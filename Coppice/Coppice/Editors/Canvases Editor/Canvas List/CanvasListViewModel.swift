//
//  CanvasListViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore
import M3Data

protocol CanvasListView: AnyObject {
    func reload()
    func reloadSelection()
}

class CanvasListViewModel: ViewModel {
    weak var view: CanvasListView?

    //MARK: - Subscribers
    private enum SubscriberKey {
        case canvas
        case selectedCanvas
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    //MARK: - Observation
    func startObserving() {
        self.subscribers[.canvas] = self.canvasCollection.changePublisher.sink { [weak self] _ in
            self?.reloadCanvases()
        }
        self.subscribers[.selectedCanvas] = self.documentWindowViewModel.$selectedCanvasID.sink { [weak self] canvasID in
            self?.cachedCanvases = nil //BUB-195: Just in case we receive this before a reload canvases, lets clear the cache
            self?.selectedCanvasIndex = self?.canvases.firstIndex { $0.id == canvasID }
        }
    }

    func stopObserving() {
        self.subscribers = [:]
    }


    //MARK: - Fetching Canvases
    private var canvasCollection: ModelCollection<Canvas> {
        return self.modelController.collection(for: Canvas.self)
    }

    private var cachedCanvases: [Canvas]?
    var canvases: [Canvas] {
        if let cachedCanvases = self.cachedCanvases {
            return cachedCanvases
        }

        let items = self.canvasCollection.sortedCanvases
        self.cachedCanvases = items
        return items
    }

    private func reloadCanvases() {
        self.cachedCanvases = nil
        self.view?.reload()
    }

    var selectedCanvasIndex: Int? {
        didSet {
            self.view?.reloadSelection()
        }
    }

    func selectCanvas(atIndex index: Int) {
        guard index >= 0 && index < self.canvases.count else {
            self.documentWindowViewModel.selectedCanvasID = nil
            return
        }
        self.documentWindowViewModel.selectedCanvasID = self.canvases[index].id
    }

    func select(_ canvas: Canvas) {
        self.documentWindowViewModel.selectedCanvasID = canvas.id
    }


    //MARK: Modifying Canvases
    func addPage(with id: ModelID, toCanvasAtIndex index: Int) {
        guard let page = self.modelController.pageCollection.objectWithID(id) else {
            return
        }
        let canvas = self.canvases[index]
        var centrePoint = CGPoint.zero
        if let viewPort = canvas.viewPort {
            centrePoint = CGPoint(x: viewPort.midX, y: viewPort.midY)
        }
        canvas.addPages([page], centredOn: centrePoint)
        self.documentWindowViewModel.clearSavedNavigation()
    }

    func addPages(fromFilesAtURLs fileURLs: [URL], toCanvasAtIndex canvasIndex: Int?) -> [Page] {
        var canvas: Canvas?
        if let index = canvasIndex {
            canvas = self.canvases[index]
        }
        self.documentWindowViewModel.clearSavedNavigation()
        return self.modelController.createPages(fromFilesAt: fileURLs, in: self.documentWindowViewModel.folderForNewPages) { (pages) in
            canvas?.addPages(pages)
        }
    }

    func moveCanvas(with id: ModelID, aboveCanvasAtIndex index: Int) {
        guard id.modelType == Canvas.modelType else {
            return
        }

        var canvases: [Canvas?] = self.canvases
        guard let currentIndex = canvases.firstIndex(where: { $0?.id == id }) else {
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
        self.cachedCanvases = nil
    }

    func deleteCanvas(atIndex index: Int) {
        guard index >= 0 else {
            return
        }

        guard let canvas = self.canvases[safe: index] else {
            return
        }

        self.documentWindowViewModel.delete(canvas)
    }
}
