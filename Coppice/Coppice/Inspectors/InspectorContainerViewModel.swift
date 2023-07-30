//
//  InspectorContainerViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 11/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
import Foundation


protocol InspectorContainerView: AnyObject {}


class InspectorContainerViewModel: ViewModel {
    weak var view: InspectorContainerView?

    override func setup() {
        self.setupObservers()
    }

    private var inspectorObserver: AnyCancellable?
    private func setupObservers() {
        self.inspectorObserver = self.documentWindowViewModel.$currentInspectors.sink { [weak self] (inspectors) in
            self?.inspectors = inspectors.sorted { $0.ranking.rawValue < $1.ranking.rawValue }
        }
        self.setupProObservation()
    }

    @Published var inspectors: [Inspector] = []

    //MARK: - Pro
    @objc dynamic var isProEnabled = false

    var activationObserver: AnyCancellable?
    private func setupProObservation() {
        self.activationObserver = CoppiceSubscriptionManager.shared.$state
            .sink { [weak self] newValue in
                self?.isProEnabled = (newValue == .enabled)
            }
    }
}
