//
//  ThumbnailController.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ThumbnailController: NSObject {
    let modelController: CoppiceModelController
    init(modelController: CoppiceModelController) {
        self.modelController = modelController
        super.init()
        self.setupObservation()
    }

    weak var documentViewModel: DocumentWindowViewModel?
    var currentThumbnailSize: CGSize = GlobalConstants.maxCanvasThumbnailSize {
        didSet {
            self.modelController.canvasCollection.all.forEach { self.changed($0) }
            self.updateThumbnails()
        }
    }


    //MARK: - Observation
    var canvasObserver: ModelCollection<Canvas>.Observation?
    var canvasPageObserver: ModelCollection<CanvasPage>.Observation?
    var pageObserver: ModelCollection<Page>.Observation?
    private func setupObservation() {
        self.canvasObserver = self.modelController.canvasCollection.addObserver { [weak self] (change) in
            self?.changed(change.object)
        }

        self.canvasPageObserver = self.modelController.canvasPageCollection.addObserver { [weak self] (change) in
            self?.changed(change.object)
        }

        self.pageObserver = self.modelController.pageCollection.addObserver { [weak self] (change) in
            self?.changed(change.object)
        }
    }

    deinit {
        if let observer = self.canvasObserver {
            self.modelController.canvasCollection.removeObserver(observer)
        }
        if let observer = self.canvasPageObserver {
            self.modelController.canvasPageCollection.removeObserver(observer)
        }
        if let observer = self.pageObserver {
            self.modelController.pageCollection.removeObserver(observer)
        }
    }


    //MARK: - Handle Changes
    private func changed(_ canvas: Canvas) {
        self.needsUpdatedThumbnail(for: canvas)
    }

    private func changed(_ canvasPage: CanvasPage) {
        if let canvas = canvasPage.canvas {
            self.needsUpdatedThumbnail(for: canvas)
        }
    }

    private func changed(_ page: Page) {
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
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateThumbnails), object: nil)
        guard self.currentThumbnailSize != .zero else {
            return
        }
        self.modelController.disableUndo {
            for object in self.canvasChangeQueue {
                if let canvas = object as? Canvas {
                    canvas.thumbnail = self.generateThumbnail(for: canvas)
                }
            }
            self.canvasChangeQueue.removeAllObjects()
        }
    }

    func generateThumbnail(for canvas: Canvas) -> NSImage? {
        //No need to generate a preview if the canvas contains nothing
        guard canvas.pages.count > 0 else {
            return nil
        }

        let thumbnailController = CanvasThumbnailGenerator(canvas: canvas)
        return thumbnailController.generateThumbnail(of: self.currentThumbnailSize)
    }
}
