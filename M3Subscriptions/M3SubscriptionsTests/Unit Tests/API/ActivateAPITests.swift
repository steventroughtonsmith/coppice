//
//  ActivateAPITests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

class ActivateAPITests: APITestCase {
    func test_run_calling_requestsActivateAPIEndpoint() async throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        _ = try? await api.run()

        XCTAssertEqual(mockAdapter.calledEndpoint, "activate")
    }

    func test_run_calling_usesPOSTMethod() async throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        _ = try? await api.run()

        XCTAssertEqual(mockAdapter.calledMethod, "POST")
    }

    func test_run_calling_setsEmail_PasswordAndBundleIDJSONOnBody() async throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        _ = try? await api.run()

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertEqual(calledBody["email"], "foo@bar.com")
        XCTAssertEqual(calledBody["password"], "123456")
        XCTAssertEqual(calledBody["bundleID"], "com.mcubedsw.Coppice")
    }

    func test_run_calling_setsDeviceID_DeviceName_DeviceTypeAndAppVersionJSONOnBody() async throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foo Bar Baz")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)
        _ = try? await api.run()

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertEqual(calledBody["deviceID"], device.id)
        XCTAssertEqual(calledBody["deviceType"], device.type.rawValue)
        XCTAssertEqual(calledBody["deviceName"], "Foo Bar Baz")
        XCTAssertEqual(calledBody["version"], device.appVersion)
    }

    func test_run_calling_setsSubscriptionIDJSONOnBodyIfSetInActivationRequest() async throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice", subscriptionID: "Sub123")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        _ = try? await api.run()

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertEqual(calledBody["subscriptionID"], "Sub123")
    }

    func test_run_calling_doesntSetSubscriptionIDJSONOnBodyIfNotSetOnActivationRequest() async throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        _ = try? await api.run()

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertNil(calledBody["subscriptionID"])
    }

    func test_run_calling_setsDeviceDeactivationTokenJSONOnBodyIfSetInActivationRequest() async throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice", deviceDeactivationToken: "Deactivate987")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        _ = try? await api.run()

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertEqual(calledBody["deactivatingDeviceToken"], "Deactivate987")
    }

    func test_run_calling_doesntSetDeviceDeactivationTokenJSONOnBodyIfNotSetOnActivationRequest() async throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        _ = try? await api.run()

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertNil(calledBody["deviceDeactivationToken"])
    }


    //MARK: - Error handling
    func test_run_errorHandling_returnsInvalidRequestIfDeviceNameIsNotSet() async throws {
        let expectedError = NSError(domain: "com.mcubedsw.test", code: -42, userInfo: nil)

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.apiError = expectedError

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device()
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        await XCTAssertThrowsErrorAsync(try await api.run()) { error in
            guard case ActivateAPI.Failure.invalidRequest = error else {
                XCTFail("Result is not an invalidRequest error")
                return
            }
        }
    }

    func test_run_errorHandling_returnsFailureIfErrorIsSupplied() async throws {
        let expectedError = NSError(domain: "com.mcubedsw.test", code: -42, userInfo: nil)

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.apiError = expectedError

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        await XCTAssertThrowsErrorAsync(try await api.run()) { error in
            guard case ActivateAPI.Failure.generic(let genericError) = error else {
                XCTFail("Result is not an generic error")
                return
            }
            XCTAssertEqual(genericError as NSError?, expectedError)
        }
    }

    func test_run_errorHandling_returnsFailureIfReceived_login_failed_Response() async throws {
        let payload = ["response": "login_failed"]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.returnValue = apiData

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        await XCTAssertThrowsErrorAsync(try await api.run()) { error in
            guard case ActivateAPI.Failure.loginFailed = error else {
                XCTFail("Result is not an loginFailed error")
                return
            }
        }
    }

    func test_run_errorHandling_returnsFailureAndSubscriptionPlansIfReceived_multiple_subscriptions_Response() async throws {
        let plan1: [String: Any] = ["id": "plan1", "name": "Plan A", "expirationDate": "2022-01-01T01:01:01Z", "maxDeviceCount": 5, "currentDeviceCount": 4, "renewalStatus": "renew"]
        let plan2: [String: Any] = ["id": "plan2", "name": "Plan B", "expirationDate": "2021-12-21T12:21:12Z", "maxDeviceCount": 3, "currentDeviceCount": 3, "renewalStatus": "cancelled"]
        let payload: [String: Any] = ["response": "multiple_subscriptions", "subscriptions": [plan1, plan2]]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.returnValue = apiData

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var subscriptions: [Subscription] = []
        await XCTAssertThrowsErrorAsync(try await api.run()) { error in
            guard case ActivateAPI.Failure.multipleSubscriptions(let subs) = error else {
                XCTFail("Result is not an multipleSubscriptions error")
                return
            }
            subscriptions = subs
        }

        let actualPlan1 = try XCTUnwrap(subscriptions.first)
        XCTAssertEqual(actualPlan1.id, "plan1")
        XCTAssertEqual(actualPlan1.name, "Plan A")
        XCTAssertDateEquals(actualPlan1.expirationDate, 2022, 1, 1, 1, 1, 1)
        XCTAssertEqual(actualPlan1.maxDeviceCount, 5)
        XCTAssertEqual(actualPlan1.currentDeviceCount, 4)

        let actualPlan2 = try XCTUnwrap(subscriptions.last)
        XCTAssertEqual(actualPlan2.id, "plan2")
        XCTAssertEqual(actualPlan2.name, "Plan B")
        XCTAssertDateEquals(actualPlan2.expirationDate, 2021, 12, 21, 12, 21, 12)
        XCTAssertEqual(actualPlan2.maxDeviceCount, 3)
        XCTAssertEqual(actualPlan2.currentDeviceCount, 3)
    }

    func test_run_errorHandling_returnsFailureIfReceived_no_subscription_found_Response() async throws {
        let payload = ["response": "no_subscription_found"]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.returnValue = apiData

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        await XCTAssertThrowsErrorAsync(try await api.run()) { error in
            guard case ActivateAPI.Failure.noSubscriptionFound = error else {
                XCTFail("Result is not an noSubscriptionFound error")
                return
            }
        }
    }

    func test_run_errorHandling_returnsFailureAndSubscriptionIfReceived_subscription_expired_Response() async throws {
        let payload: [String: Any] = [
            "response": "subscription_expired",
            "subscription": ["name": "Plan C", "expirationDate": "2020-01-02T03:04:05Z", "renewalStatus": "cancelled"],
        ]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.returnValue = apiData

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var subscription: Subscription?
        await XCTAssertThrowsErrorAsync(try await api.run()) { error in
            guard case ActivateAPI.Failure.subscriptionExpired(let sub) = error else {
                XCTFail("Result is not an subscriptionExpired error")
                return
            }
            subscription = sub
        }

        let actualSubscription = try XCTUnwrap(subscription)

        XCTAssertEqual(actualSubscription.name, "Plan C")
        XCTAssertDateEquals(actualSubscription.expirationDate, 2020, 1, 2, 3, 4, 5)
        XCTAssertEqual(actualSubscription.renewalStatus, .cancelled)
    }

    func test_run_errorHandling_returnsFailureAndDevicesIfReceived_too_many_devices_Response() async throws {
        let device1: [String: Any] = ["name": "My iMac", "deactivationToken": "tokeniMac", "activationDate": "2022-10-10T10:10:10Z"]
        let device2: [String: Any] = ["name": "My Mac Pro", "deactivationToken": "mactokenpro", "activationDate": "2031-03-31T03:31:03Z"]
        let payload: [String: Any] = ["response": "too_many_devices", "devices": [device1, device2]]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.returnValue = apiData

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var devices: [SubscriptionDevice] = []
        await XCTAssertThrowsErrorAsync(try await api.run()) { error in
            guard case ActivateAPI.Failure.tooManyDevices(let device) = error else {
                XCTFail("Result is not an tooManyDevices error")
                return
            }
            devices = device
        }

        let actualDevice1 = try XCTUnwrap(devices.first)
        XCTAssertEqual(actualDevice1.name, "My iMac")
        XCTAssertEqual(actualDevice1.deactivationToken, "tokeniMac")
        XCTAssertDateEquals(actualDevice1.activationDate, 2022, 10, 10, 10, 10, 10)

        let actualDevice2 = try XCTUnwrap(devices.last)
        XCTAssertEqual(actualDevice2.name, "My Mac Pro")
        XCTAssertEqual(actualDevice2.deactivationToken, "mactokenpro")
        XCTAssertDateEquals(actualDevice2.activationDate, 2031, 3, 31, 3, 31, 3)
    }


    //MARK: - Success
    private func runSuccessfulActivationResponseTest(isExpired: Bool = false, renewalStatus: Subscription.RenewalStatus) async throws {
        var payload: [String: Any] = [
            "response": (isExpired ? "subscription_expired" : "active"),
            "subscription": [
                "name": "Plan C",
                "expirationDate": "2020-01-02T03:04:05Z",
                "renewalStatus": renewalStatus.rawValue,
            ],
            "device": [
                "name": "My iMac",
            ],
        ]
        if (!isExpired) {
            payload["token"] = "tucan43"
        }

        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.returnValue = apiData

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        let response = try await api.run()

        XCTAssertEqual(response.isActive, !isExpired)
        XCTAssertEqual(response.deviceIsActivated, !isExpired)

        if !isExpired {
            XCTAssertEqual(response.token, "tucan43")
        } else {
            XCTAssertNil(response.token)
        }
        XCTAssertEqual(response.deviceName, "My iMac")

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, "Plan C")
        XCTAssertDateEquals(subscription.expirationDate, 2020, 1, 2, 3, 4, 5)
        XCTAssertEqual(subscription.renewalStatus, renewalStatus)
        XCTAssertEqual(subscription.hasExpired, isExpired)
    }

    func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_Response() async throws {
        try await self.runSuccessfulActivationResponseTest(renewalStatus: .renew)
    }

    func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_ResponseAndRenewStatusIsFailed() async throws {
        try await self.runSuccessfulActivationResponseTest(renewalStatus: .failed)
    }

    func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_ResponseAndRenewStatusIsCancelled() async throws {
        try await self.runSuccessfulActivationResponseTest(renewalStatus: .cancelled)
    }
}
