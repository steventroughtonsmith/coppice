//
//  ThumbnailController.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore
import M3Data

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

    //MARK: - Subscribers
    private enum SubscriberKey {
        case canvases
        case canvasPages
        case pages
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]


    //MARK: - Observation
    private func setupObservation() {
        self.subscribers[.canvases] = self.modelController.canvasCollection.changePublisher.sink { [weak self] (change) in
            self?.changed(change.object)
        }

        self.subscribers[.canvasPages] = self.modelController.canvasPageCollection.changePublisher.sink { [weak self] (change) in
            self?.changed(change.object)
        }

        self.subscribers[.pages] = self.modelController.pageCollection.changePublisher.sink { [weak self] (change) in
            self?.changed(change.object)
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
        for canvasPage in page.canvasPages {
            if let canvas = canvasPage.canvas {
                self.needsUpdatedThumbnail(for: canvas)
            }
        }
    }


    //MARK: - Perform Update
    let canvasChangeQueue = NSMutableOrderedSet()
    func needsUpdatedThumbnail(for canvas: Canvas) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.updateThumbnails), object: nil)
        self.canvasChangeQueue.add(canvas)
        self.perform(#selector(self.updateThumbnails), with: nil, afterDelay: 3)
    }

    @objc dynamic func updateThumbnails() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.updateThumbnails), object: nil)
        guard self.currentThumbnailSize != .zero else {
            return
        }
        self.modelController.disableUndo {
            for object in self.canvasChangeQueue {
                guard
                    let canvas = object as? Canvas,
                    let thumbnailImageData = self.generateThumbnail(for: canvas)?.pngData()
                else {
                    continue
                }
                canvas.thumbnail = .init(data: thumbnailImageData, canvasID: canvas.id)
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
