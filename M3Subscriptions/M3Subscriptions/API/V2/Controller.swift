//
//  Controller.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V2 {
    public class Controller {
        let licenceURL: URL
        let activationURL: URL
        let trialLicenceURL: URL
        private let adapter: APIAdapterV2
        private let keychain: Keychain
        public convenience init(licenceURL: URL, activationURL: URL, trialLicenceURL: URL) {
            let networkAdapter = URLSessionNetworkAdapter()
            networkAdapter.activeVersion = .v2
            let adapter = Adapter(networkAdapter: networkAdapter)
            self.init(licenceURL: licenceURL, activationURL: activationURL, trialLicenceURL: trialLicenceURL, adapter: adapter, keychain: DefaultKeychain())
        }

        init(licenceURL: URL, activationURL: URL, trialLicenceURL: URL, adapter: APIAdapterV2, keychain: Keychain) {
            self.licenceURL = licenceURL
            self.activationURL = activationURL
            self.trialLicenceURL = trialLicenceURL
            self.adapter = adapter
            self.keychain = keychain

            self.checkForLocalActivation()
        }

        //MARK: - State
        @Published public private(set) var trialState: TrialState = .available
        @Published public private(set) var activationSource: ActivationSource = .none
        @Published public private(set) var authenticationType: AuthenticationType?

#if DEBUG
        func setActivationSource(_ source: ActivationSource) {
            self.activationSource = source
        }
#endif

        private func checkForLocalActivation() {
            let licence = try? Licence(url: self.licenceURL)
            let trialLicence = try? Licence(url: self.trialLicenceURL)
            let activation = try? Activation(url: self.activationURL)

            if let trialLicence {
                self.trialState = .redeemed(trialLicence)
            } else {
                self.trialState = .available
            }

            if (try? self.keychain.fetchToken()) != nil {
                self.authenticationType = .token
            } else {
                self.authenticationType = .licence
            }

            if let activation {
                self.activationSource = .website(activation)
            } else if let activationLicence = (licence ?? trialLicence) {
                self.activationSource = .licence(activationLicence)
            } else {
                self.activationSource = .none
            }
        }

        //MARK: - Authentication

        /// Login to the API using an M Cubed Account ``logout()``
        /// - Parameters:
        ///   - email: The email to login with
        ///   - password: The password for the account
        public func login(email: String, password: String) async throws {
            let apiData = try await self.adapter
                .expecting(.loggedIn)
                .login(email: email, password: password, deviceName: Device.shared.defaultName)

            guard let token = apiData.payload["token"] as? String else {
                throw Error.loginFailed
            }

            do {
                try self.keychain.addToken(token)
            } catch KeychainError.unhandledError(-50) {
                //A -50 error is usually caused by the token still being in the keychain, so try clearing it out first
                try self.keychain.removeToken()
                try self.keychain.addToken(token)
            } catch {
                throw error
            }
        }

        /// Logs out the user, deleting from the keychain
        public func logout() async throws {
            _ = try await self.adapter
                .withAuthentication(try self.authenticationType(from: [.token]))
                .expecting(.loggedOut)
                .logout()

            try self.keychain.removeToken()
            self.authenticationType = .none
        }

        /// Save licence to disk
        /// - Parameter licence: The licence to save
        public func saveLicence(_ licence: Licence, isTrial: Bool = false) throws {
            try licence.write(to: isTrial ? self.trialLicenceURL : self.licenceURL)
            self.activationSource = .licence(licence)
        }


        //MARK: - Activation
        /// Attemps to activate the current device
        /// - Parameter subscriptionID: The specific subscription to activate
        public func activate(subscriptionID: String? = nil) async throws {
            let apiData = try await self.adapter
                .withAuthentication(try self.authenticationType())
                .expecting(.active)
                .allowedFailures([.noSubscriptionFound, .expired, .tooManyDevices, .invalidLicence])
                .activate(device: .shared, subscriptionID: subscriptionID)

            let activation = try Activation(apiData: apiData)
            try activation.write(to: self.activationURL)

            self.activationSource = .website(activation)
        }

        /// Check the current activation status
        public func check() async throws {
            guard case .website(let activation) = self.activationSource else {
                throw Error.notActivated
            }

            let apiData = try await self.adapter
                .withAuthentication(try self.authenticationType())
                .expecting(.active)
                .allowedFailures([.invalidLicence, .noDeviceFound, .noSubscriptionFound, .expired])
                .check(activationID: activation.activationID, device: .shared)

            let newActivation = try Activation(apiData: apiData)
            try newActivation.write(to: self.activationURL)
            self.activationSource = .website(newActivation)
        }

        /// Return a list of subscriptions for the currently authenticated user for this app
        /// - Returns: A list of active subscriptions
        public func listSubscriptions() async throws -> [Subscription] {
            guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
                throw Error.invalidResponse
            }

            let apiData = try await self.adapter
                .withAuthentication(try self.authenticationType(from: [.token]))
                .expecting(.success)
                .listSubscriptions(bundleID: bundleIdentifier, deviceType: Device.shared.type)

            guard let apiSubscriptions = apiData.payload["subscriptions"] as? [[String: Any]] else {
                throw Error.invalidResponse
            }

            return try apiSubscriptions.map { try Subscription(apiSubscription: $0) }
        }

        /// Return the list of activated devices for the supplied subscription
        ///
        /// **Note:** If the activation source is not a user account, device names will not be included
        /// - Parameter subscriptionID: The ID of the subscription to fetch the devices for
        /// - Returns: A list of activated devices
        public func listDevices(subscriptionID: String) async throws -> (maxDeviceCount: Int, devices: [ActivatedDevice]) {
            let apiData = try await self.adapter
                .withAuthentication(try self.authenticationType())
                .expecting(.success)
                .allowedFailures([.invalidLicence, .noSubscriptionFound])
                .listDevices(subscriptionID: subscriptionID, device: .shared)

            guard
                let apiDevices = apiData.payload["devices"] as? [[String: Any]],
                let maxDeviceCount = apiData.payload["maxDeviceCount"] as? Int
            else {
                throw Error.invalidResponse
            }

            let activatedDevices = try apiDevices.map { try ActivatedDevice(apiDevice: $0) }
            return (maxDeviceCount, activatedDevices)
        }

        /// Rename the currently activated device with the service
        /// - Parameter name: The new name of the device
        public func renameDevice(to name: String) async throws {
            guard case .website(let activation) = self.activationSource else {
                throw Error.notActivated
            }

            guard name != activation.deviceName else {
                return
            }

            let apiData = try await self.adapter
                .withAuthentication(try self.authenticationType(from: [.token]))
                .expecting(.active)
                .allowedFailures([.noDeviceFound, .noSubscriptionFound, .expired])
                .renameDevice(activationID: activation.activationID, deviceName: name)

            let newActivation = try Activation(apiData: apiData)
            if let trialLicence = try? Licence(url: self.trialLicenceURL),
               trialLicence.isActive == false,
               newActivation.subscription.id == trialLicence.subscription.id
            {
                try? self.cleanUpDeactivation()
                return
            }

            try newActivation.write(to: self.activationURL)
            self.activationSource = .website(newActivation)
        }

        /// Deactivate a device, removing any local activation files
        /// - Parameter activationID: The activation ID of the device to deactivate, or nil to deactivate the current device
        public func deactivate(activationID: String? = nil) async throws {
            var idToDeactivate = activationID
            if idToDeactivate == nil {
                switch self.activationSource {
                case .none:
                    throw Error.notActivated
                case .licence:
                    try self.cleanUpDeactivation()
                    return
                case .website(let activation):
                    idToDeactivate = activation.activationID
                }
            }

            _ = try await self.adapter
                .withAuthentication(try self.authenticationType())
                .expecting(.deactivated)
                .allowedFailures([.noDeviceFound, .noSubscriptionFound])
                .deactivate(activationID: idToDeactivate!)

            try self.cleanUpDeactivation()
        }

        private func cleanUpDeactivation() throws {
            if FileManager.default.fileExists(atPath: self.licenceURL.path) {
                try FileManager.default.removeItem(at: self.licenceURL)
            }
            if FileManager.default.fileExists(atPath: self.activationURL.path) {
                try FileManager.default.removeItem(at: self.activationURL)
            }
            self.activationSource = .none
        }

        private func authenticationType(from allowedTypes: [AuthenticationType] = [.token, .licence]) throws -> API.V2.Authentication {
            if allowedTypes.contains(.token),
               let token = try? self.keychain.fetchToken() {
                return .token(token)
            }
            if allowedTypes.contains(.licence) {
                if FileManager.default.fileExists(atPath: self.licenceURL.path) {
                    return .licence(try Licence(url: self.licenceURL))
                } else if FileManager.default.fileExists(atPath: self.trialLicenceURL.path) {
                    return .licence(try Licence(url: self.trialLicenceURL))
                }
            }
            throw Error.invalidAuthenticationMethod
        }

        //MARK: - Trial
        public func startTrial() async throws -> Licence {
            guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
                throw Error.invalidResponse
            }

            let apiData = try await self.adapter
                .expecting(.success)
                .allowedFailures([.noTrialAvailable, .trialUsed])
                .startTrial(bundleID: bundleIdentifier, device: Device.shared)

            guard let rawLicence = apiData.payload["licence"] as? [String: Any] else {
                throw Error.invalidLicence
            }

            let licence = try Licence(json: rawLicence)
            self.trialState = .redeemed(licence)
            return licence
        }
    }
}

extension API.V2.Controller {
    public enum ActivationSource {
        case none
        case licence(API.V2.Licence)
        case website(API.V2.Activation)
    }

    public enum AuthenticationType {
        case token
        case licence
    }

    public enum TrialState {
        case available
        case redeemed(API.V2.Licence)
    }
}

extension API.V2.Controller.ActivationSource {
    public var isActivated: Bool {
        switch self {
        case .none:
            return false
        case .licence, .website:
            return true
        }
    }

    public var isValid: Bool {
        switch self {
        case .none:
            return false
        case .licence(let licence):
            let currentTimestamp = Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate
            return licence.subscription.expirationTimestamp >= currentTimestamp
        case .website(let activation):
            let currentTimestamp = Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate
            return activation.subscription.expirationTimestamp >= currentTimestamp
        }
    }
}
