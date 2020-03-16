//
//  SidebarViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

protocol SidebarView: class {
    func reload()
}

class SidebarViewModel: ViewModel {
    weak var view: SidebarView?

    let notificationCenter: NotificationCenter
    init(documentWindowViewModel: DocumentWindowViewModel, notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.notificationCenter = notificationCenter

        super.init(documentWindowViewModel: documentWindowViewModel)

        self.reloadSidebarNodes()
    }

    var pagesObserver: ModelCollection<Page>.Observation?
    var foldersObserver: ModelCollection<Folder>.Observation?
    func startObserving() {
        self.pagesObserver = self.modelController.collection(for: Page.self).addObserver(changeHandler: { [weak self] (page, type) in
            self?.setNeedsReload()
        })
        self.foldersObserver = self.modelController.collection(for: Folder.self).addObserver(changeHandler: { [weak self] (folder, type) in
            self?.setNeedsReload()
        })
    }

    func stopObserving() {
        if let observer = self.pagesObserver {
            self.modelController.collection(for: Page.self).removeObserver(observer)
        }
        if let observer = self.foldersObserver {
            self.modelController.collection(for: Folder.self).removeObserver(observer)
        }
    }




//
//    func addPages(atIndexes indexes: IndexSet, toCanvasAtindex canvasIndex: Int) {
//        guard let canvas = self.canvasItems[safe: canvasIndex]?.canvas else {
//            return
//        }
//
//        let pages = self.pageItems[indexes].map { $0.page }
//        self.documentWindowViewModel.addPages(pages, to: canvas)
//    }


    //MARK: - Sidebar Items
    var rootSidebarNodes: [SidebarNode] {
        return [self.canvasesNode, self.pagesGroupNode]
    }

    lazy var canvasesNode: SidebarNode = {
        let node = CanvasesSidebarNode()
        self.nodesByItem[.canvases] = node
        return node
    }()

    lazy var pagesGroupNode: SidebarNode = {
        let node = PagesGroupSidebarNode(rootFolder: self.documentWindowViewModel.rootFolder)
        self.nodesByItem[.folder(self.documentWindowViewModel.rootFolder.id)] = node
        return node
    }()


    var allNodes: [SidebarNode] {
        return Array(nodesByItem.values)
    }

    private var nodesByItem = [DocumentWindowViewModel.SidebarItem: SidebarNode]()

    func setNeedsReload() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(reloadSidebarNodes), object: nil)
        self.perform(#selector(reloadSidebarNodes), with: nil, afterDelay: 0)
    }

    @objc dynamic func reloadSidebarNodes() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(reloadSidebarNodes), object: nil)
        self.addAndRemoveNodes()
        self.updateHierarchy()
        self.view?.reload()
    }

    private func addAndRemoveNodes() {
        var oldItems = Array(nodesByItem.keys)

        for page in self.documentWindowViewModel.pageCollection.all {
            let node = self.node(for: page, createIfNeeded: true)!
            if let index = oldItems.firstIndex(of: node.item) {
                oldItems.remove(at: index)
            }
        }

        for folder in self.documentWindowViewModel.foldersCollection.all {
            let node = self.node(for: folder, createIfNeeded: true)!
            if let index = oldItems.firstIndex(of: node.item) {
                oldItems.remove(at: index)
            }
        }

        //Remove root sidebar nodes
        for node in self.rootSidebarNodes {
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
        for folder in self.documentWindowViewModel.foldersCollection.all {
            guard let node = self.node(for: .folder(folder.id)) else {
                continue
            }

            let folderContentsIDs: [DocumentWindowViewModel.SidebarItem] = folder.contents.compactMap {
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

    func node(for item: DocumentWindowViewModel.SidebarItem) -> SidebarNode? {
        return self.nodesByItem[item]
    }

    private func node(for page: Page, createIfNeeded: Bool) -> SidebarNode? {
        if let node = self.nodesByItem[.page(page.id)] {
            return node
        }

        if createIfNeeded {
            let node = PageSidebarNode(page: page)
            self.nodesByItem[.page(page.id)] = node
            return node
        }

        return nil
    }

    private func node(for folder: Folder, createIfNeeded: Bool) -> SidebarNode? {
        if let node = self.nodesByItem[.folder(folder.id)] {
            return node
        }

        if createIfNeeded {
            let node = FolderSidebarNode(folder: folder)
            self.nodesByItem[.folder(folder.id)] = node
            return node
        }

        return nil
    }


    func canDropItems(with ids: [ModelID], onto node: SidebarNode?, atChildIndex index: Int) -> (Bool, SidebarNode?, Int) {
        guard let sidebarNode = node, case .folder(let folderID) = sidebarNode.item else {
            return (false, node, index)
        }

        guard let folder = self.documentWindowViewModel.foldersCollection.objectWithID(folderID),
              self.validate(ids: ids, and: folder) else {
                return (false, node, index)
        }
        return (true, node, index)
    }

    func canDropFiles(at urls: [URL], onto node: SidebarNode?, atChildIndex index: Int) -> (Bool, SidebarNode?, Int) {
        //nil, .canvases, .rootFolder -> true if urls are of valid type, nil, -1

        //on page -> false
        //on folder -> true if urls are of valid type
        //in folder -> true if urls are of valid type
        return (true, node, index)
    }

    func dropItems(with ids: [ModelID], onto node: SidebarNode?, atChildIndex index: Int) -> Bool {
        guard let sidebarNode = node, case .folder(let folderID) = sidebarNode.item else {
            return false
        }

        guard let folder = self.documentWindowViewModel.foldersCollection.objectWithID(folderID),
              self.validate(ids: ids, and: folder) else {
                return false
        }

        let items = ids.compactMap { self.modelController.object(with: $0) as? FolderContainable }

        if index == -1 {
            folder.insert(items, below: folder.contents.last)
            return true
        } else {
            let trueIndex = index - 1
            if (trueIndex == -1) {
                folder.insert(items, below: nil)
                return true
            } else if let item = folder.contents[safe: trueIndex] {
                folder.insert(items, below: item)
                return true
            }
        }

        return false
    }

    func dropFiles(at urls: [URL], onto node: SidebarNode?, atChildIndex index: Int) -> Bool {
        return false
    }


    private func validate(ids: [ModelID], and folder: Folder) -> Bool {
        var currentFolder: Folder? = folder
        while currentFolder != nil {
            guard ids.contains(currentFolder!.id) == false else {
                return false
            }
            currentFolder = currentFolder?.containingFolder
        }

        //Check all ids are valid
        for id in ids {
            guard (id.modelType == Page.modelType) || (id.modelType == Folder.modelType) else {
                return false
            }
        }

        return true
    }


    //MARK: - Creation
    func createPage(ofType type: PageContentType, underNodes collection: SidebarNodeCollection) {
        let lastNode = collection.nodes.last
        self.documentWindowViewModel.createPage(ofType: type, in: lastNode?.folderForCreation, below: lastNode?.folderItemForCreation)
    }

    func createFolder(underNodes collection: SidebarNodeCollection) {
        let lastNode = collection.nodes.last
        self.documentWindowViewModel.createFolder(in: lastNode?.folderForCreation, below: lastNode?.folderItemForCreation)
    }

    func createFolder(usingSelection: SidebarNodeCollection) {

    }


    //MARK: - Deleting
    func delete(_ nodes: [SidebarNode]) {
        self.documentWindowViewModel.delete(nodes.map(\.item))
    }



//    func deletePages(atIndexes indexes: IndexSet) {
//        for index in indexes {
//            guard (index >= 0) && (index < self.pageItems.count) else {
//                continue
//            }
//            let page = self.pageItems[index].page
//            self.documentWindowViewModel.delete(page)
//        }
//    }
//
//    func deletePage(atIndex index: Int) {
//        guard (index >= 0) && (index < self.pageItems.count) else {
//            return
//        }
//
//        let page = self.pageItems[index].page
//        self.documentWindowViewModel.delete(page)
//    }


    //MARK: - Adding Files
//    func addPages(fromFilesAtURLs fileURLs: [URL], toCanvasAtIndex canvasIndex: Int?) -> [Page] {
//        var canvas: Canvas?
//        if let index = canvasIndex {
//            canvas = self.canvasItems[index].canvas
//        }
//
//        return self.documentWindowViewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: canvas)
//    }


    //MARK: - Selection
    func updateSelectedNodes(_ newSelection: [SidebarNode]) {
        self.documentWindowViewModel.updateSelection(newSelection.map(\.item))
    }
}
