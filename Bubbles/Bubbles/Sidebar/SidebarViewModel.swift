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

    func showAlert(_ alert: Alert, callback: @escaping (Int) -> Void)
}

class SidebarViewModel: NSObject {
    weak var view: SidebarView?

    let modelController: ModelController
    let notificationCenter: NotificationCenter
    let documentWindowState: DocumentWindowState
    init(modelController: ModelController,
         notificationCenter: NotificationCenter = NotificationCenter.default,
         documentWindowState: DocumentWindowState) {
        self.modelController = modelController
        self.notificationCenter = notificationCenter
        self.documentWindowState = documentWindowState
        super.init()

        self.setupSelectionUndo()
    }


    //MARK: - Convenience Methods

    var canvases: ModelCollection<Canvas> {
        return self.modelController.collection(for: Canvas.self)
    }

    var pages: ModelCollection<Page> {
        return self.modelController.collection(for: Page.self)
    }

    var canvasPages: ModelCollection<CanvasPage> {
        return self.modelController.collection(for: CanvasPage.self)
    }


    //MARK: - Observation
    private var canvasObserver: ModelCollection<Canvas>.Observation?
    private var pageObserver: ModelCollection<Page>.Observation?
    private var windowStateSidebarObserver: NSKeyValueObservation?

    func startObserving() {
        self.canvasObserver = self.canvases.addObserver { canvas, change in self.handleChange(to: canvas, changeType: change) }
        self.pageObserver = self.pages.addObserver { page, change in self.handleChange(to: page, changeType: change)}
        self.windowStateSidebarObserver = self.documentWindowState.observe(\.selectedSidebarObjectIDString) { [weak self] (state, change) in
            guard let strongSelf = self else {
                return
            }
            guard let idString = state.selectedSidebarObjectIDString else {
                return
            }
            strongSelf.selectedObjectID = ModelID(string: idString)
        }
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

    func addPage(with id: ModelID, toCanvasAtIndex index: Int) {
        guard id.modelType == Page.modelType else {
            return
        }
        guard let page = self.pageItems.first(where: { $0.id == id })?.page else {
            return
        }
        
        let canvas = self.canvasItems[index].canvas
        if let viewPort = canvas.viewPort {
            canvas.add(page, centredOn: CGPoint(x: viewPort.midX, y: viewPort.midY))
        } else {
            canvas.add(page, centredOn: .zero)
        }
    }


    //MARK: - Deleting
    func deleteSelectedObject() {
        guard let selectedID = self.selectedObjectID else {
            return
        }

        if selectedID.modelType == Page.modelType {
            if let page = self.pages.objectWithID(selectedID) {
                guard let alert = alertForDeleting(page) else {
                    self.delete(page)
                    return
                }

                self.view?.showAlert(alert, callback: { (index) in
                    let (type, _) = alert.buttons[index]
                    if (type == .confirm) {
                        self.delete(page)
                    }
                })
            }
        } else if selectedID.modelType == Canvas.modelType {
            if let canvas = self.canvases.objectWithID(selectedID) {
                guard let alert = alertForDeleting(canvas) else {
                    self.delete(canvas)
                    return
                }

                self.view?.showAlert(alert, callback: { (index) in
                    let (type, _) = alert.buttons[index]
                    if (type == .confirm) {
                        self.delete(canvas)
                    }
                })
            }
        }
    }

    private func alertForDeleting(_ page: Page) -> Alert? {
        let canvases = Set(page.canvases.compactMap { $0.canvas })
        guard canvases.count > 0 else {
            return nil
        }
        let localizedTitle = String.localizedStringWithFormat(NSLocalizedString("Delete Page '%@'", comment: "Delete Page alert title"),
                                                              page.title)

        let localizedMessage: String
        if canvases.count == 1 {
            let messageFormat = NSLocalizedString("This page is on the canvas '%@'. Deleting it will also remove it and any linked pages from that canvas.",
                                                  comment: "Delete Page single canvas alert message")
            localizedMessage = String.localizedStringWithFormat(messageFormat, canvases.first!.title)
        } else {
            let messageFormat = NSLocalizedString("This page is on %d canvases. Deleting it will also remove it and any linked pages from those canvases.",
                                                  comment: "Delete Page multiple pages alert message")
            localizedMessage = String.localizedStringWithFormat(messageFormat, canvases.count)
        }
        return Alert(title: localizedTitle,
                     message: localizedMessage,
                     confirmButtonTitle: NSLocalizedString("Delete", comment: "Delete alert confirm button"))
    }

    private func delete(_ page: Page) {
        self.modelController.pushChangeGroup()
        page.canvases.forEach {
            self.canvasPages.delete($0)
        }
        self.pages.delete(page)
        self.modelController.popChangeGroup()

        self.selectedObjectID = nil
    }

    private func alertForDeleting(_ canvas: Canvas) -> Alert? {
        guard canvas.pages.count > 0 else {
            return nil
        }

        let localizedTitle = String.localizedStringWithFormat(NSLocalizedString("Delete Canvas '%@'", comment: "Delete Canvas alert title"),
                                                              canvas.title)
        return Alert(title: localizedTitle,
                     message: NSLocalizedString("Are you sure you want to delete this canvas?", comment: "Delete canvas confirm message"),
                     confirmButtonTitle: NSLocalizedString("Delete", comment: "Delete alert confirm button"))
    }

    private func delete(_ canvas: Canvas) {
        self.modelController.pushChangeGroup()
        canvas.pages.forEach {
            self.canvasPages.delete($0)
        }
        self.canvases.delete(canvas)
        self.modelController.popChangeGroup()

        self.selectedObjectID = nil
    }


    //MARK: - Re-ordering
    func moveCanvas(with id: ModelID, aboveCanvasAtIndex index: Int) {
        guard id.modelType == Canvas.modelType else {
            return
        }

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


    //MARK: - Adding Files
    func addPages(fromFilesAtURLs fileURLs: [URL], toCanvasAtIndex canvasIndex: Int?) -> [Page] {
        self.pages.modelController?.pushChangeGroup()

        let newPages = fileURLs.compactMap { self.pages.newPage(fromFileAt: $0) }
        if let index = canvasIndex {
            let canvas = self.canvasItems[index].canvas
            newPages.forEach { canvas.add($0) }
        }
        
        self.pages.modelController?.popChangeGroup()

        return newPages
    }


    //MARK: - Selection
    var selectedObjectID: ModelID? {
        didSet {
            guard self.selectedObjectID != oldValue else {
                return
            }
            let undoManager = self.modelController.undoManager
            if (undoManager.isUndoing || undoManager.isRedoing) {
                let selectedObjectID = self.selectedObjectID
                undoManager.setActionIsDiscardable(true)
                undoManager.registerUndo(withTarget: self, handler: { (target) in
                    target.selectedObjectID = selectedObjectID
                })
            }
            self.view?.reloadSelection()
            self.documentWindowState.selectedSidebarObjectIDString = self.selectedObjectID?.stringRepresentation
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
        let undoManager = self.modelController.undoManager
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
