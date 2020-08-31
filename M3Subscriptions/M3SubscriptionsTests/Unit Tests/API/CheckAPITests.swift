//
//  CheckAPITests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class CheckAPITests: APITestCase {
    func test_run_calling_requestsCheckAPIEndpoint() throws {
        let mockAdapter = MockNetworkAdapter()
        let api = CheckAPI(networkAdapter: mockAdapter, device: Device(), token: "tucan42")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        XCTAssertEqual(mockAdapter.calledEndpoint, "check")
    }

    func test_run_calling_usesPostMethod() throws {
        let mockAdapter = MockNetworkAdapter()
        let api = CheckAPI(networkAdapter: mockAdapter, device: Device(), token: "tucan42")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        XCTAssertEqual(mockAdapter.calledMethod, "POST")
    }

    func test_run_calling_setsToken_Version_DeviceTypeAndDeviceIDJSONAsBody() throws {
        let mockAdapter = MockNetworkAdapter()
        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertEqual(calledBody["deviceID"], device.id)
        XCTAssertEqual(calledBody["deviceType"], device.type.rawValue)
        XCTAssertEqual(calledBody["token"], "tucan42")
    }

    func test_run_calling_setsDeviceNameInBodyJSONIfSetOnDevice() throws {
        let mockAdapter = MockNetworkAdapter()
        let device = Device(name: "POSSUMZ!!1!")
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertEqual(calledBody["deviceName"], "POSSUMZ!!1!")
    }

    func test_run_calling_doesntSetDeviceNameInBodyJSONIfNotSetOnDevice() throws {
        let mockAdapter = MockNetworkAdapter()
        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertNil(calledBody["deviceName"])
    }


    //MARK: - Error Handling
    func test_run_errorHandling_returnsFailureIfErrorIsSupplied() throws {
        let expectedError = NSError(domain: "com.mcubedsw.test", code: -42, userInfo: nil)

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .failure(expectedError)

        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

        var actualResult: Result<ActivationResponse, CheckAPI.Failure>?
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

    func test_run_errorHandling_returnsFailureIfReceived_no_device_found_Response() throws {
        let payload = ["response": "no_device_found"]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

        var actualResult: Result<ActivationResponse, CheckAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .noDeviceFound = failure else {
                XCTFail("Result is not a noDeviceFound failure")
                return
        }
    }

    func test_run_errorHandling_returnsFailureIfReceived_no_subscription_found_Response() throws {
        let payload = ["response": "no_subscription_found"]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

        var actualResult: Result<ActivationResponse, CheckAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .noSubscriptionFound = failure else {
                XCTFail("Result is not a noSubscriptionFound failure")
                return
        }
    }


    //MARK: - Success
    private func runSuccessfulActivationReponseTest(isExpired: Bool = false, renewalStatus: Subscription.RenewalStatus) throws {
        var payload: [String: Any] = [
            "response": (isExpired ? "subscription_expired" : "active"),
            "subscription": [
                "name": "Plan C",
                "expirationDate": "2020-01-02T03:04:05Z",
                "renewalStatus": renewalStatus.rawValue
            ],
            "device": [
                "name": "Bob's Mac Pro"
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

        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

        var actualResult: Result<ActivationResponse, CheckAPI.Failure>?
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
        XCTAssertTrue(response.deviceIsActivated) //Note this line is different from the activate test as even though the subscription expired the device will still be activated on a check
        XCTAssertEqual(response.token, "tucan43")
        XCTAssertEqual(response.deviceName, "Bob's Mac Pro")

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, "Plan C")
        XCTAssertDateEquals(subscription.expirationDate, 2020, 1, 2, 3, 4, 5)
        XCTAssertEqual(subscription.renewalStatus, renewalStatus)
        XCTAssertEqual(subscription.hasExpired, isExpired)
    }

    func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_Response() throws {
        try self.runSuccessfulActivationReponseTest(renewalStatus: .renew)
    }

    func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_ResponseAndRenewStatusIsFailed() throws {
        try self.runSuccessfulActivationReponseTest(renewalStatus: .failed)
    }

    func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_ResponseAndRenewStatusIsCancelled() throws {
        try self.runSuccessfulActivationReponseTest(renewalStatus: .cancelled)
    }

    func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_expired_Response() throws {
        try self.runSuccessfulActivationReponseTest(isExpired: false, renewalStatus: .cancelled)
    }
}
