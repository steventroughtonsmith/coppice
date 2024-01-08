//
//  CanvasEditorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import Combine
import CoppiceCore
import M3Data
import M3Subscriptions

protocol CanvasEditorView: AnyObject {
    func updateZoomFactor()
    func flash(_ canvasPage: CanvasPage)
    func notifyAccessibilityOfMove(_ canvasPages: [CanvasPage])
    func themeDidChange()
}

class CanvasEditorViewModel: ViewModel {
    weak var view: CanvasEditorView?

    let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .mac, contentBorder: 1000, arrow: .standard))

    let canvas: Canvas
    init(canvas: Canvas, documentWindowViewModel: DocumentWindowViewModel) {
        self.canvas = canvas
        super.init(documentWindowViewModel: documentWindowViewModel)
    }

    override func setup() {
        self.setupObservation()
        self.setupProObservation()
        self.updatePages()
        self.updateLinks()

        self.layoutEngine.delegate = self
    }

    //MARK: - Pro
    @objc dynamic var isLocked: Bool = false {
        didSet {
            self.updatePages()
            self.layoutEngine.editable = !self.isLocked
        }
    }

    private var isProEnabled = false {
        didSet {
            guard self.isProEnabled != oldValue else {
                return
            }
            self.updateAlwaysShowPageTitles()
        }
    }

    var activationObserver: AnyCancellable?
    private func setupProObservation() {
        self.activationObserver = CoppiceSubscriptionManager.shared.$state.sink { [weak self] state in
            self?.updateLockedStatus(for: state)
        }
    }

    private func updateLockedStatus(for state: CoppiceSubscriptionManager.State) {
        self.isProEnabled = (state == .enabled)
        if self.isProEnabled {
            self.isLocked = false
            return
        }

        let firstCanvas = self.modelController.canvasCollection.sortedCanvases.first
        self.isLocked = (self.canvas != firstCanvas)
    }

    private func updateAlwaysShowPageTitles() {
        self.layoutEngine.alwaysShowPageTitles = self.isProEnabled && self.canvas.alwaysShowPageTitles
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case canvasChange
        case canvasPageChange
        case canvasLinkChange
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]


    //MARK: - Observation
    private func setupObservation() {
        self.subscribers[.canvasChange] = self.canvas.changePublisher?
            .filter { $0.changeType == .update && !$0.didUpdate(\.thumbnail) }
            .sink { [weak self] change in
                self?.wantsUpdate = true
                self?.updateIfNeeded()
                if change.didUpdate(\.alwaysShowPageTitles) {
                    self?.updateAlwaysShowPageTitles()
                }
                if change.didUpdate(\.theme) {
                    self?.view?.themeDidChange()
                }
            }

        self.subscribers[.canvasPageChange] = self.modelController.canvasPageCollection.changePublisher.sink { [weak self] _ in
            self?.wantsUpdate = true
        }

        self.subscribers[.canvasLinkChange] = self.modelController.canvasLinkCollection.changePublisher.sink { [weak self] _ in
            self?.wantsUpdate = true
        }
    }


    //MARK: - View Port
    var viewPortInCanvasSpace: CGRect? {
        get {
            guard var viewPort = self.canvas.viewPort else {
                return nil
            }
            viewPort.origin = viewPort.origin.multiplied(by: -1)
            return viewPort
        }
        set {
            guard var newViewPort = newValue else {
                self.canvas.viewPort = nil
                return
            }
            newViewPort.origin = newViewPort.origin.multiplied(by: -1)
            guard self.canvas.viewPort != newViewPort else {
                return
            }
            self.canvas.viewPort = newViewPort
        }
    }

    //MARK: - Updating
    private var wantsUpdate: Bool = false {
        didSet {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.updateIfNeeded), object: nil)
            if self.wantsUpdate {
                self.perform(#selector(self.updateIfNeeded), with: nil, afterDelay: 0)
            }
        }
    }

    @objc dynamic func updateIfNeeded() {
        guard self.wantsUpdate else {
            return
        }
        self.updatePages()
        self.updateLinks()
        self.wantsUpdate = false
    }


    //MARK: - Page Management
    private(set) var canvasPages = Set<CanvasPage>()

    var selectedCanvasPages: Set<CanvasPage> {
        let selectedPageIDs = self.layoutEngine.selectedItems.map { $0.id }
        return self.canvasPages.filter { selectedPageIDs.contains($0.id.uuid) }
    }

    func close(_ canvasPage: CanvasPage) {
        self.modelController.close(canvasPage)
    }

    func select(_ canvasPage: CanvasPage, extendingSelection: Bool = false) {
        guard let page = self.layoutEngine.page(withID: canvasPage.id.uuid) else {
            return
        }
        self.layoutEngine.select([page], extendingSelection: extendingSelection)
    }

    func deselect(_ canvasPage: CanvasPage) {
        guard let page = self.layoutEngine.page(withID: canvasPage.id.uuid) else {
            return
        }
        self.layoutEngine.deselect([page])
    }

    func canvasPage(with uuid: UUID) -> CanvasPage? {
        return self.canvasPages.first(where: { $0.id.uuid == uuid })
    }

    private func addPages(_ canvasPages: Set<CanvasPage>) {
        guard canvasPages.count > 0 else {
            return
        }

        let newPages = canvasPages
            .map { LayoutEnginePage(canvasPage: $0) }
            .sorted { $0.zIndex < $1.zIndex }

        self.layoutEngine.add(newPages)
    }

    private func removePages(_ canvasPages: Set<CanvasPage>) {
        guard canvasPages.count > 0 else {
            return
        }

        let idsToRemove = canvasPages.map(\.id.uuid)
        let layoutPagesToRemove = self.layoutEngine.pages.filter { idsToRemove.contains($0.id) }
        self.layoutEngine.remove(layoutPagesToRemove)
    }

    private func updatePages(_ canvasPages: Set<CanvasPage>) {
        canvasPages.forEach { self.layoutEngine.updateContentFrame($0.frame, ofPageWithID: $0.id.uuid) }
    }

    private var updatesDisable = false

    private func updatePages() {
        guard !self.updatesDisable else {
            return
        }

        //We need to temporarily disable updates in case our changes cause updates themselves
        self.updatesDisable = true

        let newPages = self.canvas.pages
        let (addedPages, removedPages, remainingPages) = self.canvasPages.differencesFrom(newPages)

        self.canvasPages = newPages

        self.addPages(addedPages)
        self.removePages(removedPages)
        self.updatePages(remainingPages)

        self.updatesDisable = false
    }

    func createTestPage() {
        self.modelController.collection(for: CanvasPage.self).newObject() { canvasPage in
            if let viewPort = self.canvas.viewPort {
                canvasPage.frame = CGRect(width: 300, height: 400, centredIn: viewPort)
            } else {
                canvasPage.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
            }
            canvasPage.canvas = self.canvas
        }
        self.updatePages()
    }

    func newPage(of type: Page.ContentType, centredOn point: CGPoint? = nil) {
        self.modelController.createPage(ofType: type, in: self.documentWindowViewModel.folderForNewPages) { (page) in
            self.canvas.addPages([page], centredOn: point)
        }
    }

    func addPage(at link: PageLink, centredOn point: CGPoint? = nil, useAlternate: Bool = false) {
        let linkToExistingByDefault = UserDefaults.standard.bool(forKey: .linkToExistingPagesByDefault) && self.isProEnabled
        let mode: Canvas.OpenPageMode
        if useAlternate {
            mode = linkToExistingByDefault ? .new : .existing
        } else {
            mode = linkToExistingByDefault ? .existing : .new
        }

        for canvasPage in self.modelController.openPage(at: link, on: self.canvas, mode: mode) {
            self.view?.flash(canvasPage)
        }
    }

    func addPages(with ids: [ModelID], centredOn point: CGPoint? = nil) {
        self.documentWindowViewModel.registerStartOfEditing()
        let pages = ids.compactMap { self.modelController.pageCollection.objectWithID($0) }

        self.canvas.addPages(pages, centredOn: point)
        self.documentWindowViewModel.clearSavedNavigation()
    }

    func addPages(forFilesAtURLs urls: [URL], centredOn point: CGPoint? = nil) {
        self.documentWindowViewModel.registerStartOfEditing()
        let pagePosition = (point != nil) ? self.layoutEngine.convertPointToPageSpace(point!) : nil
        self.modelController.createPages(fromFilesAt: urls, in: self.documentWindowViewModel.folderForNewPages) { (pages) in
            self.canvas.addPages(pages, centredOn: pagePosition)
        }
        self.documentWindowViewModel.clearSavedNavigation()
    }

    func dragImageForPage(with id: ModelID) -> NSImage? {
        return self.documentWindowViewModel.pageImageController.imageForPage(with: id)
    }

    func sourcePage(for link: LayoutEngineLink) -> Page? {
        return self.canvasPage(with: link.sourcePageID)?.page
    }


    //MARK: - Links
    private(set) var canvasLinks: Set<CanvasLink> = []

    func canvasLink(with uuid: UUID) -> CanvasLink? {
        return self.canvasLinks.first(where: { $0.id.uuid == uuid })
    }

    private func addLinks(_ links: Set<CanvasLink>) {
        guard links.count > 0 else {
            return
        }

        let newLinks = links.compactMap { LayoutEngineLink(canvasLink: $0) }
        self.layoutEngine.add(newLinks)
    }

    private func removeLinks(_ links: Set<CanvasLink>) {
        guard links.count > 0 else {
            return
        }

        let idsToRemove = links.map(\.id.uuid)
        let layoutLinksToRemove = self.layoutEngine.links.filter { idsToRemove.contains($0.id) }
        self.layoutEngine.remove(layoutLinksToRemove)
    }

    private func updateLinks() {
        guard !self.updatesDisable else {
            return
        }

        //We need to temporarily disable updates in case our changes cause updates themselves
        self.updatesDisable = true

        let newLinks = self.canvas.links
        let (addedLinks, removedLinks, _) = self.canvasLinks.differencesFrom(newLinks)

        self.canvasLinks = newLinks

        self.addLinks(addedLinks)
        self.removeLinks(removedLinks)

        self.updatesDisable = false
    }


    //MARK: - Creating Links
    private var linkingEditor: PageContentEditor?
    func startLinking(from editor: PageContentEditor) {
        self.linkingEditor = editor
        self.layoutEngine.startLinking()
    }

    func finishLinking(toDestination page: LayoutEnginePage?) {
        guard
            let page,
            let sourceCanvasPage = self.linkingEditor?.canvasPageViewController?.viewModel.canvasPage,
            let destinationCanvasPage = self.canvasPage(with: page.id),
            let destinationPage = destinationCanvasPage.page
        else {
            self.linkingEditor = nil
            return
        }
        self.linkingEditor?.createLink(to: destinationPage)



        self.canvas.addLink(PageLink(destinationPage: destinationPage, sourceCanvasPage: sourceCanvasPage), between: sourceCanvasPage, and: destinationCanvasPage)

        self.linkingEditor = nil
    }


    //MARK: - Zooming
    @objc dynamic var zoomFactor: CGFloat {
        get { return self.canvas.zoomFactor }
        set {
            self.canvas.zoomFactor = newValue
            self.view?.updateZoomFactor()
        }
    }

    var zoomLevels: [Int] {
        var baseLevels = [25, 50, 75, 100]
        let zoomFactorLevel = Int((self.zoomFactor * 100))
        if (!baseLevels.contains(zoomFactorLevel)) {
            baseLevels.append(zoomFactorLevel)
            baseLevels.sort()
        }
        return baseLevels
    }

    var selectedZoomLevel: Int {
        get {
            let zoomFactorLevel = Int((self.zoomFactor * 100))
            return self.zoomLevels.firstIndex(of: zoomFactorLevel) ?? 0
        }
        set {
            let index = max(min(newValue, (self.zoomLevels.count - 1)), 0)
            let zoomLevel = self.zoomLevels[index]
            self.zoomFactor = CGFloat(zoomLevel) / 100
        }
    }

    var canZoomIn: Bool {
        return self.selectedZoomLevel < (self.zoomLevels.count - 1)
    }

    func zoomIn() {
        self.selectedZoomLevel += 1
    }

    var canZoomOut: Bool {
        return self.selectedZoomLevel > 0
    }

    func zoomOut() {
        self.selectedZoomLevel -= 1
    }

    var canZoomTo100: Bool {
        return self.zoomFactor != 1
    }

    func zoomTo100() {
        self.zoomFactor = 1
    }


    //MARK: - Theming
    var theme: Canvas.Theme {
        guard CoppiceSubscriptionManager.shared.state == .enabled else {
            return .auto
        }
        return self.canvas.theme
    }


    //MARK: - Inspectors
    var canvasInspectorViewModel: CanvasInspectorViewModel {
        return CanvasInspectorViewModel(canvas: self.canvas, modelController: self.modelController)
    }
}

extension CanvasEditorViewModel: CanvasLayoutEngineDelegate {
    func remove(items: [LayoutEngineItem], from layout: CanvasLayoutEngine) {
        for page in items.pages {
            guard let canvasPage = self.canvasPage(with: page.id) else {
                continue
            }
            self.close(canvasPage)
        }
        for link in items.links {
            guard let link = self.canvasLink(with: link.id) else {
                continue
            }
            self.modelController.canvasLinkCollection.delete(link)
        }
    }

    func moved(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine) {
        self.updatesDisable = true
        var canvasPages = [CanvasPage]()
        for page in pages {
            guard let canvasPage = self.canvasPage(with: page.id) else {
                continue
            }
            if canvasPage.frame != page.contentFrame {
                canvasPage.frame = page.contentFrame
            }
            if canvasPage.zIndex != page.zIndex {
                canvasPage.zIndex = page.zIndex
            }
            canvasPages.append(canvasPage)
        }
        self.view?.notifyAccessibilityOfMove(canvasPages)
        self.updatesDisable = false
    }

    func reordered(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine) {
        self.updatesDisable = true
        for page in pages {
            guard let canvasPage = self.canvasPage(with: page.id) else {
                continue
            }
            if canvasPage.zIndex != page.zIndex {
                canvasPage.zIndex = page.zIndex
            }
        }
        self.updatesDisable = false
    }

    func finishLinking(withDestination page: LayoutEnginePage?, in layout: CanvasLayoutEngine) {
        self.finishLinking(toDestination: page)
    }
}
