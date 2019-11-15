//
//  InspectorContainerViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 11/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation
import Combine


protocol InspectorContainerView: class {
}


class InspectorContainerViewModel {
    weak var view: InspectorContainerView?

    let modelController: ModelController
    let documentWindowState: DocumentWindowState
    init(modelController: ModelController, documentWindowState: DocumentWindowState) {
        self.modelController = modelController
        self.documentWindowState = documentWindowState

        self.setupObservers()
    }

    private var inspectorObserver: AnyCancellable?
    private func setupObservers() {
        self.inspectorObserver = self.documentWindowState.$currentInspectors.sink { [weak self] (inspectors) in
            self?.inspectors = inspectors
        }
    }

    @Published var inspectors: [Inspector] = []
}
