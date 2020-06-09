//
//  SubscriptionController.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public protocol SubscriptionControllerDelegate: class {
    func didChangeSubscription(_ info: SubscriptionInfo, in controller: SubscriptionController)
    func didEncounterError(_ error: Error, in controller: SubscriptionController)
}

public protocol SubscriptionControllerUIDelegate: class {
    func showSubscriptionPlans(_ plans: [SubscriptionPlan], for controller: SubscriptionController)
    func showDevicesToDeactivate(_ device: [SubscriptionDevice], for controller: SubscriptionController)
}

public class SubscriptionController {
    public weak var delegate: SubscriptionControllerDelegate?
    public weak var uiDelegate: SubscriptionControllerUIDelegate?

    public convenience init() {
        self.init(subscriptionAPI: OnlineSubscriptionAPI(networkAdapter: URLSessionNetworkAdapter()))
    }

    let subscriptionAPI: SubscriptionAPI
    init(subscriptionAPI: SubscriptionAPI) {
        self.subscriptionAPI = subscriptionAPI
    }

    public func activate(withEmail email: String, password: String, subscription: SubscriptionPlan? = nil, deactivatingDevice: SubscriptionDevice? = nil) {

    }

    public func checkSubscription(updatingDeviceName deviceName: String? = nil) {

    }

    public func deactivate() {

    }
}
