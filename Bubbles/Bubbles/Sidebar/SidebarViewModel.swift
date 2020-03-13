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
    }

    var pagesObserver: ModelCollection<Page>.Observation?
    var foldersObserver: ModelCollection<Folder>.Observation?
    func startObserving() {
        self.pagesObserver = self.modelController.collection(for: Page.self).addObserver(changeHandler: { [weak self] (_, _) in
            self?.forceReload()
        })
        self.foldersObserver = self.modelController.collection(for: Folder.self).addObserver(changeHandler: { [weak self] (_, _) in
            self?.forceReload()
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


    private func forceReload() {
        self.cachedRootSidebarNodes = nil
        self.view?.reload()
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
    private var cachedRootSidebarNodes: [SidebarNode]?
    var rootSidebarNodes: [SidebarNode] {
        if let items = self.cachedRootSidebarNodes {
            return items
        }
        let newItems = self.regenerateSidebarNodes()
        self.cachedRootSidebarNodes = newItems
        return newItems
    }

    private func regenerateSidebarNodes() -> [SidebarNode] {
        var nodes = [SidebarNode]()
        nodes.append(CanvasesSidebarNode())

        let rootFolder = self.documentWindowViewModel.rootFolder
        let pagesGroup = PagesGroupSidebarNode(rootFolder: rootFolder)

        pagesGroup.addChildren(self.sidebarNodes(for: rootFolder))
        nodes.append(pagesGroup)
        return nodes
    }

    func sidebarNodes(for folder: Folder) -> [SidebarNode] {
        var nodes = [SidebarNode]()
        for item in folder.contents {
            if let page = item as? Page {
                nodes.append(PageSidebarNode(page: page))
            }
            else if let folder = item as? Folder {
                let folderNode = FolderSidebarNode(folder: folder)
                folderNode.addChildren(self.sidebarNodes(for: folder))
                nodes.append(folderNode)
            }
        }
        return nodes
    }


    //MARK: - Folder
    func createFolder() {

    }


    //MARK: - Deleting
    func deleteItems(at indexes: IndexSet) {

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
