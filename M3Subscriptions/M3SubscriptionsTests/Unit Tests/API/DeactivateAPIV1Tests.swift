//
//  DeactivateAPITests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

extension API.V1 {
    class DeactivateAPITests: APITestCase {
        //MARK: - Sending request
        func test_run_calling_requestsDeactivateAPIEndpoint() async throws {
            let mockAdapter = MockNetworkAdapter()
            let api = DeactivateAPI(networkAdapter: mockAdapter, device: Device(), token: "token3")
            _ = try? await api.run()
            
            XCTAssertEqual(mockAdapter.calledEndpoint, "deactivate")
        }
        
        func test_run_calling_usesPostMethod() async throws {
            let mockAdapter = MockNetworkAdapter()
            let api = DeactivateAPI(networkAdapter: mockAdapter, device: Device(), token: "token3")
            _ = try? await api.run()
            
            XCTAssertEqual(mockAdapter.calledMethod, "POST")
        }
        
        func test_run_calling_setsTokenAndDeviceIDJSONAsBody() async throws {
            let mockAdapter = MockNetworkAdapter()
            let device = Device()
            let api = DeactivateAPI(networkAdapter: mockAdapter, device: device, token: "token3")
            _ = try? await api.run()
            
            let calledBody = try XCTUnwrap(mockAdapter.calledBody)
            XCTAssertEqual(calledBody["deviceID"], device.id)
            XCTAssertEqual(calledBody["token"], "token3")
        }
        
        
        //MARK: - Error handling
        func test_run_errorHandling_returnsFailureIfErrorIsSupplied() async throws {
            let expectedError = NSError(domain: "com.mcubedsw.test", code: -42, userInfo: nil)
            
            let mockAdapter = MockNetworkAdapter()
            mockAdapter.apiError = expectedError
            
            let device = Device()
            let api = DeactivateAPI(networkAdapter: mockAdapter, device: device, token: "token3")
            
            await XCTAssertThrowsErrorAsync(try await api.run()) { error in
                guard case DeactivateAPI.Failure.generic(let genericError) = error else {
                    XCTFail("Result is not an generic error")
                    return
                }
                XCTAssertEqual(genericError as NSError?, expectedError)
            }
        }
        
        func test_run_errorHandling_returnsFailureIfReceived_no_device_found_Response() async throws {
            let payload = ["response": "no_device_found"]
            let signature = try self.signature(forPayload: payload)
            let json: [String: Any] = ["payload": payload, "signature": signature]
            let apiData = try XCTUnwrap(APIData(json: json))
            
            let mockAdapter = MockNetworkAdapter()
            mockAdapter.returnValue = apiData
            
            let device = Device()
            _ = DeactivateAPI(networkAdapter: mockAdapter, device: device, token: "token3")
            
            //        var actualResult: Result<ActivationResponse, DeactivateAPI.Failure>?
            //        self.performAndWaitFor("Call API") { (expectation) in
            //            api.run { result in
            //                actualResult = result
            //                expectation.fulfill()
            //            }
            //        }
            //
            //        guard
            //            case .failure(let failure) = try XCTUnwrap(actualResult),
            //            case .noDeviceFound = failure
            //        else {
            ////                XCTFail("Result is not a noDeviceFound failure")
            //                return
            //        }
#warning("Fix this test")
        }
        
        
        //MARK: - Success
        func test_run_returnsSubscriptionInfoWithDeactivateStateIfRequestWasSuccessful() async throws {
            let payload = ["response": "deactivated"]
            let signature = try self.signature(forPayload: payload)
            let json: [String: Any] = ["payload": payload, "signature": signature]
            let apiData = try XCTUnwrap(APIData(json: json))
            
            let mockAdapter = MockNetworkAdapter()
            mockAdapter.returnValue = apiData
            
            let device = Device()
            let api = DeactivateAPI(networkAdapter: mockAdapter, device: device, token: "token3")
            
            let info = try await api.run()
            
            XCTAssertFalse(info.isActive)
            XCTAssertFalse(info.deviceIsActivated)
        }
    }
}
