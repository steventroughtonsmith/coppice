//
//  CanvasEditorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

protocol CanvasEditorView: class {
    func updateZoomFactor()
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
        self.updatePages()

        self.layoutEngine.delegate = self
    }


    //MARK: - Observation
    var canvasObserver: ModelCollection<Canvas>.Observation?
    var canvasPageObserver: ModelCollection<CanvasPage>.Observation?
    private func setupObservation() {
        self.canvasObserver = self.modelController.collection(for: Canvas.self).addObserver(filterBy: [self.canvas.id]) { [weak self] (canvas, changeType) in
            if changeType == .update {
                self?.updatePages()
            }
        }
        self.canvasPageObserver = self.modelController.collection(for: CanvasPage.self).addObserver() { [weak self] (canvas, changeType) in
            self?.updatePages()
        }
    }

    deinit {
        if let observer = self.canvasObserver {
            self.modelController.collection(for: Canvas.self).removeObserver(observer)
        }
        if let observer = self.canvasPageObserver {
            self.modelController.collection(for: CanvasPage.self).removeObserver(observer)
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
            self.canvas.viewPort = newViewPort
        }
    }


    //MARK: - Page Management
    private(set) var canvasPages = Set<CanvasPage>()

    var selectedCanvasPages: Set<CanvasPage> {
        let selectedPageIDs = self.layoutEngine.selectedPages.map { $0.id }
        return self.canvasPages.filter { selectedPageIDs.contains($0.id.uuid) }
    }

    func close(_ canvasPage: CanvasPage) {
        self.documentWindowViewModel.remove(canvasPage)
    }

    func canvasPage(with uuid: UUID) -> CanvasPage? {
        return self.canvasPages.first(where: { $0.id.uuid == uuid })
    }

    private func addPages(_ canvasPages: Set<CanvasPage>) {
        let newPages = canvasPages.map { LayoutEnginePage(id: $0.id.uuid, contentFrame: $0.frame) }

        let newPagesByID = newPages.indexed(by: \.id)

        for canvasPage in canvasPages {
            guard let parentID = canvasPage.parent?.id.uuid else {
                continue
            }
            guard let parentPage = newPagesByID[parentID] ?? self.layoutEngine.page(withID: parentID) else {
                assertionFailure("Parent (\(parentID)) did not exist in newly created pages or layout engine")
                continue
            }

            guard let page = newPagesByID[canvasPage.id.uuid] else {
                assertionFailure("WTF?! You should have literally just added this page (\(canvasPage.id.uuid)). Where has it gone?")
                continue
            }
            parentPage.addChild(page)
        }

        self.layoutEngine.add(newPages)
    }

    private func removePages(_ canvasPages: Set<CanvasPage>) {
        let idsToRemove = canvasPages.map { $0.id.uuid }
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
        let addedPages = newPages.subtracting(self.canvasPages)
        let removedPages = self.canvasPages.subtracting(newPages)
        let remainingPages = newPages.subtracting(addedPages)

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

    func addPage(at link: PageLink, centredOn point: CGPoint? = nil) {
        self.documentWindowViewModel.addPage(at: link, to: self.canvas)
    }

    func addPage(with id: ModelID, centredOn point: CGPoint? = nil) {
        guard let page = self.modelController.collection(for: Page.self).objectWithID(id) else {
            return
        }

        self.documentWindowViewModel.addPages([page], to: self.canvas, centredOn: point)
    }

    func addPages(forFilesAtURLs urls: [URL], centredOn point: CGPoint? = nil) {
        let pagePosition = (point != nil) ? self.layoutEngine.convertPointToPageSpace(point!) : nil
        self.documentWindowViewModel.createPages(fromFilesAtURLs: urls, addingTo: self.canvas, centredOn: pagePosition)
    }

    func dragImageForPage(with id: ModelID) -> NSImage? {
        return self.documentWindowViewModel.pageImageController.imageForPage(with: id)
    }


    //MARK: - Zooming
    @objc dynamic var zoomFactor: CGFloat = 1 {
        didSet {
            if self.zoomFactor > 1 {
                self.zoomFactor = 1
            }
            else if self.zoomFactor < 0.25 {
                self.zoomFactor = 0.25
            }
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
        return self.selectedZoomLevel < (zoomLevels.count - 1)
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


    //MARK: - Inspectors
    var canvasInspectorViewModel: CanvasInspectorViewModel {
        return CanvasInspectorViewModel(canvas: self.canvas, modelController: self.modelController)
    }
}

extension CanvasEditorViewModel: CanvasLayoutEngineDelegate {
    func remove(pages: [LayoutEnginePage], from layout: CanvasLayoutEngine) {
        for page in pages {
            guard let canvasPage = self.canvasPage(with: page.id) else {
                continue
            }
            self.close(canvasPage)
        }
    }

    func moved(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine) {
        self.updatesDisable = true
        for page in pages {
            guard let canvasPage = self.canvasPage(with: page.id) else {
                continue
            }
            if canvasPage.frame != page.contentFrame {
                canvasPage.frame = page.contentFrame
            }
        }
        self.updatesDisable = false
    }
}
