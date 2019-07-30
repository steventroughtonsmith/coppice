//
//  SidebarViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

protocol SidebarView: class {
    func reloadSelection()
    func reloadCanvases()
    func reloadPages()
}

protocol SidebarViewModelDelegate: class {
    func selectedObjectDidChange(in viewModel: SidebarViewModel)
}


protocol SidebarItem: class{
    var id: ModelID { get }
    var title: String { get }
}

class CanvasSidebarItem: NSObject, SidebarItem {
    let canvas: Canvas
    init(canvas: Canvas) {
        self.canvas = canvas
    }

    var id: ModelID { self.canvas.id }
    @objc dynamic var title: String { self.canvas.title }
}

class PageSidebarItem: NSObject, SidebarItem {
    let page: Page
    init(page: Page) {
        self.page = page
    }

    var id: ModelID { self.page.id }
    @objc dynamic var title: String { self.page.title }
}

class SidebarViewModel: NSObject {
    weak var view: SidebarView?
    weak var delegate: SidebarViewModelDelegate?

    let modelController: ModelController
    init(modelController: ModelController) {
        self.modelController = modelController
        super.init()

        self.setupSelectionUndo()
    }

    var canvasObserver: ModelCollectionObservation<Canvas>?
    var pageObserver: ModelCollectionObservation<Page>?

    func startObserving() {
        self.canvasObserver = self.modelController.canvases.addObserver { _ in self.reloadCanvases() }
        self.pageObserver = self.modelController.pages.addObserver { _ in self.reloadPages() }
    }

    func stopObserving() {
        if let canvasObserver = self.canvasObserver {
            self.modelController.canvases.removeObserver(canvasObserver)
            self.canvasObserver = nil
        }
        if let pageObserver = self.pageObserver {
            self.modelController.pages.removeObserver(pageObserver)
            self.pageObserver = nil
        }
    }


    func reloadCanvases() {
        self.cachedCanvasItems = nil
        self.view?.reloadCanvases()
    }

    func reloadPages() {
        self.cachedPageItems = nil
        self.view?.reloadPages()
    }


    private var cachedCanvasItems: [CanvasSidebarItem]?
    var canvasItems: [CanvasSidebarItem] {
        if let cachedItems = self.cachedCanvasItems {
            return cachedItems
        }
        let items = self.modelController.canvases.all.sorted { $0.sortIndex < $1.sortIndex }.map { CanvasSidebarItem(canvas: $0)}
        self.cachedCanvasItems = items
        return items
    }

    private var cachedPageItems: [PageSidebarItem]?
    var pageItems: [PageSidebarItem] {
        if let cachedItems = self.cachedPageItems {
            return cachedItems
        }
        let items = self.modelController.pages.all.sorted { $0.title < $1.title }.map { PageSidebarItem(page: $0)}
        self.cachedPageItems = items
        return items
    }


    //MARK: - Re-ordering
    func moveCanvas(with id: ModelID, toIndex index: Int) {
        var canvases: [Canvas?] = self.canvasItems.map { $0.canvas }
        guard let currentIndex = canvases.firstIndex(where: { $0?.id == id}) else {
            return
        }

        let canvasToMove = canvases[currentIndex]
        canvases[currentIndex] = nil
        canvases.insert(canvasToMove, at: index)

        var sortIndex = 0
        for canvas in canvases {
            if canvas != nil {
                canvas?.sortIndex = sortIndex
                sortIndex += 1
            }
        }
    }


    //MARK: - Selection
    var selectedObject: ModelObject? {
        if (self.selectedCanvasRow >= 0) {
            return self.canvasItems[self.selectedCanvasRow].canvas
        }
        if (self.selectedPageRow >= 0) {
            return self.pageItems[self.selectedPageRow].page
        }
        return nil
    }

    func selectObject(withID id: ModelID) {
        if let canvasRow = self.canvasItems.firstIndex(where: { $0.id == id }) {
            self.selectCanvas(atRow: canvasRow)
        }
        else if let pageRow = self.pageItems.firstIndex(where: { $0.id == id }) {
            self.selectPage(atRow: pageRow)
        }

        if let selectionID = self.selectedObject?.id {
            self.modelController.undoManager?.registerUndo(withTarget: self, handler: { (target) in
                target.selectObject(withID: selectionID)
            })
        }
    }

    private(set) var selectedCanvasRow: Int = -1

    func selectCanvas(atRow row: Int) {
        guard self.selectedCanvasRow != row else {
            return
        }

        self.selectedPageRow = -1
        self.selectedCanvasRow = row
        self.view?.reloadSelection()
        self.delegate?.selectedObjectDidChange(in: self)
    }

    private(set) var selectedPageRow: Int = -1

    func selectPage(atRow row: Int) {
        guard self.selectedPageRow != row else {
            return
        }

        self.selectedCanvasRow = -1
        self.selectedPageRow = row
        self.view?.reloadSelection()
        self.delegate?.selectedObjectDidChange(in: self)
    }


    private var undoObservation: NSObjectProtocol?
    private func setupSelectionUndo() {
        guard let undoManager = self.modelController.document?.undoManager else {
            return
        }

        self.undoObservation = NotificationCenter.default.addObserver(forName: .NSUndoManagerDidOpenUndoGroup, object: undoManager, queue: .main) { [weak self] (notification) in
            guard let strongSelf = self,
                let selectionID = strongSelf.selectedObject?.id else {
                return
            }

            undoManager.registerUndo(withTarget: strongSelf) { (target) in
                target.selectObject(withID: selectionID)
            }
        }
    }
}
