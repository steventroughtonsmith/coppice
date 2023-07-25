//
//  SubscriptionController.V1.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 24/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V1 {
    public class SubscriptionController {
        public convenience init(activationDetailsURL: URL) {
            self.init(activationDetailsURL: activationDetailsURL, subscriptionAPI: Activations(networkAdapter: URLSessionNetworkAdapter()))
        }

        let activationDetailsURL: URL
        let subscriptionAPI: SubscriptionAPIV1
        init(activationDetailsURL: URL, subscriptionAPI: SubscriptionAPIV1) {
            self.activationDetailsURL = activationDetailsURL
            self.subscriptionAPI = subscriptionAPI
        }

        //MARK: - Version 1
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
                response.write(to: self.activationDetailsURL)
                return response
            } catch {
                throw SubscriptionErrorFactory.error(for: error)
            }
        }

        public func checkSubscription(updatingDeviceName deviceName: String? = nil) async throws -> ActivationResponse {
            guard
                let localResponse = ActivationResponse(url: self.activationDetailsURL),
                let token = localResponse.token
            else {
                throw SubscriptionErrorFactory.notActivatedError()
            }

            do {
                var response = try await self.subscriptionAPI.check(Device(name: deviceName), token: token)
                response.previousSubscription = localResponse.subscription
                response.write(to: self.activationDetailsURL)
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
                let response = ActivationResponse(url: self.activationDetailsURL),
                let token = response.token
            else {
                return ActivationResponse.deactivated()
            }

            do {
                let response = try await self.subscriptionAPI.deactivate(Device(), token: token)
                self.deleteActivation()
                return response
            } catch {
                throw SubscriptionErrorFactory.error(for: error)
            }
        }

        public func deleteActivation() {
            try? FileManager.default.removeItem(at: self.activationDetailsURL)
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
}
