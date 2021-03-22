//
//  SubscriptionController.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public class SubscriptionController {
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

    public typealias SubscriptionCompletion = (Result<ActivationResponse, NSError>) -> Void
    public func activate(withEmail email: String, password: String, subscription: Subscription? = nil, deactivatingDevice: SubscriptionDevice? = nil, completion: @escaping SubscriptionCompletion) {
        #if TEST
        let bundleID = TEST_OVERRIDES.bundleID ?? Bundle.main.bundleIdentifier ?? "com.mcubedsw.unknown"
        #else
        let bundleID = Bundle.main.bundleIdentifier ?? "com.mcubedsw.unknown"
        #endif
        let request = ActivationRequest(email: email,
                                        password: password,
                                        bundleID: bundleID,
                                        subscriptionID: subscription?.id,
                                        deviceDeactivationToken: deactivatingDevice?.deactivationToken)
        let device = Device(name: Host.current().localizedName)
        self.subscriptionAPI.activate(request, device: device) { (result) in
            switch result {
            case .success(let response):
                self.complete(with: response, completion: completion)
            case .failure(let failure):
                let error = SubscriptionErrorFactory.error(for: failure)
                completion(.failure(error))
            }
        }
    }

    public func checkSubscription(updatingDeviceName deviceName: String? = nil, completion:  @escaping SubscriptionCompletion) {
        guard
            let localResponse = ActivationResponse(url: self.licenceURL),
            let token = localResponse.token
        else {
            completion(.failure(SubscriptionErrorFactory.notActivatedError()))
            return
        }

        self.subscriptionAPI.check(Device(name: deviceName), token: token) { (result) in
            switch result {
            case .success(var response):
                response.previousSubscription = localResponse.subscription
                self.complete(with: response, completion: completion)
            case .failure(let failure):
                switch failure {
                case .generic(let error as NSError) where (error.domain == NSURLErrorDomain) && (deviceName == nil):
                    self.attemptLocalValidation(with: localResponse, dueTo: failure, completion: completion)
                default:
                    let error = SubscriptionErrorFactory.error(for: failure)
                    completion(.failure(error))
                }
            }
        }
        //Set next timer
    }

    public func deactivate(completion: @escaping SubscriptionCompletion) {
        guard
            let response = ActivationResponse(url: self.licenceURL),
            let token = response.token
        else {
            completion(.success(ActivationResponse.deactivated()))
            return
        }

        self.subscriptionAPI.deactivate(Device(), token: token) { (result) in
            switch result {
            case .success(let response):
                self.deleteLicence()
                completion(.success(response))
                self.recheckTimer?.invalidate()
                self.recheckTimer = nil
            case .failure(let failure):
                let error = SubscriptionErrorFactory.error(for: failure)
                completion(.failure(error))
            }
        }
    }

    public func deleteLicence() {
        try? FileManager.default.removeItem(at: self.licenceURL)
    }

    private func attemptLocalValidation(with response: ActivationResponse, dueTo failure: CheckAPI.Failure, completion: SubscriptionCompletion) {
        guard response.subscription != nil else {
            let error = SubscriptionErrorFactory.error(for: failure)
            completion(.failure(error))
            return
        }

        var modifiedResponse = response
        modifiedResponse.previousSubscription = modifiedResponse.subscription
        modifiedResponse.reevaluateSubscription()
        self.complete(with: modifiedResponse, writeToFile: false, completion: completion)
    }

    private func complete(with response: ActivationResponse, writeToFile: Bool = true, completion: SubscriptionCompletion) {
        response.write(to: self.licenceURL)
        completion(.success(response))
    }
}
