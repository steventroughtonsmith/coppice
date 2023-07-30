//
//  CheckAPITests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

extension API.V1 {
    class CheckAPITests: APITestCase {
        func test_run_calling_requestsCheckAPIEndpoint() async throws {
            let mockAdapter = MockNetworkAdapter()
            let api = CheckAPI(networkAdapter: mockAdapter, device: Device(), token: "tucan42")
            _ = try? await api.run()

            XCTAssertEqual(mockAdapter.calledEndpoint, "check")
        }

        func test_run_calling_usesPostMethod() async throws {
            let mockAdapter = MockNetworkAdapter()
            let api = CheckAPI(networkAdapter: mockAdapter, device: Device(), token: "tucan42")
            _ = try? await api.run()

            XCTAssertEqual(mockAdapter.calledMethod, "POST")
        }

        func test_run_calling_setsToken_Version_DeviceTypeAndDeviceIDJSONAsBody() async throws {
            let mockAdapter = MockNetworkAdapter()
            let device = Device()
            let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")
            _ = try? await api.run()

            let calledBody = try XCTUnwrap(mockAdapter.calledBody)
            XCTAssertEqual(calledBody["deviceID"], device.id)
            XCTAssertEqual(calledBody["deviceType"], device.type.rawValue)
            XCTAssertEqual(calledBody["token"], "tucan42")
        }

        func test_run_calling_setsDeviceNameInBodyJSONIfSetOnDevice() async throws {
            let mockAdapter = MockNetworkAdapter()
            let device = Device(name: "POSSUMZ!!1!")
            let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")
            _ = try? await api.run()

            let calledBody = try XCTUnwrap(mockAdapter.calledBody)
            XCTAssertEqual(calledBody["deviceName"], "POSSUMZ!!1!")
        }

        func test_run_calling_doesntSetDeviceNameInBodyJSONIfNotSetOnDevice() async throws {
            let mockAdapter = MockNetworkAdapter()
            let device = Device()
            let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")
            _ = try? await api.run()

            let calledBody = try XCTUnwrap(mockAdapter.calledBody)
            XCTAssertNil(calledBody["deviceName"])
        }


        //MARK: - Error Handling
        func test_run_errorHandling_returnsFailureIfErrorIsSupplied() async throws {
            let expectedError = NSError(domain: "com.mcubedsw.test", code: -42, userInfo: nil)

            let mockAdapter = MockNetworkAdapter()
            mockAdapter.apiError = expectedError

            let device = Device()
            let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

            await XCTAssertThrowsErrorAsync(try await api.run()) { error in
                guard case CheckAPI.Failure.generic(let genericError) = error else {
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
            let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

            await XCTAssertThrowsErrorAsync(try await api.run()) { error in
                guard case CheckAPI.Failure.noDeviceFound = error else {
                    XCTFail("Result is not an noDeviceFound error")
                    return
                }
            }
        }

        func test_run_errorHandling_returnsFailureIfReceived_no_subscription_found_Response() async throws {
            let payload = ["response": "no_subscription_found"]
            let signature = try self.signature(forPayload: payload)
            let json: [String: Any] = ["payload": payload, "signature": signature]
            let apiData = try XCTUnwrap(APIData(json: json))

            let mockAdapter = MockNetworkAdapter()
            mockAdapter.returnValue = apiData

            let device = Device()
            let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

            await XCTAssertThrowsErrorAsync(try await api.run()) { error in
                guard case CheckAPI.Failure.noSubscriptionFound = error else {
                    XCTFail("Result is not an noDeviceFound error")
                    return
                }
            }
        }


        //MARK: - Success
        private func runSuccessfulActivationReponseTest(isExpired: Bool = false, renewalStatus: Subscription.RenewalStatus) async throws {
            var payload: [String: Any] = [
                "response": (isExpired ? "subscription_expired" : "active"),
                "subscription": [
                    "name": "Plan C",
                    "expirationDate": "2020-01-02T03:04:05Z",
                    "renewalStatus": renewalStatus.rawValue,
                ],
                "device": [
                    "name": "Bob's Mac Pro",
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

            let device = Device()
            let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

            let response = try await api.run()

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

        func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_Response() async throws {
            try await self.runSuccessfulActivationReponseTest(renewalStatus: .renew)
        }

        func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_ResponseAndRenewStatusIsFailed() async throws {
            try await self.runSuccessfulActivationReponseTest(renewalStatus: .failed)
        }

        func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_active_ResponseAndRenewStatusIsCancelled() async throws {
            try await self.runSuccessfulActivationReponseTest(renewalStatus: .cancelled)
        }

        func test_run_returnsActivationResponseWithSubscriptionAndDeviceNameIfReceived_expired_Response() async throws {
            try await self.runSuccessfulActivationReponseTest(isExpired: false, renewalStatus: .cancelled)
        }
    }
}
