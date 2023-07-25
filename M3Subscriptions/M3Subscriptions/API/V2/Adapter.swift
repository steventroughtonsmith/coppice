//
//  APIAdapter.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 24/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

protocol APIAdapterV2 {
    func login(email: String, password: String, deviceName: String) async throws -> APIData

    func withAuthentication(authentication: API.V2.Authentication) -> APIAdapterV2

    func logout() async throws -> APIData

    func activate(device: Device, subscriptionID: String?) async throws -> APIData
    func check(activationID: String, device: Device) async throws -> APIData
    func deactivate(activationID: String) async throws -> APIData

    func renameDevice(activationID: String, deviceName: String) async throws -> APIData
    func listSubscriptions(bundleID: String) async throws -> APIData
}


extension API.V2 {
    class Adapter: APIAdapterV2 {
        let networkAdapter: NetworkAdapter
        init(networkAdapter: NetworkAdapter) {
            self.networkAdapter = networkAdapter
        }

        private var currentAuthentication: Authentication?
        func withAuthentication(authentication: API.V2.Authentication) -> APIAdapterV2 {
            self.currentAuthentication = authentication
            return self
        }

        func login(email: String, password: String, deviceName: String) async throws -> APIData {
            fatalError()
        }

        func logout() async throws -> APIData {
            fatalError()
        }

        func activate(device: Device, subscriptionID: String?) async throws -> APIData {
            fatalError()
        }

        func check(activationID: String, device: Device) async throws -> APIData {
            fatalError()
        }

        func deactivate(activationID: String) async throws -> APIData {
            fatalError()
        }

        func renameDevice(activationID: String, deviceName: String) async throws -> APIData {
            fatalError()
        }

        func listSubscriptions(bundleID: String) async throws -> APIData {
            fatalError()
        }
    }
}
