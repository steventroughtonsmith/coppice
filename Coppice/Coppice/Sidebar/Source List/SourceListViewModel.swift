//
//  SourceListViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore
import M3Data

protocol SourceListView: AnyObject {
    func reload()
    func reloadSelection()
}

class SourceListViewModel: ViewModel {
    weak var view: SourceListView?

    let notificationCenter: NotificationCenter
    init(documentWindowViewModel: DocumentWindowViewModel, notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.notificationCenter = notificationCenter

        super.init(documentWindowViewModel: documentWindowViewModel)

        self.reloadSourceListNodes()
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case pages
        case folders
        case selection
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    func startObserving() {
        self.subscribers[.pages] = self.modelController.collection(for: Page.self).changePublisher.sink { [weak self] _ in
            self?.setNeedsReload()
        }
        self.subscribers[.folders] = self.modelController.collection(for: Folder.self).changePublisher.sink { [weak self] _ in
            self?.setNeedsReload()
        }

        self.subscribers[.selection] = self.documentWindowViewModel.$sidebarSelection.sink { [weak self] newItem in
            self?.updateSelectedNodes(with: newItem)
        }
    }

    func stopObserving() {
        self.subscribers = [:]
    }


    //MARK: - Source List Items
    var rootSourceListNodes: [SourceListNode] {
        return [self.canvasesNode, self.pagesGroupNode]
    }

    lazy var canvasesNode: SourceListNode = {
        let node = CanvasesSourceListNode()
        self.nodesByItem[.canvases] = node
        return node
    }()

    lazy var pagesGroupNode: SourceListNode = {
        let node = PagesGroupSourceListNode(rootFolder: self.modelController.rootFolder)
        self.nodesByItem[.folder(self.modelController.rootFolder.id)] = node
        return node
    }()

    var isPageGroupNodeExpanded: Bool {
        get { self.modelController.settings.bool(for: .pageGroupExpanded) ?? true }
        set { self.modelController.settings.set(newValue, for: .pageGroupExpanded) }
    }


    var allNodes: [SourceListNode] {
        return Array(self.nodesByItem.values)
    }

    private var nodesByItem = [DocumentWindowViewModel.SidebarItem: SourceListNode]()

    func setNeedsReload() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.reloadSourceListNodes), object: nil)
        self.perform(#selector(self.reloadSourceListNodes), with: nil, afterDelay: 0)
    }

    @objc dynamic func reloadSourceListNodes() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.reloadSourceListNodes), object: nil)
        self.addAndRemoveNodes()
        self.updateHierarchy()
        self.updateSelectedNodes(with: self.documentWindowViewModel.sidebarSelection)
        self.view?.reload()
    }

    private func addAndRemoveNodes() {
        var oldItems = Array(nodesByItem.keys)

        for page in self.modelController.pageCollection.all {
            let node = self.node(for: page, createIfNeeded: true)!
            if let index = oldItems.firstIndex(of: node.item) {
                oldItems.remove(at: index)
            }
        }

        for folder in self.modelController.folderCollection.all {
            let node = self.node(for: folder, createIfNeeded: true)!
            if let index = oldItems.firstIndex(of: node.item) {
                oldItems.remove(at: index)
            }
        }

        //Remove root source list nodes
        for node in self.rootSourceListNodes {
            if let index = oldItems.firstIndex(of: node.item) {
                oldItems.remove(at: index)
            }
        }

        //Remove old items
        for item in oldItems {
            self.nodesByItem[item] = nil
        }
    }

    private func updateHierarchy() {
        for folder in self.modelController.folderCollection.all {
            guard let node = self.node(for: .folder(folder.id)) else {
                continue
            }

            let folderContentsIDs: [DocumentWindowViewModel.SidebarItem] = folder.folderContents.compactMap {
                if $0.id.modelType == Page.modelType {
                    return .page($0.id)
                }
                if $0.id.modelType == Folder.modelType {
                    return .folder($0.id)
                }
                return nil
            }

            let folderNodes = folderContentsIDs.compactMap { self.node(for: $0) }
            node.children = folderNodes
        }
    }

    func node(for item: DocumentWindowViewModel.SidebarItem) -> SourceListNode? {
        return self.nodesByItem[item]
    }

    private func node(for page: Page, createIfNeeded: Bool) -> SourceListNode? {
        if let node = self.nodesByItem[.page(page.id)] {
            return node
        }

        if createIfNeeded {
            let node = PageSourceListNode(page: page)
            self.nodesByItem[.page(page.id)] = node
            return node
        }

        return nil
    }

    private func node(for folder: Folder, createIfNeeded: Bool) -> SourceListNode? {
        if let node = self.nodesByItem[.folder(folder.id)] {
            return node
        }

        if createIfNeeded {
            let node = FolderSourceListNode(folder: folder)
            self.nodesByItem[.folder(folder.id)] = node
            return node
        }

        return nil
    }


    //MARK: - Selection
    var springLoadedNode: SourceListNode? {
        didSet {
            if let node = self.springLoadedNode {
                self.documentWindowViewModel.saveNavigation()
                self.selectedNodes = [node]
            } else {
                self.documentWindowViewModel.restoreNavigation()
            }
        }
    }


    var selectedNodes: [SourceListNode] = [] {
        didSet {
            self.isUpdatingSelection = true
            self.documentWindowViewModel.updateSelection(self.selectedNodes.map(\.item))
            self.isUpdatingSelection = false
        }
    }

    private var isUpdatingSelection = false
    func updateSelectedNodes(with items: [DocumentWindowViewModel.SidebarItem]) {
        guard self.isUpdatingSelection == false else {
            return
        }
        let normalisedItems: [DocumentWindowViewModel.SidebarItem] = items.map {
            if case .canvas = $0 {
                return .canvases
            }
            return $0
        }
        self.selectedNodes = normalisedItems.compactMap { self.node(for: $0) }
        self.view?.reloadSelection()
    }


    //MARK: - Item Drag & Drop
    enum DropMode {
        case move
        case copy
    }

    func canDropItems(with ids: [ModelID], onto node: SourceListNode?, atChildIndex index: Int, mode: DropMode) -> (Bool, SourceListNode?, Int) {
        guard let sourceListNode = node, case .folder(let folderID) = sourceListNode.item else {
            return (false, node, index)
        }

        guard let folder = self.modelController.folderCollection.objectWithID(folderID),
              self.validate(ids: ids, and: folder, mode: mode)
        else {
                return (false, node, index)
        }
        return (true, node, index)
    }

    func dropItems(with ids: [ModelID], onto node: SourceListNode?, atChildIndex index: Int, mode: DropMode) -> Bool {
        guard let sourceListNode = node, case .folder(let folderID) = sourceListNode.item else {
            return false
        }

        guard let folder = self.modelController.folderCollection.objectWithID(folderID),
              self.validate(ids: ids, and: folder, mode: mode)
        else {
            return false
        }

        let items: [FolderContainable]
        switch mode {
        case .move:
            items = ids.compactMap { self.modelController.object(with: $0) as? FolderContainable }
        case .copy:
            let pages = ids.compactMap { self.modelController.pageCollection.objectWithID($0) }
            items = self.modelController.duplicatePages(pages)
        }

        if index == -1 {
            folder.insert(items, below: folder.folderContents.last)
            return true
        } else {
            let trueIndex = index - 1
            if (trueIndex == -1) {
                folder.insert(items, below: nil)
                return true
            } else if let item = folder.folderContents[safe: trueIndex] {
                folder.insert(items, below: item)
                return true
            }
        }

        return false
    }

    private func validate(ids: [ModelID], and folder: Folder, mode: DropMode) -> Bool {
        guard (CoppiceSubscriptionManager.shared.state == .enabled) || folder == self.modelController.rootFolder else {
            return false
        }

        var currentFolder: Folder? = folder
        while currentFolder != nil {
            guard ids.contains(currentFolder!.id) == false else {
                return false
            }
            currentFolder = currentFolder?.containingFolder
        }

        let validModelTypes: [ModelType]
        switch mode {
        case .move:
            validModelTypes = [Page.modelType, Folder.modelType]
        case .copy:
            validModelTypes = [Page.modelType]
        }

        //Check all ids are valid
        for id in ids {
            guard validModelTypes.contains(id.modelType) else {
                return false
            }
        }

        return true
    }


    //MARK: - File Drag & Drop
    func canDropFiles(at urls: [URL], onto node: SourceListNode?, atChildIndex index: Int) -> (Bool, SourceListNode?, Int) {
        guard let sourceListNode = node else {
            return (self.validateFiles(at: urls), self.pagesGroupNode, -1)
        }
        guard case .folder = sourceListNode.item else {
            return (false, node, index)
        }

        return (self.validateFiles(at: urls), node, index)
    }

    func dropFiles(at urls: [URL], onto node: SourceListNode?, atChildIndex index: Int) -> Bool {
        guard let sourceListNode = node, case .folder(let folderID) = sourceListNode.item else {
            return false
        }

        guard let folder = self.modelController.folderCollection.objectWithID(folderID),
            self.validateFiles(at: urls)
        else {
            return false
        }

        if index == -1 {
            self.modelController.createPages(fromFilesAt: urls, in: folder, below: folder.folderContents.last)
            return true
        }

        let trueIndex = index - 1
        if (trueIndex == -1) {
            self.modelController.createPages(fromFilesAt: urls, in: folder)
        } else {
            self.modelController.createPages(fromFilesAt: urls, in: folder, below: folder.folderContents[safe: trueIndex])
        }
        return true
    }

    private func validateFiles(at urls: [URL]) -> Bool {
        for url in urls {
            guard let resourceValues = try? url.resourceValues(forKeys: Set([.typeIdentifierKey])),
                let typeIdentifier = resourceValues.typeIdentifier
            else {
                    return false
            }

            if Page.ContentType.contentType(forUTI: typeIdentifier) == nil {
                return false
            }
        }
        return true
    }


    //MARK: - Creation
    func createPage(ofType type: Page.ContentType?, underNodes collection: SourceListNodeCollection) -> DocumentWindowViewModel.SidebarItem {
        let actualType = type ?? self.documentWindowViewModel.lastCreatePageType
        let lastNode = collection.nodes.last
        let folder: Folder
        if CoppiceSubscriptionManager.shared.state == .enabled {
            folder = lastNode?.folderForCreation ?? self.documentWindowViewModel.folderForNewPages
        } else {
            folder = self.documentWindowViewModel.folderForNewPages
        }
        let page = self.modelController.createPage(ofType: actualType, in: folder, below: lastNode?.folderItemForCreation) {
            self.documentWindowViewModel.canvasForNewPages?.addPages([$0])
        }
        self.documentWindowViewModel.lastCreatePageType = actualType
        return .page(page.id)
    }

    func createFolder(underNodes collection: SourceListNodeCollection) -> DocumentWindowViewModel.SidebarItem {
        let lastNode = collection.nodes.last
        let folder = self.modelController.createFolder(in: lastNode?.folderForCreation ?? self.documentWindowViewModel.folderForNewPages,
                                                       below: lastNode?.folderItemForCreation)
        return .folder(folder.id)
    }

    func createFolder(usingSelection collection: SourceListNodeCollection) -> DocumentWindowViewModel.SidebarItem? {
        guard (collection.nodes.count > 0) else {
            return nil
        }
        let containingFolder = collection.commonAncestor?.folderForCreation ?? self.modelController.rootFolder
        let newFolder = self.modelController.createFolder(in: containingFolder, below: containingFolder.folderContents.last) { folder in
            folder.insert(collection.nodes.compactMap(\.folderContainable))
        }
        return .folder(newFolder.id)
    }

    @discardableResult func createPages(fromFilesAt urls: [URL], underNodes collection: SourceListNodeCollection) -> [DocumentWindowViewModel.SidebarItem] {
        let lastNode = collection.nodes.last
        let pages = self.modelController.createPages(fromFilesAt: urls,
                                                     in: (lastNode?.folderForCreation ?? self.documentWindowViewModel.folderForNewPages),
                                                     below: lastNode?.folderItemForCreation)
        return pages.map { .page($0.id) }
    }

    @discardableResult func duplicatePages(inNodes collection: SourceListNodeCollection) -> [DocumentWindowViewModel.SidebarItem] {
        let duplicatedPages = self.modelController.duplicatePages(collection.nodes.compactMap { ($0 as? PageSourceListNode)?.page })
        return duplicatedPages.map { .page($0.id) }
    }


    //MARK: - Deleting
    func delete(_ nodes: [SourceListNode]) {
        self.documentWindowViewModel.deleteItems(nodes.compactMap(\.folderContainable))
    }


    //MARK: - Canvases
    var canvases: [Canvas] {
        return self.modelController.canvasCollection.all.sorted { $0.sortIndex < $1.sortIndex }
    }

    func addNodes(_ nodeCollection: SourceListNodeCollection, to canvas: Canvas) {
        guard (nodeCollection.containsCanvases == false) && (nodeCollection.containsFolders == false) else {
            return
        }

        let pages = nodeCollection.nodes.compactMap { ($0 as? PageSourceListNode)?.page }
        canvas.addPages(pages)
    }
}
