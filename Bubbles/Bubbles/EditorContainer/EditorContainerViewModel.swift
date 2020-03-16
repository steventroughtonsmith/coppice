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

    var currentEditor: DocumentWindowViewModel.Editor = .none {
        didSet {
            guard currentEditor != oldValue else {
                return
            }
            self.view?.editorChanged()
        }
    }


    //MARK: - Observation
    var selectedObjectObservation: AnyCancellable?
    private func setupObservation() {
        self.selectedObjectObservation = self.documentWindowViewModel.$currentEditor.assign(to: \.currentEditor, on: self)
    }
}
