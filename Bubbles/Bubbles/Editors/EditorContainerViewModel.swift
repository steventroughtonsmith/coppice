//
//  EditorContainerViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

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
    var selectedObjectObservation: NSKeyValueObservation?
    private func setupObservation() {
        self.selectedObjectObservation = self.documentWindowState.observe(\.selectedSidebarObjectIDString) { [weak self] (state, change) in
            guard let strongSelf = self else {
                return
            }

            guard let idString = state.selectedSidebarObjectIDString,
                let objectID = ModelID(string: idString) else
            {
                strongSelf.currentObject = nil
                return
            }

            strongSelf.currentObject = strongSelf.modelController.object(with: objectID)
        }
    }

    var currentObject: ModelObject? {
        didSet {
            self.view?.editorChanged()
        }
    }
}
