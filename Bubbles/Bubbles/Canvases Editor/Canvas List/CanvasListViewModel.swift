//
//  CanvasListViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 06/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

protocol CanvasListView: class {
    func reload()
    func reloadSelection()
}

class CanvasListViewModel: ViewModel {
    weak var view: CanvasListView?

    //MARK: - Observation
    private var canvasObserver: ModelCollection<Canvas>.Observation?
    private var selectedCanvasObserver: AnyCancellable?
    func startObserving() {
        self.canvasObserver = self.canvasCollection.addObserver { [weak self] canvas, change in
            self?.reloadCanvases()
        }
        self.selectedCanvasObserver = self.documentWindowViewModel.$selectedCanvasID.sink { [weak self] canvasID in
            self?.selectedCanvasIndex = self?.canvases.firstIndex { $0.id == canvasID }
        }
    }

    func stopObserving() {
        if let observer = self.canvasObserver {
        	self.canvasCollection.removeObserver(observer)
        }
        self.canvasObserver = nil

        self.selectedCanvasObserver?.cancel()
        self.selectedCanvasObserver = nil
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

        let items = self.canvasCollection.all
            .sorted { $0.sortIndex < $1.sortIndex }
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


    //MARK: Modifying Canvases
    func addPage(with id: ModelID, toCanvasAtIndex index: Int) {
        guard let page = self.documentWindowViewModel.pageCollection.objectWithID(id) else {
            return
        }
        let canvas = self.canvases[index]
        var centrePoint = CGPoint.zero
        if let viewPort = canvas.viewPort {
            centrePoint = CGPoint(x: viewPort.midX, y: viewPort.midY)
        }
        self.documentWindowViewModel.addPages([page], to: canvas, centredOn: centrePoint)
    }

    func addPages(fromFilesAtURLs fileURLs: [URL], toCanvasAtIndex canvasIndex: Int?) -> [Page] {
        var canvas: Canvas?
        if let index = canvasIndex {
            canvas = self.canvases[index]
        }

        return self.documentWindowViewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: canvas)
    }

    func moveCanvas(with id: ModelID, aboveCanvasAtIndex index: Int) {
        guard id.modelType == Canvas.modelType else {
            return
        }

        var canvases: [Canvas?] = self.canvases
        guard let currentIndex = canvases.firstIndex(where: { $0?.id == id}) else {
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
