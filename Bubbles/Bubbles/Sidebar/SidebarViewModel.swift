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

class SidebarViewModel: NSObject {
    weak var view: SidebarView?
    weak var delegate: SidebarViewModelDelegate?



    convenience init(modelController: BubblesModelController, notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.init(canvases: modelController.canvases,
                  pages: modelController.pages,
                  undoManager: modelController.undoManager,
                  notificationCenter: notificationCenter)
    }

    let canvases: ModelCollection<Canvas>
    let pages: ModelCollection<Page>
    let undoManager: UndoManager
    let notificationCenter: NotificationCenter
    init(canvases: ModelCollection<Canvas>,
         pages: ModelCollection<Page>,
         undoManager: UndoManager,
         notificationCenter: NotificationCenter) {
        self.canvases = canvases
        self.pages = pages
        self.undoManager = undoManager
        self.notificationCenter = notificationCenter
        super.init()

        self.setupSelectionUndo()
    }


    //MARK: - Observation
    private var canvasObserver: ModelCollection<Canvas>.Observation?
    private var pageObserver: ModelCollection<Page>.Observation?

    func startObserving() {
        self.canvasObserver = self.canvases.addObserver { canvas, change in self.handleChange(to: canvas, changeType: change) }
        self.pageObserver = self.pages.addObserver { page, change in self.handleChange(to: page, changeType: change)}
    }

    func stopObserving() {
        if let canvasObserver = self.canvasObserver {
            self.canvases.removeObserver(canvasObserver)
            self.canvasObserver = nil
        }
        if let pageObserver = self.pageObserver {
            self.pages.removeObserver(pageObserver)
            self.pageObserver = nil
        }
    }




    //MARK: - Canvases
    private func handleChange(to canvas: Canvas, changeType: ModelCollection<Canvas>.ChangeType) {
        self.reloadCanvases()
        if (changeType == .insert) {
            self.selectedObjectID = canvas.id
        }
    }

    private func reloadCanvases() {
        self.cachedCanvasItems = nil
        self.view?.reloadCanvases()
    }

    private var cachedCanvasItems: [CanvasSidebarItem]?
    var canvasItems: [CanvasSidebarItem] {
        if let cachedItems = self.cachedCanvasItems {
            return cachedItems
        }
        let items = self.canvases.all.sorted { $0.sortIndex < $1.sortIndex }.map { CanvasSidebarItem(canvas: $0)}
        self.cachedCanvasItems = items
        return items
    }


    //MARK: - Pages
    private func handleChange(to page: Page, changeType: ModelCollection<Page>.ChangeType) {
        self.reloadPages()
        //Only want to select the page in the sidebar if the user has a page selected (otherwise it will appear in the canvas)
        if ((self.selectedPageRow != -1) && changeType == .insert) {
            self.selectedObjectID = page.id
        }
    }

    private func reloadPages() {
        self.cachedPageItems = nil
        self.view?.reloadPages()
    }

    private var cachedPageItems: [PageSidebarItem]?
    var pageItems: [PageSidebarItem] {
        if let cachedItems = self.cachedPageItems {
            return cachedItems
        }
        let items = self.pages.all.sorted { $0.title < $1.title }.map { PageSidebarItem(page: $0)}
        self.cachedPageItems = items
        return items
    }


    //MARK: - Re-ordering
    func moveCanvas(with id: ModelID, aboveCanvasAtIndex index: Int) {
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
        self.cachedCanvasItems = nil
    }


    //MARK: - Selection
    var selectedObjectID: ModelID? {
        didSet {
            let undoManager = self.undoManager
            if (undoManager.isUndoing || undoManager.isRedoing) {
                let selectedObjectID = self.selectedObjectID
                self.undoManager.setActionIsDiscardable(true)
                self.undoManager.registerUndo(withTarget: self, handler: { (target) in
                    target.selectedObjectID = selectedObjectID
                })
            }
            self.view?.reloadSelection()
            self.delegate?.selectedObjectDidChange(in: self)
        }
    }

    var selectedCanvasRow: Int {
        get {
            return self.canvasItems.firstIndex(where: { $0.id == self.selectedObjectID }) ?? -1
        }
        set {
            guard (newValue >= 0) && (newValue < self.canvasItems.count) else {
                return
            }
            self.selectedObjectID = self.canvasItems[newValue].id
        }
    }

    var selectedPageRow: Int {
        get {
            return self.pageItems.firstIndex(where: { $0.id == self.selectedObjectID }) ?? -1
        }
        set {
            guard (newValue >= 0) && (newValue < self.pageItems.count) else {
                return
            }
            self.selectedObjectID = self.pageItems[newValue].id
        }
    }


    //MARK: - Undo
    private var undoObservation: NSObjectProtocol?
    private func setupSelectionUndo() {
        let undoManager = self.undoManager
        self.undoObservation = self.notificationCenter.addObserver(forName: .NSUndoManagerDidOpenUndoGroup,
                                                                   object: undoManager,
                                                                   queue: .main)
        { [weak self] (notification) in
            guard let strongSelf = self,
                let selectionID = strongSelf.selectedObjectID else {
                return
            }

            undoManager.setActionIsDiscardable(true)
            undoManager.registerUndo(withTarget: strongSelf) { (target) in
                target.selectedObjectID = selectionID
            }
        }
    }
}
