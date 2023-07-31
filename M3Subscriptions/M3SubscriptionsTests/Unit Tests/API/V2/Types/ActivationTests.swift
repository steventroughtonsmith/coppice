//
//  ActivationTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 30/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

final class ActivationTests: APITestCase {
    func test_init_throwsInvalidResponseIfActivationIDMissing() throws {
        self.runInvalidResponseTest(activationID: nil,
                                    device: ["name": "My Machine"],
                                    subscription: [
                                        "id": "abcde",
                                        "name": "Annual Subscription",
                                        "expirationTimestamp": 654_321_000,
                                        "renewalStatus": "renew",
                                    ])
    }

    func test_init_throwsInvalidResponseIfDeviceMissing() throws {
        self.runInvalidResponseTest(activationID: "12345",
                                    device: nil,
                                    subscription: [
                                        "id": "abcde",
                                        "name": "Annual Subscription",
                                        "expirationTimestamp": 654_321_000,
                                        "renewalStatus": "renew",
                                    ])
    }

    func test_init_throwsInvalidResponseIfDeviceNameMissing() throws {
        self.runInvalidResponseTest(activationID: "12345",
                                    device: ["foobar": "My Machine"],
                                    subscription: [
                                        "id": "abcde",
                                        "name": "Annual Subscription",
                                        "expirationTimestamp": 654_321_000,
                                        "renewalStatus": "renew",
                                    ])
    }

    func test_init_throwsInvalidResponseIfSubscriptionMissing() throws {
        self.runInvalidResponseTest(activationID: "12345",
                                    device: ["name": "My Machine"],
                                    subscription: nil)
    }

    func test_init_throwsInvalidResponseIfSubscriptionIDMissing() throws {
        self.runInvalidResponseTest(activationID: "12345",
                                    device: ["name": "My Machine"],
                                    subscription: [
                                        "name": "Annual Subscription",
                                        "expirationTimestamp": 654_321_000,
                                        "renewalStatus": "renew",
                                    ])
    }

    func test_init_throwsInvalidResponseIfSubscriptionNameMissing() throws {
        self.runInvalidResponseTest(activationID: "12345",
                                    device: ["name": "My Machine"],
                                    subscription: [
                                        "id": "abcde",
                                        "expirationTimestamp": 654_321_000,
                                        "renewalStatus": "renew",
                                    ])
    }

    func test_init_throwsInvalidResponseIfSubscriptionExpirationTimestampMissing() throws {
        self.runInvalidResponseTest(activationID: "12345",
                                    device: ["name": "My Machine"],
                                    subscription: [
                                        "id": "abcde",
                                        "name": "Annual Subscription",
                                        "renewalStatus": "renew",
                                    ])
    }

    func test_init_throwsInvalidResponseIfSubscriptionRenewalStatusMissing() throws {
        self.runInvalidResponseTest(activationID: "12345",
                                    device: ["name": "My Machine"],
                                    subscription: [
                                        "id": "abcde",
                                        "name": "Annual Subscription",
                                        "expirationTimestamp": 654_321_000,
                                    ])
    }

    func test_init_returnsActivationIfAllFieldsExist() throws {
        let subscription: [String: Any] = [
            "id": "abcde",
            "name": "Annual Subscription",
            "expirationTimestamp": 654_321_000,
            "renewalStatus": "renew",
        ]
        let activation = try createActivation(activationID: "12345",
                                              device: ["name": "My Machine"],
                                              subscription: subscription)
        XCTAssertEqual(activation.activationID, "12345")
        XCTAssertEqual(activation.deviceName, "My Machine")
        XCTAssertEqual(activation.subscription.id, "abcde")
        XCTAssertEqual(activation.subscription.name, "Annual Subscription")
        XCTAssertEqual(activation.subscription.expirationTimestamp, 654_321_000)
        XCTAssertEqual(activation.subscription.renewalStatus, .renew)
    }


    //MARK: - Helper
    private func runInvalidResponseTest(activationID: String?,
                                        device: [String: String]?,
                                        subscription: [String: Any]?) {
        XCTAssertThrowsError(try self.createActivation(activationID: activationID, device: device, subscription: subscription)) { error in
            guard
                let v2Error = error as? API.V2.Error,
                case .invalidResponse = v2Error
            else {
                XCTFail("\(error) is not equal to .invalidResponse")
                return
            }
        }
    }

    private func createActivation(activationID: String?,
                                  device: [String: String]?,
                                  subscription: [String: Any]?) throws -> API.V2.Activation {
        var payload: [String: Any] = ["response": "success"]
        if let activationID {
            payload["activationID"] = activationID
        }
        if let device {
            payload["device"] = device
        }
        if let subscription {
            payload["subscription"] = subscription
        }

        let apiData = try XCTUnwrap(APIData(json: [
            "payload": payload,
            "signature": try Self.signature(forPayload: payload),
        ]))
        return try API.V2.Activation(apiData: apiData)
    }
}
