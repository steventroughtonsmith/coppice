//
//  SubscriptionController.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public protocol SubscriptionControllerDelegate: class {
    func didChangeSubscription(_ info: ActivationResponse, in controller: SubscriptionController)
    func didEncounterError(_ error: NSError, in controller: SubscriptionController)
}

public protocol SubscriptionControllerUIDelegate: class {
    func showSubscriptionPlans(_ plans: [SubscriptionPlan], for controller: SubscriptionController)
    func showDevicesToDeactivate(_ device: [SubscriptionDevice], for controller: SubscriptionController)
}

public class SubscriptionController {
    public weak var delegate: SubscriptionControllerDelegate?
    public weak var uiDelegate: SubscriptionControllerUIDelegate?

    public convenience init(licenceURL: URL) {
        self.init(licenceURL: licenceURL, subscriptionAPI: OnlineSubscriptionAPI(networkAdapter: URLSessionNetworkAdapter()))
    }

    let licenceURL: URL
    let subscriptionAPI: SubscriptionAPI
    init(licenceURL: URL, subscriptionAPI: SubscriptionAPI) {
        self.licenceURL = licenceURL
        self.subscriptionAPI = subscriptionAPI
    }

    private(set) var recheckTimer: Timer? 

    public func activate(withEmail email: String, password: String, subscription: SubscriptionPlan? = nil, deactivatingDevice: SubscriptionDevice? = nil) {
        //Call to server
        //If failure then return error/show plans/show devices
        //If success then didChange subscription
        //Store to disk
        //Set next timer
    }

    public func checkSubscription(updatingDeviceName deviceName: String? = nil) {
        //Call to server
        //If call to server failed
            //Load from disk
            //Verify
            //Call did change subscription or failure
        //If failure then return error
        //If success then did change subscription
        //Store to disk
        //Set next timer
    }

    public func deactivate() {
        guard
            let response = ActivationResponse(url: self.licenceURL),
            let token = response.token
        else {
            guard let deactivated = ActivationResponse.deactivated() else {
                let error = SubscriptionErrorFactory.error(for: DeactivateAPI.Failure.generic(nil))
                self.delegate?.didEncounterError(error, in: self)
                return
            }
            self.delegate?.didChangeSubscription(deactivated, in: self)
            return
        }

        self.subscriptionAPI.deactivate(Device(), token: token) { (result) in
            switch result {
            case .success(let response):
                self.deleteLicence()
                self.delegate?.didChangeSubscription(response, in: self)
            case .failure(let failure):
                let error = SubscriptionErrorFactory.error(for: failure)
                self.delegate?.didEncounterError(error, in: self)
            }
        }
    }

    private func deleteLicence() {
        try? FileManager.default.removeItem(at: self.licenceURL)
    }


}
