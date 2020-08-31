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

        self.subscriptionController?.checkSubscription(completion: { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
            case .failure(let error):
                print("error: \(error)")
            }
        })
    }

    func activate(withEmail email: String, password: String, on window: NSWindow) {
        guard let controller = self.subscriptionController else {
            return
        }
        controller.activate(withEmail: email, password: password) { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
            case .failure(let error):
                window.presentError(error)
            }
        }
    }

    func deactivate(on window: NSWindow) {
        guard let controller = self.subscriptionController else {
            return
        }
        controller.deactivate { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
            case .failure(let error):
                window.presentError(error)
            }
        }
    }
}
