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

    let modelController: ModelController
    init(modelController: ModelController) {
        self.modelController = modelController
        super.init()

        self.setupSelectionUndo()
    }

    var sortedCanvases: [Canvas] {
        self.modelController.canvases.all.sorted { $0.title < $1.title }
    }

    var numberOfCanvases: Int {
        return self.modelController.canvases.all.count
    }

    func canvas(forRow row: Int) -> Canvas {
        return self.sortedCanvases[row]
    }

    func row(for canvas: Canvas) -> Int? {
        return self.sortedCanvases.firstIndex(of: canvas)
    }

    var sortedPages: [Page] {
        self.modelController.pages.all.sorted { $0.title < $1.title }
    }

    var numberOfPages: Int {
        return self.modelController.pages.all.count
    }

    func page(forRow row: Int) -> Page {
        return self.sortedPages[row]
    }

    func row(for page: Page) -> Int? {
        return self.sortedPages.firstIndex(of: page)
    }

    //MARK: - Selection
    var selectedObject: ModelObject? {
        if (self.selectedCanvasRow >= 0) {
            return self.sortedCanvases[self.selectedCanvasRow]
        }
        if (self.selectedPageRow >= 0) {
            return self.sortedPages[self.selectedPageRow]
        }
        return nil
    }

    func selectObject(withID id: UUID) {
        if let canvas = self.modelController.canvases.objectWithID(id),
           let canvasRow = self.row(for: canvas) {
            self.selectCanvas(atRow: canvasRow)
        }
        else if let page = self.modelController.pages.objectWithID(id),
            let pageRow = self.row(for: page) {
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
