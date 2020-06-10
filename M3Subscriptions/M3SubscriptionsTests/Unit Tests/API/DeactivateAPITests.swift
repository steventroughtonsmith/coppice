//
//  DeactivateAPITests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class DeactivateAPITests: XCTestCase {
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

        let bodyData = try XCTUnwrap(mockAdapter.calledBody)
        let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
        XCTAssertEqual(json?["deviceID"] as? String, device.id)
        XCTAssertEqual(json?["token"] as? String, "token3")
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
            case .generic(let error) = failure else {
            XCTFail("Result is not a generic error")
            return
        }

        XCTAssertEqual(error as NSError?, expectedError)
    }

    func test_run_errorHandling_returnsFailureIfReceived_no_device_found_Response() throws {
        let payload = ["response": "no_device_found"]
        let signature = "3BLTKt7ToQUlKSDFFPctzZz4fwsChOSWqMBKrPuD1BnJ5hl7/iJAcirzJds0f6afSJrNCiy0MVIbaazoyYrv3hF6EOBhipHe5mwtIjkZrf74aMgYcDb9v9P7JfGUfzax9HBGtplfAaZaGlO94auGkiRxe/1LOFCUIu/l+zeYU+TkrSRnqUyvXl7RnS3MhK7j8BWjlTaOx5WdU+scEweETdN9V31YhQZX7LmEebpSvZObfvgm2LAntLArXpIChgAb0js7gCneDooHWyaICvgHJJuUlVRijOANAi9+21dNdl3tlwidGUDo91Uq906GIBdBWfhz+9S2VBYpgxlWH4u7Nw=="
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
            case .noDeviceFound = failure else {
                XCTFail("Result is not a noDeviceFound failure")
                return
        }
    }


    //MARK: - Success
    func test_run_returnsSubscriptionInfoWithDeactivateStateIfRequestWasSuccessful() throws {
        let payload = ["response": "deactivated"]
        let signature = "2FK5GJmiT6C4aLZTWq8R0d+sEXWLORh0iQnHKritAfySu+W/wvhlblSXy2hUqKiRjHuOWIcz+f4wjMBTuoki7SAV78LElaPxor2hIEB8eqtaX3P+foAY0s/XpnlXWXg7YrUD53YsCRaZR47rLfLBsS9iCcKPRIWz8xXgyev4sbwt2Td3EvFukIasGRsTMe9Jvt0Qi1euyN8yKB7kYPqH43Oaua0rdxUN8BjoiTmUHwq7Z3gBn2+3K7DzhfRoYY7AAqZDO9FwDrcrwI5b5M5eXG9ZLSCdYJadeW6VfFLc/6Mtnt59EHzazbmzkfUwYw0y0+Cbvj8eb/+eiN8a/ALgBg=="
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

        XCTAssertEqual(info.state, .deactivated)
    }

}
