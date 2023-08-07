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

    func expecting(_ response: APIData.Response) -> APIAdapterV2
    func allowedFailures(_ responses: [APIData.Response]) -> APIAdapterV2
    func withAuthentication(_ authentication: API.V2.Authentication) -> APIAdapterV2

    func logout() async throws -> APIData

    func activate(device: Device, subscriptionID: String?) async throws -> APIData
    func check(activationID: String, device: Device) async throws -> APIData
    func deactivate(activationID: String) async throws -> APIData

    func renameDevice(activationID: String, deviceName: String) async throws -> APIData
    func listSubscriptions(bundleID: String, deviceType: Device.DeviceType) async throws -> APIData
    func listDevices(subscriptionID: String, device: Device) async throws -> APIData
}


extension API.V2 {
    class Adapter: APIAdapterV2 {
        let networkAdapter: NetworkAdapter
        init(networkAdapter: NetworkAdapter) {
            self.networkAdapter = networkAdapter
        }

        private struct Context {
            var authentication: Authentication?
            var expectedResponse: APIData.Response?
            var allowedFailures: [APIData.Response] = []
        }

        private var currentContext: Context?

        func withAuthentication(_ authentication: API.V2.Authentication) -> APIAdapterV2 {
            var context = self.currentContext ?? Context()
            context.authentication = authentication
            self.currentContext = context
            return self
        }

        func expecting(_ response: APIData.Response) -> APIAdapterV2 {
            var context = self.currentContext ?? Context()
            context.expectedResponse = response
            self.currentContext = context
            return self
        }

        func allowedFailures(_ responses: [APIData.Response]) -> APIAdapterV2 {
            var context = self.currentContext ?? Context()
            context.allowedFailures = responses
            self.currentContext = context
            return self
        }

        func login(email: String, password: String, deviceName: String) async throws -> APIData {
            return try await self.networkAdapter.callAPI(endpoint: "login", method: .post, body: [
                "email": email,
                "password": password,
                "deviceName": deviceName,
            ], headers: nil)
        }

        func logout() async throws -> APIData {
            return try await self.authenticatedAPICall(endpoint: "logout", method: .post, body: [:])
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
            return try await self.authenticatedAPICall(endpoint: "activate", method: .post, body: body)
        }

        func check(activationID: String, device: Device) async throws -> APIData {
            return try await self.authenticatedAPICall(endpoint: "check", method: .post, body: [
                "version": device.appVersion,
                "deviceID": device.id,
                "activationID": activationID,
            ])
        }

        func deactivate(activationID: String) async throws -> APIData {
            return try await self.authenticatedAPICall(endpoint: "deactivate", method: .post, body: [
                "activationID": activationID,
            ])
        }

        func renameDevice(activationID: String, deviceName: String) async throws -> APIData {
            return try await self.authenticatedAPICall(endpoint: "rename", method: .post, body: [
                "deviceName": deviceName,
                "activationID": activationID,
            ])
        }

        func listSubscriptions(bundleID: String, deviceType: Device.DeviceType) async throws -> APIData {
            return try await self.authenticatedAPICall(endpoint: "subscriptions", method: .get, body: [
                "bundleID": bundleID,
                "deviceType": deviceType.rawValue,
            ])
        }

        func listDevices(subscriptionID: String, device: Device) async throws -> APIData {
            return try await self.authenticatedAPICall(endpoint: "devices", method: .get, body: [
                "deviceType": device.type.rawValue,
                "deviceID": device.id,
                "subscriptionID": subscriptionID,
            ])
        }

        private func authenticatedAPICall(endpoint: String, method: HTTPMethod, body: [String: String]) async throws -> APIData {
            var modifiedBody = body
            let headers: [String: String]?
            switch self.currentContext?.authentication {
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

            let apiData: APIData
            do {
                apiData = try await self.networkAdapter.callAPI(endpoint: endpoint, method: method, body: modifiedBody, headers: headers)
            } catch {
                throw Error.couldNotConnectToServer(error as NSError)
            }

            guard let expectedResult = self.currentContext?.expectedResponse else {
                preconditionFailure("No expected response")
            }

            guard expectedResult == apiData.response else {
                let failures = self.currentContext?.allowedFailures ?? []
                if failures.contains(apiData.response) {
                    throw Error(apiResponse: apiData.response) ?? .invalidResponse
                }
                throw Error.invalidResponse
            }

            return apiData
        }
    }
}
