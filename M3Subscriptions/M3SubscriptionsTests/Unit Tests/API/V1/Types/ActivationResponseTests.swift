//
//  ActivationResponseTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 09/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

typealias ActivationResponse = API.V1.ActivationResponse

class ActivationResponseTests: APITestCase {
    func test_init_returnsNilIfSubscriptionIsMissingAndStateRequiresSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
        ]
        let signature = try self.signature(forPayload: payload)
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        XCTAssertNil(ActivationResponse(data: data))
    }

    func test_init_returnsActivationResponseWithCorrectPropertiesForActiveSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscription": [
                "name": "My Subscription Plan",
                "expirationDate": "2005-10-15T20:15:10Z",
                "renewalStatus": "renew",
            ],
            "device": [
                "name": "My Shiny New Mac",
            ],
            "token": "tokenX",
        ]
        let signature = try self.signature(forPayload: payload)
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)

        XCTAssertEqual(response.deviceName, "My Shiny New Mac")

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, "My Subscription Plan")
        XCTAssertEqual(subscription.renewalStatus, .renew)
        XCTAssertFalse(subscription.hasExpired)

        let calendar = NSCalendar(calendarIdentifier: .ISO8601)
        calendar?.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar?.components([.year, .month, .day, .hour, .minute, .second], from: subscription.expirationDate)
        XCTAssertEqual(components?.year, 2005)
        XCTAssertEqual(components?.month, 10)
        XCTAssertEqual(components?.day, 15)
        XCTAssertEqual(components?.hour, 20)
        XCTAssertEqual(components?.minute, 15)
        XCTAssertEqual(components?.second, 10)
    }


    //MARK: - isActive
    private func performIsActiveTest(withResponse response: String) throws -> Bool {
        let payload: [String: Any] = [
            "response": response,
            "subscription": ["name": "X", "expirationDate": "2005-10-15T20:15:10Z", "renewalStatus": "renew"],
            "device": ["name": "My Shiny New Mac"],
            "token": "tokenX",
        ]
        let signature = try self.signature(forPayload: payload)
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let activationResponse = try XCTUnwrap(ActivationResponse(data: data))
        return activationResponse.isActive
    }

    func test_isActive_returnsFalseIfResponseIsDeactivated() throws {
        XCTAssertFalse(try self.performIsActiveTest(withResponse: "deactivated"))
    }

    func test_isActive_returnsFalseIfResponseIsExpired() throws {
        XCTAssertFalse(try self.performIsActiveTest(withResponse: "expired"))
    }

    func test_isActive_returnsFalseIfResponseIsLoginFailed() throws {
        XCTAssertFalse(try self.performIsActiveTest(withResponse: "login_failed"))
    }

    func test_isActive_returnsFalseIfResponseIsMultipleSubscriptions() throws {
        XCTAssertFalse(try self.performIsActiveTest(withResponse: "multiple_subscriptions"))
    }

    func test_isActive_returnsFalseIfResponseIsNoSubscriptionFound() throws {
        XCTAssertFalse(try self.performIsActiveTest(withResponse: "no_subscription_found"))
    }

    func test_isActive_returnsFalseIfResponseIsNoDeviceFound() throws {
        XCTAssertFalse(try self.performIsActiveTest(withResponse: "no_device_found"))
    }

    func test_isActive_returnsFalseIfResponseIsTooManyDevices() throws {
        XCTAssertFalse(try self.performIsActiveTest(withResponse: "too_many_devices"))
    }

    func test_isActive_returnsFalseIfResponseIsSomeOtherValue() throws {
        XCTAssertFalse(try self.performIsActiveTest(withResponse: "foobarbaz"))
    }

    func test_isActive_returnsFalseIfResponseIsActiveButTokenIsNil() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscription": ["name": "X", "expirationDate": "2005-10-15T20:15:10Z", "renewalStatus": "renew"],
            "device": ["name": "My Shiny New Mac"],
        ]
        let signature = try self.signature(forPayload: payload)
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertFalse(response.isActive)
    }

    func test_isActive_returnsFalseIfResponseIsActiveTokenIsSetButSubscriptionHasExpired() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscription": ["name": "X", "expirationDate": "2005-10-15T20:15:10Z", "renewalStatus": "renew"],
            "device": ["name": "My Shiny New Mac"],
        ]
        let signature = try self.signature(forPayload: payload)
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        var response = try XCTUnwrap(ActivationResponse(data: data))
        response.reevaluateSubscription()
        XCTAssertFalse(response.isActive)
    }

    func test_isActive_returnsTrueIfResponseIsActiveTokenIsSetAndSubscriptionHasNotExpired() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscription": ["name": "X", "expirationDate": "2005-10-15T20:15:10Z", "renewalStatus": "renew"],
            "device": ["name": "My Shiny New Mac"],
            "token": "tokenX",
        ]
        let signature = try self.signature(forPayload: payload)
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertTrue(response.isActive)
    }
}
