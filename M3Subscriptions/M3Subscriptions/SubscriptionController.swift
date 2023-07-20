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

    public func activate(withEmail email: String, password: String, subscription: Subscription? = nil, deactivatingDevice: SubscriptionDevice? = nil) async throws -> ActivationResponse {
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


        do {
            let response = try await self.subscriptionAPI.activate(request, device: device)
            response.write(to: self.licenceURL)
            return response
        } catch {
            throw SubscriptionErrorFactory.error(for: error)
        }
    }

    public func checkSubscription(updatingDeviceName deviceName: String? = nil) async throws -> ActivationResponse {
        guard
            let localResponse = ActivationResponse(url: self.licenceURL),
            let token = localResponse.token
        else {
            throw SubscriptionErrorFactory.notActivatedError()
        }

        do {
            var response = try await self.subscriptionAPI.check(Device(name: deviceName), token: token)
            response.previousSubscription = localResponse.subscription
            response.write(to: self.licenceURL)
            return response
        } catch {
            switch error {
            case CheckAPI.Failure.generic(let error as NSError) where (error.domain == NSURLErrorDomain) && (deviceName == nil):
                return try self.attemptLocalValidation(with: localResponse, dueTo: error)
            default:
                throw SubscriptionErrorFactory.error(for: error)
            }
        }
    }

    public func deactivate() async throws -> ActivationResponse {
        guard
            let response = ActivationResponse(url: self.licenceURL),
            let token = response.token
        else {
            return ActivationResponse.deactivated()
        }

        do {
            let response = try await self.subscriptionAPI.deactivate(Device(), token: token)
            self.deleteLicence()
            self.recheckTimer?.invalidate()
            self.recheckTimer = nil
            return response
        } catch {
            throw SubscriptionErrorFactory.error(for: error)
        }
    }

    public func deleteLicence() {
        try? FileManager.default.removeItem(at: self.licenceURL)
    }

    private func attemptLocalValidation(with response: ActivationResponse, dueTo failure: Error) throws -> ActivationResponse {
        guard response.subscription != nil else {
            throw SubscriptionErrorFactory.error(for: failure)
        }

        var modifiedResponse = response
        modifiedResponse.previousSubscription = modifiedResponse.subscription
        modifiedResponse.reevaluateSubscription()
        return modifiedResponse
    }
}
