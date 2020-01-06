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
    func reloadSelection()
    func reloadCanvases()
    func reloadPages()
}

class SidebarViewModel: ViewModel {
    weak var view: SidebarView?

    let notificationCenter: NotificationCenter
    init(documentWindowViewModel: DocumentWindowViewModel, notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.notificationCenter = notificationCenter

        super.init(documentWindowViewModel: documentWindowViewModel)
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
    private var windowStateSidebarObserver: AnyCancellable?
    private var windowSearchObserver: AnyCancellable?

    func startObserving() {
        self.canvasObserver = self.canvases.addObserver { canvas, change in self.handleChange(to: canvas, changeType: change) }
        self.pageObserver = self.pages.addObserver { page, change in self.handleChange(to: page, changeType: change)}
        self.windowStateSidebarObserver = self.documentWindowViewModel.$selectedSidebarObjectID
                                            .receive(on: RunLoop.main)
                                            .assign(to: \.selectedObjectID, on: self)
        
        self.windowSearchObserver = self.documentWindowViewModel.publisher(for: \.searchString).sink { _ in
            self.updateSearch()
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
        let items = self.canvases.objects(matchingSearchTerm: self.documentWindowViewModel.searchString)
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { CanvasSidebarItem(canvas: $0)}
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
        let items = self.pages.objects(matchingSearchTerm: self.documentWindowViewModel.searchString)
            .sorted { $0.title < $1.title }
            .map { PageSidebarItem(page: $0)}
        self.cachedPageItems = items
        return items
    }

    func addPage(with id: ModelID, toCanvasAtIndex index: Int) {
        let pageLink = PageLink(destination: id)
        let canvas = self.canvasItems[index].canvas
        var centrePoint = CGPoint.zero
        if let viewPort = canvas.viewPort {
            centrePoint = CGPoint(x: viewPort.midX, y: viewPort.midY)
        }
        self.documentWindowViewModel.addPage(at: pageLink, to: canvas, centredOn: centrePoint)
    }


    //MARK: - Deleting
    func deleteSelectedObject() {
        guard let selectedID = self.selectedObjectID else {
            return
        }

        if selectedID.modelType == Page.modelType {
            if let page = self.pages.objectWithID(selectedID) {
                self.documentWindowViewModel.delete(page)
            }
        } else if selectedID.modelType == Canvas.modelType {
            if let canvas = self.canvases.objectWithID(selectedID) {
                self.documentWindowViewModel.delete(canvas)
            }
        }
    }

    func deleteCanvas(atIndex index: Int) {
        guard (index >= 0) && (index < self.canvasItems.count) else {
            return
        }

        let canvas = self.canvasItems[index].canvas
        self.documentWindowViewModel.delete(canvas)
    }

    func deletePage(atIndex index: Int) {
        guard (index >= 0) && (index < self.pageItems.count) else {
            return
        }

        let page = self.pageItems[index].page
        self.documentWindowViewModel.delete(page)
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
        var canvas: Canvas?
        if let index = canvasIndex {
            canvas = self.canvasItems[index].canvas
        }

        return self.documentWindowViewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: canvas)
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
            self.documentWindowViewModel.selectedSidebarObjectID = self.selectedObjectID
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

    var selectedPages: [Page] {
        guard self.selectedPageRow > -1 else {
            return []
        }
        return [self.pageItems[self.selectedPageRow].page]
    }


    //MARK: - Search
    private func updateSearch() {
        self.reloadPages()
        self.reloadCanvases()
    }


    //MARK: - Cell Size
    @objc dynamic var useSmallCanvasCells: Bool {
        get {
            return UserDefaults.standard.bool(forKey: .useSmallCanvasCells)
        }
        set {
            self.willChangeValue(for: \.useSmallCanvasCells)
            UserDefaults.standard.set(newValue, forKey: .useSmallCanvasCells)
            self.didChangeValue(for: \.useSmallCanvasCells)
        }
    }
}
