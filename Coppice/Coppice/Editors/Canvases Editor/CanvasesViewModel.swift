//
//  CanvasesViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import Combine
import CoppiceCore

protocol CanvasesView: class {
    func currentCanvasChanged()
    func canvasListStateChanged()
}

class CanvasesViewModel: ViewModel {
    weak var view: CanvasesView?

    private var selectedCanvasObserver: AnyCancellable?
    private var searchStringObserver: AnyCancellable?
    func startObserving() {
        self.selectedCanvasObserver = self.documentWindowViewModel.$selectedCanvasID
            .map { [weak self] id -> Canvas? in
                if let modelID = id {
                    return self?.modelController.canvasCollection.objectWithID(modelID)
                }
                return nil
            }.assign(to: \.currentCanvas, on: self)

        self.searchStringObserver = self.documentWindowViewModel.publisher(for: \.searchString).sink { [weak self] _ in
            self?.view?.canvasListStateChanged()
        }
    }

    func stopObserving() {
        self.selectedCanvasObserver?.cancel()
        self.selectedCanvasObserver = nil

        self.searchStringObserver?.cancel()
        self.searchStringObserver = nil
    }

    var showCanvasList: Bool {
        return self.documentWindowViewModel.searchString == nil
    }


    var currentCanvas: Canvas? {
        didSet {
            self.view?.currentCanvasChanged()
        }
    }
}
