//
//  MockAPIAdapterV2.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 30/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation
@testable import M3Subscriptions

class MockAPIAdapterV2: APIAdapterV2 {
    var loginMock = MockDetails<(String, String, String), APIData>()
    func login(email: String, password: String, deviceName: String) async throws -> APIData {
        return try self.loginMock.throwingCalled(withArguments: (email, password, deviceName)) ?? .empty
    }

    var withAuthenticationMock = MockDetails<API.V2.Authentication, Void>()
    func withAuthentication(_ authentication: API.V2.Authentication) -> APIAdapterV2 {
        self.withAuthenticationMock.called(withArguments: authentication)
        return self
    }

    var logoutMock = MockDetails<Void, APIData>()
    func logout() async throws -> APIData {
        let apiData = try self.logoutMock.throwingCalled() ?? .empty
        try self.checkData(apiData)
        return apiData
    }

    var activateMock = MockDetails<(Device, String?), APIData>()
    func activate(device: Device, subscriptionID: String?) async throws -> APIData {
        let apiData = try self.activateMock.throwingCalled(withArguments: (device, subscriptionID)) ?? .empty
        try self.checkData(apiData)
        return apiData
    }

    var checkMock = MockDetails<(String, Device), APIData>()
    func check(activationID: String, device: Device) async throws -> APIData {
        let apiData = try self.checkMock.throwingCalled(withArguments: (activationID, device)) ?? .empty
        try self.checkData(apiData)
        return apiData
    }

    var deactivateMock = MockDetails<String, APIData>()
    func deactivate(activationID: String) async throws -> APIData {
        let apiData = try self.deactivateMock.throwingCalled(withArguments: activationID) ?? .empty
        try self.checkData(apiData)
        return apiData
    }

    var renameDeviceMock = MockDetails<(String, String), APIData>()
    func renameDevice(activationID: String, deviceName: String) async throws -> APIData {
        let apiData = try self.renameDeviceMock.throwingCalled(withArguments: (activationID, deviceName)) ?? .empty
        try self.checkData(apiData)
        return apiData
    }

    var listSubscriptionsMock = MockDetails<(String, Device.DeviceType), APIData>()
    func listSubscriptions(bundleID: String, deviceType: Device.DeviceType) async throws -> APIData {
        let apiData = try self.listSubscriptionsMock.throwingCalled(withArguments: (bundleID, deviceType)) ?? .empty
        try self.checkData(apiData)
        return apiData
    }

    var listDevicesMock = MockDetails<(String, Device), APIData>()
    func listDevices(subscriptionID: String, device: Device) async throws -> APIData {
        let apiData = try self.listDevicesMock.throwingCalled(withArguments: (subscriptionID, device)) ?? .empty
        try self.checkData(apiData)
        return apiData
    }

    private var expectedResponse: APIData.Response?
    func expecting(_ response: APIData.Response) -> APIAdapterV2 {
        self.expectedResponse = response
        return self
    }

    private var allowedFailures: [APIData.Response] = []
    func allowedFailures(_ responses: [APIData.Response]) -> APIAdapterV2 {
        self.allowedFailures = responses
        return self
    }

    private func checkData(_ apiData: APIData) throws {
        if let expectedResponse = self.expectedResponse, apiData.response != expectedResponse {
            if self.allowedFailures.contains(apiData.response) {
                throw API.V2.Error(apiResponse: apiData.response) ?? .invalidResponse
            }
            throw API.V2.Error.invalidResponse
        }
    }

    var startTrialMock = MockDetails<(String, Device), APIData>()
    func startTrial(bundleID: String, device: Device) async throws -> APIData {
        return try self.startTrialMock.throwingCalled(withArguments: (bundleID, device)) ?? .empty
    }
}
