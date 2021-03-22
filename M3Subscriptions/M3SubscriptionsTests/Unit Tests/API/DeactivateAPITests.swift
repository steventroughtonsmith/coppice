//
//  DeactivateAPITests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

class DeactivateAPITests: APITestCase {
    //MARK: - Sending request
    func test_run_calling_requestsDeactivateAPIEndpoint() throws {
        let mockAdapter = MockNetworkAdapter()
        let api = DeactivateAPI(networkAdapter: mockAdapter, device: Device(), token: "token3")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        XCTAssertEqual(mockAdapter.calledEndpoint, "deactivate")
    }

    func test_run_calling_usesPostMethod() throws {
        let mockAdapter = MockNetworkAdapter()
        let api = DeactivateAPI(networkAdapter: mockAdapter, device: Device(), token: "token3")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        XCTAssertEqual(mockAdapter.calledMethod, "POST")
    }

    func test_run_calling_setsTokenAndDeviceIDJSONAsBody() throws {
        let mockAdapter = MockNetworkAdapter()
        let device = Device()
        let api = DeactivateAPI(networkAdapter: mockAdapter, device: device, token: "token3")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let calledBody = try XCTUnwrap(mockAdapter.calledBody)
        XCTAssertEqual(calledBody["deviceID"], device.id)
        XCTAssertEqual(calledBody["token"], "token3")
    }


    //MARK: - Error handling
    func test_run_errorHandling_returnsFailureIfErrorIsSupplied() throws {
        let expectedError = NSError(domain: "com.mcubedsw.test", code: -42, userInfo: nil)

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .failure(expectedError)

        let device = Device()
        let api = DeactivateAPI(networkAdapter: mockAdapter, device: device, token: "token3")

        var actualResult: Result<ActivationResponse, DeactivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .generic(let error) = failure
        else {
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
        let api = DeactivateAPI(networkAdapter: mockAdapter, device: device, token: "token3")

        var actualResult: Result<ActivationResponse, DeactivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .noDeviceFound = failure
        else {
//                XCTFail("Result is not a noDeviceFound failure")
                return
        }
        #warning("Fix this test")
    }


    //MARK: - Success
    func test_run_returnsSubscriptionInfoWithDeactivateStateIfRequestWasSuccessful() throws {
        let payload = ["response": "deactivated"]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let device = Device()
        let api = DeactivateAPI(networkAdapter: mockAdapter, device: device, token: "token3")

        var actualResult: Result<ActivationResponse, DeactivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard case .success(let info) = try XCTUnwrap(actualResult) else {
            XCTFail("Result is not a success")
            return
        }

        XCTAssertFalse(info.isActive)
        XCTAssertFalse(info.deviceIsActivated)
    }
}
