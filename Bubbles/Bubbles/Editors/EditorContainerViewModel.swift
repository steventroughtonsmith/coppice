//
//  EditorContainerViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

protocol EditorContainerView: class {
    func editorChanged()
}

class EditorContainerViewModel: ViewModel {
    enum Selection {
        case none
        case canvas(Canvas)
        case page(Page)
        case multiple([Page])
    }
    weak var view: EditorContainerView?

    override func setup() {
        self.setupObservation()
    }


    //MARK: - Observation
    var selectedObjectObservation: AnyCancellable?
    private func setupObservation() {
        self.selectedObjectObservation = self.documentWindowViewModel.$selectedSidebarObjectIDs
            .map({[weak self] (modelIDs) in
                guard let strongSelf = self else {
                    return .none
                }
                return strongSelf.selection(fromIDs: modelIDs)
            })
            .assign(to: \.currentSelection, on: self)
    }

    var currentSelection: Selection = .none {
        didSet {
            self.view?.editorChanged()
        }
    }

    private func selection(fromIDs modelIDs: Set<ModelID>) -> Selection {
        if modelIDs.count > 1 {
            let pages = modelIDs.compactMap { self.documentWindowViewModel.pageCollection.objectWithID($0) }
            return .multiple(pages)
        }

        if let modelID = modelIDs.first {
            if modelID.modelType == Canvas.modelType, let canvas = self.documentWindowViewModel.canvasCollection.objectWithID(modelID) {
                return .canvas(canvas)
            }
            else if modelID.modelType == Page.modelType, let page = self.documentWindowViewModel.pageCollection.objectWithID(modelID) {
                return .page(page)
            }
        }
        return .none
    }
}
