//
//  CoppiceSubscriptionManager.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Subscriptions
import Combine

class CoppiceSubscriptionManager: NSObject {
    let subscriptionController: SubscriptionController?

    @Published var activationResponse: ActivationResponse?

    override init() {
        if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let licenceURL = appSupportURL.appendingPathComponent("licence")
            self.subscriptionController = SubscriptionController(licenceURL: licenceURL)
        } else {
            self.subscriptionController = nil
        }

        super.init()
        self.subscriptionController?.delegate = self

        self.subscriptionController?.checkSubscription()
    }
}

extension CoppiceSubscriptionManager: SubscriptionControllerDelegate {
    func didChangeSubscription(_ info: ActivationResponse, in controller: SubscriptionController) {
        self.activationResponse = info
        print("info: \(info)")
    }

    func didEncounterError(_ error: NSError, in controller: SubscriptionController) {
        print("error: \(error)")
    }
}
