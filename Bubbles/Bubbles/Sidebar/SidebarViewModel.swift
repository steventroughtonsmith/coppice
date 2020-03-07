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
//        self.canvasObserver = self.canvases.addObserver { canvas, change in self.handleChange(to: canvas, changeType: change) }
        self.pageObserver = self.pages.addObserver { page, change in self.handleChange(to: page, changeType: change)}
        self.windowStateSidebarObserver = self.documentWindowViewModel.$selectedSidebarObjectIDs
                                            .receive(on: RunLoop.main)
                                            .assign(to: \.selectedObjectIDs, on: self)
        
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
//        self.reloadCanvases()
        if (changeType == .insert) {
            self.selectedObjectIDs = Set([canvas.id])
        }
    }

    private var cachedCanvasItems: [CanvasSidebarItem]?
    var canvasItems: [CanvasSidebarItem] {
        return []
    }


    //MARK: - Pages
    enum PageSortKey: String, CaseIterable {
        case title
        case lastEdited
        case dateCreated

        var localizedName: String {
            switch self {
            case .title:
				return NSLocalizedString("Title", comment: "Title sorting name")
            case .lastEdited:
                return NSLocalizedString("Last Edited", comment: "Last Edited sorting name")
            case .dateCreated:
                return NSLocalizedString("Date Created", comment: "Date Created sorting name")
            }
        }
    }
    
    var sortKey: PageSortKey {
        get {
            guard let sortKeyString = self.modelController.settings.string(for: ModelSettings.pageSortKeySetting),
                let sortKey = PageSortKey(rawValue: sortKeyString) else {
                    return .title
            }
            return sortKey
        }
        set {
            let oldValue = self.sortKey
            self.modelController.undoManager.registerUndo(withTarget: self) { (target) in
                target.sortKey = oldValue
            }
            self.modelController.undoManager.setActionName("Sort Pages")
            self.modelController.settings.set(newValue.rawValue, for: ModelSettings.pageSortKeySetting)
            if let cachedItems = self.cachedPageItems {
                self.cachedPageItems = self.sort(cachedItems)
            }
            self.view?.reloadPages()
        }
    }

    private func handleChange(to page: Page, changeType: ModelCollection<Page>.ChangeType) {
        self.reloadPages()
        //Only want to select the page in the sidebar if the user has a page selected (otherwise it will appear in the canvas)
        if ((self.selectedPageRowIndexes.count > 0) && changeType == .insert) {
            self.selectedObjectIDs = Set([page.id])
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
        let items = self.pages.objects(matchingSearchTerm: self.documentWindowViewModel.searchString).map { PageSidebarItem(page: $0)}
        let sortedItems = self.sort(items)
        self.cachedPageItems = sortedItems
        return sortedItems
    }

    private func sort(_ pageItems: [PageSidebarItem]) -> [PageSidebarItem] {
        return pageItems.sorted { item1, item2 in
            switch self.sortKey {
            case .title:
                return item1.page.title < item2.page.title
            case .lastEdited:
                return item1.page.dateModified > item2.page.dateModified
            case .dateCreated:
                return item1.page.dateCreated > item2.page.dateCreated
            }
        }
    }

    func addPages(atIndexes indexes: IndexSet, toCanvasAtindex canvasIndex: Int) {
        guard let canvas = self.canvasItems[safe: canvasIndex]?.canvas else {
            return
        }

        let pages = self.pageItems[indexes].map { $0.page }
        self.documentWindowViewModel.addPages(pages, to: canvas)
    }



    //MARK: - Deleting

    func deletePages(atIndexes indexes: IndexSet) {
        for index in indexes {
            guard (index >= 0) && (index < self.pageItems.count) else {
                continue
            }
            let page = self.pageItems[index].page
            self.documentWindowViewModel.delete(page)
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


    //MARK: - Adding Files
    func addPages(fromFilesAtURLs fileURLs: [URL], toCanvasAtIndex canvasIndex: Int?) -> [Page] {
        var canvas: Canvas?
        if let index = canvasIndex {
            canvas = self.canvasItems[index].canvas
        }

        return self.documentWindowViewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: canvas)
    }


    //MARK: - Selection
    var selectedObjectIDs = Set<ModelID>() {
        didSet {
            guard self.selectedObjectIDs != oldValue else {
                return
            }
            let undoManager = self.modelController.undoManager
            if (undoManager.isUndoing || undoManager.isRedoing) {
                let selectedObjectID = self.selectedObjectIDs
                undoManager.setActionIsDiscardable(true)
                undoManager.registerUndo(withTarget: self, handler: { (target) in
                    target.selectedObjectIDs = selectedObjectID
                })
            }
            self.view?.reloadSelection()
            self.documentWindowViewModel.selectedSidebarObjectIDs = self.selectedObjectIDs
        }
    }

    private var selectedCanvasID: ModelID? {
        let canvasIDs = self.selectedObjectIDs.filter { $0.modelType == Canvas.modelType }
        guard canvasIDs.count == 1 else {
            return nil
        }
        return canvasIDs.first
    }

    var selectedCanvasRowIndexes: IndexSet {
        get {
            guard let index = self.canvasItems.firstIndex(where: { $0.id == self.selectedCanvasID }) else {
                return IndexSet()
            }
            return IndexSet(integer: index)
        }
        set {
            var newSelectedIDs = Set<ModelID>()
            for index in newValue {
                guard (index >= 0) && (index < self.canvasItems.count) else {
                    continue
                }
                newSelectedIDs.insert(self.canvasItems[index].id)
            }

            guard newSelectedIDs.count == newValue.count else {
                return
            }
            self.selectedObjectIDs = newSelectedIDs
        }
    }

    private var selectedPageIDs: Set<ModelID> {
        return self.selectedObjectIDs.filter { $0.modelType == Page.modelType }
    }

    var selectedPageRowIndexes: IndexSet {
        get {
            var indexSet = IndexSet()
            for pageID in self.selectedPageIDs {
                guard let index = self.pageItems.firstIndex(where: { $0.id == pageID}) else {
                    continue
                }
                indexSet.insert(index)
            }
            return indexSet
        }
        set {
            var newSelectedIDs = Set<ModelID>()
            for index in newValue {
                guard (index >= 0) && (index < self.pageItems.count) else {
                    continue
                }
                newSelectedIDs.insert(self.pageItems[index].id)
            }

            guard newSelectedIDs.count == newValue.count else {
                return
            }
            self.selectedObjectIDs = newSelectedIDs
        }
    }

    var selectedPages: [Page] {
        return self.selectedPageIDs.compactMap { self.pages.objectWithID($0) }
    }


    //MARK: - Search
    private func updateSearch() {
        self.reloadPages()
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
