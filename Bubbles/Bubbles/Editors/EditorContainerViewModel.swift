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
    weak var view: EditorContainerView?

    override func setup() {
        self.setupObservation()
    }


    //MARK: - Observation
    var selectedObjectObservation: AnyCancellable?
    private func setupObservation() {
        self.selectedObjectObservation = self.documentWindowViewModel.$selectedSidebarObjectID
            .map({[weak self] (modelID) in
                guard let modelID = modelID else {
                    return nil
                }
                return self?.modelController.object(with: modelID)
            })
            .assign(to: \.currentObject, on: self)
    }

    var currentObject: ModelObject? {
        didSet {
            self.view?.editorChanged()
        }
    }
}
