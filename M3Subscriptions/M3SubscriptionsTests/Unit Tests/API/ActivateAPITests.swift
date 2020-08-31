//
//  ActivateAPITests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class ActivateAPITests: APITestCase {
    func test_run_calling_requestsActivateAPIEndpoint() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        XCTAssertEqual(mockAdapter.calledEndpoint, "activate")
    }

    func test_run_calling_usesPOSTMethod() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        XCTAssertEqual(mockAdapter.calledMethod, "POST")
    }

    func test_run_calling_setsEmail_PasswordAndBundleIDJSONOnBody() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertEqual(calledBody["email"], "foo@bar.com")
        XCTAssertEqual(calledBody["password"], "123456")
        XCTAssertEqual(calledBody["bundleID"], "com.mcubedsw.Coppice")
    }

    func test_run_calling_setsDeviceID_DeviceName_DeviceTypeAndAppVersionJSONOnBody() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foo Bar Baz")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertEqual(calledBody["deviceID"], device.id)
        XCTAssertEqual(calledBody["deviceType"], device.type.rawValue)
        XCTAssertEqual(calledBody["deviceName"], "Foo Bar Baz")
        XCTAssertEqual(calledBody["version"], device.appVersion)
    }

    func test_run_calling_setsSubscriptionIDJSONOnBodyIfSetInActivationRequest() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice", subscriptionID: "Sub123")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertEqual(calledBody["subscriptionID"], "Sub123")
    }

    func test_run_calling_doesntSetSubscriptionIDJSONOnBodyIfNotSetOnActivationRequest() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertNil(calledBody["subscriptionID"])
    }

    func test_run_calling_setsDeviceDeactivationTokenJSONOnBodyIfSetInActivationRequest() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice", deviceDeactivationToken: "Deactivate987")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertEqual(calledBody["deactivatingDeviceToken"], "Deactivate987")
    }

    func test_run_calling_doesntSetDeviceDeactivationTokenJSONOnBodyIfNotSetOnActivationRequest() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertNil(calledBody["deviceDeactivationToken"])
    }


    //MARK: - Error handling
    func test_run_errorHandling_returnsInvalidRequestIfDeviceNameIsNotSet() throws {
        let expectedError = NSError(domain: "com.mcubedsw.test", code: -42, userInfo: nil)

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .failure(expectedError)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device()
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .invalidRequest = failure else {
                XCTFail("Result is not an invalidRequest error")
                return
        }
    }

    func test_run_errorHandling_returnsFailureIfErrorIsSupplied() throws {
        let expectedError = NSError(domain: "com.mcubedsw.test", code: -42, userInfo: nil)

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .failure(expectedError)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .generic(let error) = failure else {
                XCTFail("Result is not a generic error")
                return
        }

        XCTAssertEqual(error as NSError?, expectedError)
    }

    func test_run_errorHandling_returnsFailureIfReceived_login_failed_Response() throws {
        let payload = ["response": "login_failed"]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .loginFailed = failure else {
                XCTFail("Result is not a loginFailed error")
                return
        }
    }

    func test_run_errorHandling_returnsFailureAndSubscriptionPlansIfReceived_multiple_subscriptions_Response() throws {
        let plan1: [String: Any] = ["id": "plan1", "name": "Plan A", "expirationDate": "2022-01-01T01:01:01Z", "maxDeviceCount":5, "currentDeviceCount":4, "renewalStatus": "renew"]
        let plan2: [String: Any] = ["id": "plan2", "name": "Plan B", "expirationDate": "2021-12-21T12:21:12Z", "maxDeviceCount":3, "currentDeviceCount":3, "renewalStatus": "cancelled"]
        let payload: [String: Any] = ["response": "multiple_subscriptions", "subscriptions": [plan1, plan2]]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .multipleSubscriptions(let subscriptions) = failure else {
                XCTFail("Result is not a multipleSubscriptions failure")
                return
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

    func test_run_errorHandling_returnsFailureIfReceived_no_subscription_found_Response() throws {
        let payload = ["response": "no_subscription_found"]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .noSubscriptionFound = failure else {
                XCTFail("Result is not a noSubscriptionFound error")
                return
        }
    }

//    func test_run_errorHandling_returnsFailureAndSubscriptionIfReceived_subscription_expired_Response() throws {
//        let payload = ["response": "subscription_expired", "subscriptionName": "Plan C", "expirationDate": "2020-01-02T03:04:05Z"]
//        let signature = "Syj/uI3VvxI+cJj9MvfSeyUdU3xZiUmEbUO3clzcM2znhQRJMQNrayF+nTkOunj+S59x2TIFIS6n2AdWAn9bfPDpsTuibWlRWZFELiidlJDL4+mn+yZG8jLJGJoNcLV4zXuZrD4mbnSI2/rH8p4QybW59NanmC8t6mt89W9JCAUICfCLfZBnYMBx/3RR6TBY4b79p4PV84KG2i77Z2ga1wgkO852jGVwS9eG+8ekgALnMw6X/YLgZpqkQHuD39eCSURvglVMMC84+vrtdROghhjD4htuSwYgDmkx93+J6aOUGTjDT7iUTS3+AkYFOSd6FbdI/qpR5xKcMN1+I+CrvQ=="
//        let json: [String: Any] = ["payload": payload, "signature": signature]
//        let apiData = try XCTUnwrap(APIData(json: json))
//
//        let mockAdapter = MockNetworkAdapter()
//        mockAdapter.resultToReturn = .success(apiData)
//
//        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
//        let device = Device(name: "Foobar")
//        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)
//
//        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
//        self.performAndWaitFor("Call API") { (expectation) in
//            api.run { result in
//                actualResult = result
//                expectation.fulfill()
//            }
//        }
//
//        guard
//            case .failure(let failure) = try XCTUnwrap(actualResult),
//            case .subscriptionExpired(let subscription) = failure else {
//                XCTFail("Result is not a subscriptionExpired failure")
//                return
//        }
//
//        let actualSubscription = try XCTUnwrap(subscription)
//
//        XCTAssertEqual(actualSubscription.name, "Plan C")
//        XCTAssertDateEquals(actualSubscription.expirationDate, 2020, 1, 2, 3, 4, 5)
//    }

    func test_run_errorHandling_returnsFailureAndDevicesIfReceived_too_many_devices_Response() throws {
        let device1: [String: Any] = ["name": "My iMac", "deactivationToken": "tokeniMac", "activationDate": "2022-10-10T10:10:10Z"]
        let device2: [String: Any] = ["name": "My Mac Pro", "deactivationToken": "mactokenpro", "activationDate": "2031-03-31T03:31:03Z"]
        let payload: [String: Any] = ["response": "too_many_devices", "devices": [device1, device2]]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .tooManyDevices(let devices) = failure else {
                XCTFail("Result is not a tooManyDevices failure")
                return
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
    private func runSuccessfulActivationResponseTest(isExpired: Bool = false, renewalStatus: Subscription.RenewalStatus) throws {
        var payload: [String: Any] = [
            "response": (isExpired ? "subscription_expired" : "active"),
            "subscription": [
                "name": "Plan C",
                "expirationDate": "2020-01-02T03:04:05Z",
                "renewalStatus": renewalStatus.rawValue
            ],
            "device": [
                "name": "My iMac"
            ],
        ]
        if (!isExpired) {
            payload["token"] = "tucan43"
        }

        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard case .success(let response) = try XCTUnwrap(actualResult) else {
            XCTFail("Result is not a success")
            return
        }

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

    func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_Response() throws {
        try self.runSuccessfulActivationResponseTest(renewalStatus: .renew)
    }

    func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_ResponseAndRenewStatusIsFailed() throws {
        try self.runSuccessfulActivationResponseTest(renewalStatus: .failed)
    }

    func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_ResponseAndRenewStatusIsCancelled() throws {
        try self.runSuccessfulActivationResponseTest(renewalStatus: .cancelled)
    }

    func test_run_returnsActivationResponseWithExpiredSubscriptionIfReceived_expired_Response() throws {
        try self.runSuccessfulActivationResponseTest(isExpired: true, renewalStatus: .renew)
    }
}
