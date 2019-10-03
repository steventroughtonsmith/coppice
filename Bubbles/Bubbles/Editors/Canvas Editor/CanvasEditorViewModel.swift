//
//  CanvasEditorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol CanvasEditorView: class {
    func updateZoomFactor()
}

class CanvasEditorViewModel: NSObject {
    weak var view: CanvasEditorView?

    let layoutEngine = CanvasLayoutEngine()

    let canvas: Canvas
    let modelController: ModelController
    init(canvas: Canvas, modelController: ModelController) {
        self.canvas = canvas
        self.modelController = modelController
        super.init()

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
            if changeType == .update {
                self?.updatePages()
            } else if changeType == .insert {
                self?.updatePages()
            }
        }
    }

    deinit {
        if let observer = self.canvasObserver {
            self.modelController.collection(for: Canvas.self).removeObserver(observer)
        }
    }

    //Using an add to canvas control
    //Dropping a page on the canvas
    //Dropping content on a canvas

    func close(_ canvasPage: CanvasPage) {
        canvasPage.canvas = nil
        self.modelController.collection(for: CanvasPage.self).delete(canvasPage)
    }


    //MARK: - Page Management
    private(set) var canvasPages = Set<CanvasPage>()

    func canvasPage(with uuid: UUID) -> CanvasPage? {
        return self.canvasPages.first(where: { $0.id.uuid == uuid })
    }

    private func addPages(_ canvasPages: Set<CanvasPage>) {
        let layoutEnginePages = canvasPages.map { self.createLayoutPage(for: $0) }
        self.layoutEngine.add(layoutEnginePages)
    }

    private func removePages(_ canvasPages: Set<CanvasPage>) {
        let idsToRemove = canvasPages.map { $0.id.uuid }
        let layoutPagesToRemove = self.layoutEngine.pages.filter { idsToRemove.contains($0.id) }
        self.layoutEngine.remove(layoutPagesToRemove)
    }

    private func createLayoutPage(for canvasPage: CanvasPage) -> LayoutEnginePage {
        let layoutPage = LayoutEnginePage(id: canvasPage.id.uuid, contentFrame: canvasPage.frame)
        layoutPage.minSize = CGSize(width: 100, height: 100)
        return layoutPage
    }

    private func updatePages() {
        let newPages = self.canvas.pages
        let addedPages = newPages.subtracting(self.canvasPages)
        let removedPages = self.canvasPages.subtracting(newPages)

        self.addPages(addedPages)
        self.removePages(removedPages)

        self.canvasPages = newPages
    }

    func createTestPage() {
        self.modelController.collection(for: CanvasPage.self).newObject() { canvasPage in
            canvasPage.frame = CGRect(x: 100, y: 100, width: 300, height: 400)
            canvasPage.canvas = self.canvas
        }
        self.updatePages()
    }

    func addPage(with id: ModelID, centredOn point: CGPoint) {
        guard let page = self.modelController.collection(for: Page.self).objectWithID(id) else {
            return
        }

        let pagePosition = self.layoutEngine.convertPointToPageSpace(point)
        self.canvas.add(page, centredOn: pagePosition)
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

    func zoomIn() {
        self.selectedZoomLevel += 1
    }

    func zoomOut() {
        self.selectedZoomLevel -= 1
    }

    func zoomTo100() {
        self.zoomFactor = 1
    }
}

extension CanvasEditorViewModel: CanvasLayoutEngineDelegate {
    func moved(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine) {
        for page in pages {
            guard let canvasPage = self.canvasPage(with: page.id) else {
                continue
            }
            canvasPage.frame = page.contentFrame
        }
    }
}
