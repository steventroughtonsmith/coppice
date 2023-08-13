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
    @objc dynamic var isTrialActive = false

    var trialDaysRemaining: Int = 0

    var activationObserver: AnyCancellable?
    private func setupProObservation() {
        self.subscribers[.subscriptionState] = CoppiceSubscriptionManager.shared.$state
            .sink { [weak self] newValue in
                self?.isProEnabled = (newValue == .enabled)
            }

        self.subscribers[.trialState] = CoppiceSubscriptionManager.shared.v2Controller.$trialState.sink { [weak self] newState in
            switch newState {
            case .available:
                self?.isTrialActive = false
            case .redeemed(let licence):
                self?.isTrialActive = licence.isActive
                let daysRemaining = Int((licence.subscription.expirationTimestamp - Date().timeIntervalSince1970) / 86400)
                self?.trialDaysRemaining = min(max(daysRemaining, 0), 30)
            }
        }
    }



    //MARK: - Subscribers
    private enum SubscriberKey {
        case subscriptionState
        case trialState
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]
}
