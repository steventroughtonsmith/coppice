//
//  CanvasesViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import Combine

protocol CanvasesView: class {
    func currentCanvasChanged()
}

class CanvasesViewModel: ViewModel {
    weak var view: CanvasesView?

    private var selectedCanvasObserver: AnyCancellable?
    func startObserving() {
        self.selectedCanvasObserver = self.documentWindowViewModel.$selectedCanvasID
            .map { [weak self] id -> Canvas? in
                if let modelID = id {
                    return self?.documentWindowViewModel.canvasCollection.objectWithID(modelID)
                }
                return nil
            }.assign(to: \.currentCanvas, on: self)
    }

    func stopObserving() {
        self.selectedCanvasObserver?.cancel()
        self.selectedCanvasObserver = nil
    }


    var currentCanvas: Canvas? {
        didSet {
            self.view?.currentCanvasChanged()
        }
    }
}
