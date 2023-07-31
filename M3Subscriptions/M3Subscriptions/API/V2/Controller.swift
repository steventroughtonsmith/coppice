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
        public enum ActivationSource {
            case none
            case licence(Licence)
            case website(Activation)
        }

        public private(set) var activationSource: ActivationSource = .none

        #if DEBUG
        func setActivationSource(_ source: ActivationSource) {
            self.activationSource = source
        }
        #endif

        let licenceURL: URL
        let activationURL: URL
        private let adapter: APIAdapterV2
        private let keychain: Keychain
        public convenience init(licenceURL: URL, activationURL: URL) {
            let networkAdapter = URLSessionNetworkAdapter()
            networkAdapter.activeVersion = .v2
            let adapter = Adapter(networkAdapter: networkAdapter)
            self.init(licenceURL: licenceURL, activationURL: activationURL, adapter: adapter, keychain: DefaultKeychain())
        }

        init(licenceURL: URL, activationURL: URL, adapter: APIAdapterV2, keychain: Keychain) {
            self.licenceURL = licenceURL
            self.activationURL = activationURL
            self.adapter = adapter
            self.keychain = keychain

            do {
                let data = try Data(contentsOf: self.activationURL)

                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let apiData = APIData(json: json) {
                    let activation = try Activation(apiData: apiData)
                    self.activationSource = .website(activation)
                    return
                }
            } catch {
//                print("No valid local activation")
            }

            do {
                let licence = try Licence(url: self.licenceURL)
                self.activationSource = .licence(licence)
                return
            } catch {
//                print("No valid licence")
            }
            self.activationSource = .none
        }

        //MARK: - Authentication

        /// Login to the API using an M Cubed Account ``logout()``
        /// - Parameters:
        ///   - email: The email to login with
        ///   - password: The password for the account
        public func login(email: String, password: String) async throws {
            let apiData = try await self.adapter.login(email: email, password: password, deviceName: Device.shared.defaultName)

            guard
                apiData.response == .loggedIn,
                let token = apiData.payload["token"] as? String
            else {
                throw Error.loginFailed
            }

            try self.keychain.addToken(token)
        }

        /// Logs out the user, deleting from the keychain
        public func logout() async throws {
            let apiData = try await self.adapter.logout()
            guard apiData.response == .loggedOut else {
                throw Error.invalidResponse
            }
            try self.keychain.removeToken()
        }

        /// Save licence to disk
        /// - Parameter licence: The licence to save
        public func saveLicence(_ licence: Licence) throws {
            try licence.write(to: self.licenceURL)
            self.activationSource = .licence(licence)
        }


        //MARK: - Activation
        /// Attemps to activate the current device
        /// - Parameter subscriptionID: The specific subscription to activate
        public func activate(subscriptionID: String? = nil) async throws {
            let apiData = try await self.adapter
                .withAuthentication(try self.authenticationType())
                .activate(device: .shared, subscriptionID: subscriptionID)

            guard apiData.response == .active else {
                throw Error.notActivated
            }

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
                .check(activationID: activation.activationID, device: .shared)

            guard apiData.response == .active else {
                throw Error.notActivated
            }

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
                .listSubscriptions(bundleID: bundleIdentifier)

            guard
                apiData.response == .success,
                let apiSubscriptions = apiData.payload["subscriptions"] as? [[String: Any]]
            else {
                throw Error.invalidResponse
            }

            return try apiSubscriptions.map { try Subscription(apiSubscription: $0) }
        }

        /// Return the list of activated devices for the supplied subscription
        ///
        /// **Note:** If the activation source is not a user account, device names will not be included
        /// - Parameter subscriptionID: The ID of the subscription to fetch the devices for
        /// - Returns: A list of activated devices
        public func listDevices(subscriptionID: String) async throws -> [ActivatedDevice] {
            let apiData = try await self.adapter
                .withAuthentication(try self.authenticationType())
                .listDevices(subscriptionID: subscriptionID, device: .shared)

            guard
                apiData.response == .success,
                let apiDevices = apiData.payload["devices"] as? [[String: Any]]
            else {
                throw Error.invalidResponse
            }

            return try apiDevices.map { try ActivatedDevice(apiDevice: $0) }
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
                .renameDevice(activationID: activation.activationID, deviceName: name)

            guard apiData.response == .active else {
                throw Error.notActivated
            }

            let newActivation = try Activation(apiData: apiData)
            try newActivation.write(to: self.activationURL)
            self.activationSource = .website(newActivation)
        }

        /// Deactivate a device, removing any local activation files
        /// - Parameter activationID: The activation ID of the device to deactivate, or nil to deactivate the current device
        public func deactivate(activationID: String? = nil) async throws {
            var idToDeactivate = activationID
            if idToDeactivate == nil {
                guard case .website(let activation) = self.activationSource else {
                    throw Error.notActivated
                }
                idToDeactivate = activation.activationID
            }
            let apiData = try await self.adapter
                .withAuthentication(try self.authenticationType())
                .deactivate(activationID: idToDeactivate!)

            guard apiData.response == .deactivated else {
                throw Error.invalidResponse
            }

            if FileManager.default.fileExists(atPath: self.licenceURL.path) {
                try FileManager.default.removeItem(at: self.licenceURL)
            }
            if FileManager.default.fileExists(atPath: self.activationURL.path) {
                try FileManager.default.removeItem(at: self.activationURL)
            }
            self.activationSource = .none
        }

        enum AuthenticationType {
            case token
            case licence
        }

        private func authenticationType(from allowedTypes: [AuthenticationType] = [.token, .licence]) throws -> API.V2.Authentication {
            if allowedTypes.contains(.token),
               let token = try? self.keychain.fetchToken() {
                return .token(token)
            }
            if allowedTypes.contains(.licence) {
                let licence = try Licence(url: self.licenceURL)
                return .licence(licence)
            }
            throw Error.invalidAuthenticationMethod
        }
    }
}

extension API.V2.Controller.ActivationSource {
    public var activated: Bool {
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
