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
        return try self.logoutMock.throwingCalled() ?? .empty
    }

    var activateMock = MockDetails<(Device, String?), APIData>()
    func activate(device: Device, subscriptionID: String?) async throws -> APIData {
        return try self.activateMock.throwingCalled(withArguments: (device, subscriptionID)) ?? .empty
    }

    var checkMock = MockDetails<(String, Device), APIData>()
    func check(activationID: String, device: Device) async throws -> APIData {
        return try self.checkMock.throwingCalled(withArguments: (activationID, device)) ?? .empty
    }

    var deactivateMock = MockDetails<String, APIData>()
    func deactivate(activationID: String) async throws -> APIData {
        return try self.deactivateMock.throwingCalled(withArguments: activationID) ?? .empty
    }

    var renameDeviceMock = MockDetails<(String, String), APIData>()
    func renameDevice(activationID: String, deviceName: String) async throws -> APIData {
        return try self.renameDeviceMock.throwingCalled(withArguments: (activationID, deviceName)) ?? .empty
    }

    var listSubscriptionsMock = MockDetails<(String, Device.DeviceType), APIData>()
    func listSubscriptions(bundleID: String, deviceType: Device.DeviceType) async throws -> APIData {
        return try self.listSubscriptionsMock.throwingCalled(withArguments: (bundleID, deviceType)) ?? .empty
    }

    var listDevicesMock = MockDetails<(String, Device), APIData>()
    func listDevices(subscriptionID: String, device: Device) async throws -> APIData {
        return try self.listDevicesMock.throwingCalled(withArguments: (subscriptionID, device)) ?? .empty
    }
}
