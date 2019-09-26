//
//  CanvasEditorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol CanvasEditorView: class {
}

class CanvasEditorViewModel: NSObject {
    weak var view: CanvasEditorView?

    let layoutEngine = CanvasLayoutEngine()

    let canvas: Canvas
    let modelController: BubblesModelController
    init(canvas: Canvas, modelController: BubblesModelController) {
        self.canvas = canvas
        self.modelController = modelController
        super.init()

        self.setupObservation()
        self.updatePages()

        self.layoutEngine.delegate = self
    }


    //MARK: - Observation
    var canvasObserver: ModelCollection<Canvas>.Observation?
    private func setupObservation() {
        self.canvasObserver = self.modelController.canvases.addObserver(filterBy: [self.canvas.id]) { [weak self] (canvas, changeType) in
            if changeType == .update {
                self?.updatePages()
            }
        }
    }

    deinit {
        if let observer = self.canvasObserver {
            self.modelController.canvases.removeObserver(observer)
        }
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var set = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == #keyPath(zoomPercentage)) {
            set.insert(#keyPath(zoomFactor))
        }
        return set
    }

    //Using an add to canvas control
    //Dropping a page on the canvas
    //Dropping content on a canvas

    func close(_ canvasPage: CanvasPage) {
        canvasPage.canvas = nil
        self.modelController.canvasPages.delete(canvasPage)
    }

    //MARK: - Page Management
    private(set) var canvasPages = Set<CanvasPage>()

    func canvasPage(with uuid: UUID) -> CanvasPage? {
        return self.canvasPages.first(where: { $0.id.uuid == uuid })
    }

    func addPages(_ canvasPages: Set<CanvasPage>) {
        let layoutEnginePages = canvasPages.map { self.createLayoutPage(for: $0) }
        self.layoutEngine.add(layoutEnginePages)
    }

    func removePages(_ canvasPages: Set<CanvasPage>) {
        let idsToRemove = canvasPages.map { $0.id.uuid }
        let layoutPagesToRemove = self.layoutEngine.pages.filter { idsToRemove.contains($0.id) }
        self.layoutEngine.remove(layoutPagesToRemove)
    }

    private func createLayoutPage(for canvasPage: CanvasPage) -> LayoutEnginePage {
        let layoutPage = LayoutEnginePage(id: canvasPage.id.uuid, pageOrigin: canvasPage.position, size: canvasPage.size)
        layoutPage.minSize = CGSize(width: 100, height: 100)
        return layoutPage
    }

    func createTestPage() {
        let canvasPage = self.modelController.canvasPages.newObject()
        canvasPage.position = CGPoint(x: 100, y: 100)
        canvasPage.size = CGSize(width: 300, height: 400)
        canvasPage.canvas = self.canvas
        self.updatePages()
    }

    private func updatePages() {
        let newPages = self.canvas.pages
        let addedPages = newPages.subtracting(self.canvasPages)
        let removedPages = self.canvasPages.subtracting(newPages)

        self.addPages(addedPages)
        self.removePages(removedPages)

        self.canvasPages = newPages
    }


    //MARK: - Zooming
    @objc dynamic var zoomFactor: CGFloat = 1 {
        didSet {
            if self.zoomFactor > 1 {
                self.zoomFactor = 1
            }
            if self.zoomFactor < 0.25 {
                self.zoomFactor = 0.25
            }
        }
    }

    @objc dynamic var zoomControlOptions: String {
        return "\((self.zoomFactor * 100).rounded())%"
    }

    @objc dynamic var zoomControlSelectedOption: Int

    func zoomIn() {

    }

    func zoomOut() {

    }

    func zoomTo100() {

    }
}

extension CanvasEditorViewModel: CanvasLayoutEngineDelegate {
    func moved(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine) {
        for page in pages {
            guard let canvasPage = self.canvasPage(with: page.id) else {
                continue
            }
            canvasPage.position = page.pageOrigin
            canvasPage.size = page.size
        }
    }
}
