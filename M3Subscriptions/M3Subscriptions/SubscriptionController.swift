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
    func showDevicesToDeactivate(_ devices: [SubscriptionDevice], for controller: SubscriptionController)
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
    private(set) var lastCheck: Date?

    #if TEST
    func setLastCheck(_ date: Date) {
        self.lastCheck = date
    }
    #endif

    public func activate(withEmail email: String, password: String, subscription: SubscriptionPlan? = nil, deactivatingDevice: SubscriptionDevice? = nil) {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.mcubedsw.unknown"
        let request = ActivationRequest(email: email,
                                        password: password,
                                        bundleID: bundleID,
                                        subscriptionID: subscription?.id,
                                        deviceDeactivationToken: deactivatingDevice?.deactivationToken)
        let device = Device(name: Host.current().localizedName)
        self.subscriptionAPI.activate(request, device: device) { (result) in
            switch result {
            case .success(let response):
                self.complete(with: response)
            case .failure(let failure):
                switch failure {
                case .multipleSubscriptions(let plans):
                    self.uiDelegate?.showSubscriptionPlans(plans, for: self)
                case .tooManyDevices(let devices):
                    self.uiDelegate?.showDevicesToDeactivate(devices, for: self)
                default:
                    let error = SubscriptionErrorFactory.error(for: failure)
                    self.delegate?.didEncounterError(error, in: self)
                }
            }
        }
        //Set next timer
    }

    public func checkSubscription(updatingDeviceName deviceName: String? = nil) {
        guard
            let response = ActivationResponse(url: self.licenceURL),
            let token = response.token
        else {
            self.delegate?.didEncounterError(SubscriptionErrorFactory.notActivatedError(), in: self)
            return
        }

        self.subscriptionAPI.check(Device(name: deviceName), token: token) { (result) in
            switch result {
            case .success(let response):
                self.complete(with: response)
            case .failure(let failure):
                switch failure {
                case .generic(let error as NSError) where error.domain == NSURLErrorDomain:
                    self.attemptLocalValidation(with: response, dueTo: failure)
                default:
                    let error = SubscriptionErrorFactory.error(for: failure)
                    self.delegate?.didEncounterError(error, in: self)
                }
            }
        }
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
                self.recheckTimer?.invalidate()
                self.recheckTimer = nil
            case .failure(let failure):
                let error = SubscriptionErrorFactory.error(for: failure)
                self.delegate?.didEncounterError(error, in: self)
            }
        }
    }

    private func deleteLicence() {
        try? FileManager.default.removeItem(at: self.licenceURL)
    }

    private func attemptLocalValidation(with response: ActivationResponse, dueTo failure: CheckAPI.Failure) {
        guard let subscription =  response.subscription else {
            let error = SubscriptionErrorFactory.error(for: failure)
            self.delegate?.didEncounterError(error, in: self)
            return
        }

        guard subscription.expirationDate >= Date() else {
            let error = SubscriptionErrorFactory.error(for: CheckAPI.Failure.subscriptionExpired(subscription))
            self.delegate?.didEncounterError(error, in: self)
            return
        }

        self.complete(with: response, writeToFile: false)
    }

    private func complete(with response: ActivationResponse, writeToFile: Bool = true) {
        response.write(to: self.licenceURL)
        self.delegate?.didChangeSubscription(response, in: self)
        self.lastCheck = Date()
        self.recheckTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: false) { [weak self] _ in self?.recheckIfNeeded() }
    }

    private func recheckIfNeeded() {
        if let lastCheck = self.lastCheck, (Date().timeIntervalSince(lastCheck) > 86400) {
            self.checkSubscription()
        } else {
            self.recheckTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: false) { [weak self] _ in self?.recheckIfNeeded() }
        }
    }


}
