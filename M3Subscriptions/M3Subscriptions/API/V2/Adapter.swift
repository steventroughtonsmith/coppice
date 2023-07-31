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

    func withAuthentication(_ authentication: API.V2.Authentication) -> APIAdapterV2

    func logout() async throws -> APIData

    func activate(device: Device, subscriptionID: String?) async throws -> APIData
    func check(activationID: String, device: Device) async throws -> APIData
    func deactivate(activationID: String) async throws -> APIData

    func renameDevice(activationID: String, deviceName: String) async throws -> APIData
    func listSubscriptions(bundleID: String) async throws -> APIData
    func listDevices(subscriptionID: String, device: Device) async throws -> APIData
}


extension API.V2 {
    class Adapter: APIAdapterV2 {
        let networkAdapter: NetworkAdapter
        init(networkAdapter: NetworkAdapter) {
            self.networkAdapter = networkAdapter
        }

        private var currentAuthentication: Authentication?
        func withAuthentication(_ authentication: API.V2.Authentication) -> APIAdapterV2 {
            self.currentAuthentication = authentication
            return self
        }

        func login(email: String, password: String, deviceName: String) async throws -> APIData {
            return try await self.networkAdapter.callAPI(endpoint: "login", method: "POST", body: [
                "email": email,
                "password": password,
                "deviceName": deviceName,
            ], headers: nil)
        }

        func logout() async throws -> APIData {
            return try await self.networkAdapter.callAPI(endpoint: "logout", method: "POST", body: [:], headers: nil)
        }

        func activate(device: Device, subscriptionID: String?) async throws -> APIData {
            var body: [String: String] = [
                "version": device.appVersion,
                "deviceID": device.id,
                "deviceName": device.name ?? device.defaultName,
                "deviceType": device.type.rawValue,
            ]

            if let subscriptionID {
                body["subscriptionID"] = subscriptionID
            }
            return try await self.authenticatedAPICall(endpoint: "activate", method: "POST", body: body)
        }

        func check(activationID: String, device: Device) async throws -> APIData {
            return try await self.authenticatedAPICall(endpoint: "check", method: "POST", body: [
                "version": device.appVersion,
                "deviceID": device.id,
                "activationID": activationID,
            ])
        }

        func deactivate(activationID: String) async throws -> APIData {
            return try await self.authenticatedAPICall(endpoint: "deactivate", method: "POST", body: [
                "activationID": activationID,
            ])
        }

        func renameDevice(activationID: String, deviceName: String) async throws -> APIData {
            return try await self.authenticatedAPICall(endpoint: "activate", method: "POST", body: [
                "deviceName": deviceName,
                "activationID": activationID,
            ])
        }

        func listSubscriptions(bundleID: String) async throws -> APIData {
            return try await self.authenticatedAPICall(endpoint: "activate", method: "GET", body: [
                "bundleID": bundleID,
            ])
        }

        func listDevices(subscriptionID: String, device: Device) async throws -> APIData {
            return try await self.authenticatedAPICall(endpoint: "check", method: "POST", body: [
                "deviceType": device.type.rawValue,
                "deviceID": device.id,
                "subscriptionID": subscriptionID,
            ])
        }

        private func authenticatedAPICall(endpoint: String, method: String, body: [String: String]) async throws -> APIData {
            var modifiedBody = body
            let headers: [String: String]?
            switch self.currentAuthentication {
            case .none:
                headers = nil
            case .token(let token):
                headers = ["Authorization": "Bearer \(token)"]
            case .licence(let licence):
                headers = nil
                guard let licence = String(data: try licence.jsonData, encoding: .utf8) else {
                    throw Error.invalidLicence
                }
                modifiedBody["licence"] = licence
            }

            return try await self.networkAdapter.callAPI(endpoint: endpoint, method: method, body: modifiedBody, headers: headers)
        }
    }
}
