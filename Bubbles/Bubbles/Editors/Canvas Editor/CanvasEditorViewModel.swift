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

    //Using an add to canvas control
    //Dropping a page on the canvas
    //Dropping content on a canvas

    //MARK: - Page Management
    private(set) var canvasPages = Set<CanvasPage>()

    func add(_ page: CanvasPage) {

    }

    func createTestPage() {
        let canvasPage = self.modelController.canvasPages.newObject()
        canvasPage.position = CGPoint(x: 100, y: 100)
        canvasPage.size = CGSize(width: 300, height: 400)
        canvasPage.canvas = self.canvas
    }

    func remove(_ page: CanvasPage) {
        self.modelController.canvasPages.delete(page)
    }

    private func updatePages() {
        let newPages = self.canvas.pages
        let addedPages = newPages.subtracting(self.canvasPages)
        let removedPages = self.canvasPages.subtracting(newPages)

        self.canvasPages = newPages

    }
}
