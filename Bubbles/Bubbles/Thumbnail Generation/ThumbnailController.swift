//
//  ThumbnailController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 06/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ThumbnailController: NSObject {
    let modelController: ModelController
    init(modelController: ModelController) {
        self.modelController = modelController
        super.init()
        self.setupObservation()
    }

    weak var documentViewModel: DocumentWindowViewModel?


    //MARK: - Observation
    var canvasObserver: ModelCollection<Canvas>.Observation?
    var canvasPageObserver: ModelCollection<CanvasPage>.Observation?
    var pageObserver: ModelCollection<Page>.Observation?
    private func setupObservation() {
        self.canvasObserver = self.modelController.collection(for: Canvas.self).addObserver { [weak self] (canvas, changeType) in
            self?.changed(canvas, changeType: changeType)
        }

        self.canvasPageObserver = self.modelController.collection(for: CanvasPage.self).addObserver { [weak self] (canvasPage, changeType) in
            self?.changed(canvasPage, changeType: changeType)
        }

        self.pageObserver = self.modelController.collection(for: Page.self).addObserver { [weak self] (page, changeType) in
            self?.changed(page, changeType: changeType)
        }
    }

    deinit {
        if let observer = self.canvasObserver {
            self.modelController.collection(for: Canvas.self).removeObserver(observer)
        }
        if let observer = self.canvasPageObserver {
            self.modelController.collection(for: CanvasPage.self).removeObserver(observer)
        }
        if let observer = self.pageObserver {
            self.modelController.collection(for: Page.self).removeObserver(observer)
        }
    }


    //MARK: - Handle Changes
    private func changed(_ canvas: Canvas, changeType: ModelChangeType) {
        self.needsUpdatedThumbnail(for: canvas)
    }

    private func changed(_ canvasPage: CanvasPage, changeType: ModelChangeType) {
        if let canvas = canvasPage.canvas {
            self.needsUpdatedThumbnail(for: canvas)
        }
    }

    private func changed(_ page: Page, changeType: ModelChangeType) {
        for canvasPage in page.canvases {
            if let canvas = canvasPage.canvas {
                self.needsUpdatedThumbnail(for: canvas)
            }
        }
    }


    //MARK: - Perform Update
    let canvasChangeQueue = NSMutableOrderedSet()
    func needsUpdatedThumbnail(for canvas: Canvas) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateThumbnails), object: nil)
        self.canvasChangeQueue.add(canvas)
        self.perform(#selector(updateThumbnails), with: nil, afterDelay: 3)
    }

    @objc dynamic func updateThumbnails() {
        for object in self.canvasChangeQueue {
            if let canvas = object as? Canvas {
                canvas.thumbnail = self.generateThumbnail(for: canvas)
            }
        }
        self.canvasChangeQueue.removeAllObjects()
    }

    func generateThumbnail(for canvas: Canvas) -> NSImage? {
        guard let documentViewModel = self.documentViewModel else {
            return nil
        }
        let canvasEditor = CanvasEditorViewController(viewModel: CanvasEditorViewModel(canvas: canvas, documentWindowViewModel: documentViewModel, mode: .preview))
        _ = canvasEditor.view
        guard let canvasView = canvasEditor.canvasView else {
            return nil
        }
        canvasView.setNeedsDisplay(canvasView.bounds)
        return canvasView.generateThumbnail()
    }
}
