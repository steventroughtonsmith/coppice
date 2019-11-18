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

class EditorContainerViewModel: NSObject {
    weak var view: EditorContainerView?

    let modelController: ModelController
    let documentWindowState: DocumentWindowState
    init(modelController: ModelController, documentWindowState: DocumentWindowState) {
        self.modelController = modelController
        self.documentWindowState = documentWindowState
        super.init()

        self.setupObservation()
    }


    //MARK: - Observation
    var selectedObjectObservation: AnyCancellable?
    private func setupObservation() {
        self.selectedObjectObservation = self.documentWindowState.$selectedSidebarObjectID
            .receive(on: RunLoop.main)
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
