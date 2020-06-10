//
//  ActivationResponseTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 09/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class ActivationResponseTests: XCTestCase {

    func test_init_returnsNilIfResponseIsMissing() throws {
        let payload: [String: Any] = [
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        XCTAssertNil(ActivationResponse(payload: payload))
    }

    func test_init_returnsNilIfResponseIsNotString() throws {
        let payload: [String: Any] = [
            "response": 13,
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        XCTAssertNil(ActivationResponse(payload: payload))
    }

    func test_init_returnsNilIfSubscriptionNameIsMissingAndStateRequiresSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        XCTAssertNil(ActivationResponse(payload: payload))
    }

    func test_init_returnsNilIfSubscriptionNameIsNotStringAndStateRequiresSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscriptionName": 19251212512,
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        XCTAssertNil(ActivationResponse(payload: payload))
    }

    func test_init_returnsNilIfExpirationDateIsMissingAndStateRequiresSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscriptionName": "My Subscription Plan",
        ]
        XCTAssertNil(ActivationResponse(payload: payload))
    }

    func test_init_returnsNilIfExpirationDateIsNotStringAndStateRequiresSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": 2000
        ]
        XCTAssertNil(ActivationResponse(payload: payload))
    }

    func test_init_returnsNilIfExpirationDateIsNotISO8601DateAndStateRequiresSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "Not a date!"
        ]
        XCTAssertNil(ActivationResponse(payload: payload))
    }

    func test_init_returnsActivationResponseWithCorrectProperties() throws {
        let payload: [String: Any] = [
            "response": "foo",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let response = try XCTUnwrap(ActivationResponse(payload: payload))
        XCTAssertEqual(response.state, .unknown)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, "My Subscription Plan")

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


    //MARK: - .state
    func test_state_setsStateTo_active_ifResponseIs_active() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let response = try XCTUnwrap(ActivationResponse(payload: payload))
        XCTAssertEqual(response.state, .active)
    }

    func test_state_setsStateTo_billingFailed_ifResponseIs_billing_failed() throws {
        let payload: [String: Any] = [
            "response": "billing_failed",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let response = try XCTUnwrap(ActivationResponse(payload: payload))
        XCTAssertEqual(response.state, .billingFailed)
    }

    func test_state_setsStateTo_deactivated_ifResponseIs_deactivated() throws {
        let payload: [String: Any] = [
            "response": "deactivated",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let response = try XCTUnwrap(ActivationResponse(payload: payload))
        XCTAssertEqual(response.state, .deactivated)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_no_device_found() throws {
        let payload: [String: Any] = [
            "response": "no_device_found",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let response = try XCTUnwrap(ActivationResponse(payload: payload))
        XCTAssertEqual(response.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_subscription_expired() throws {
        let payload: [String: Any] = [
            "response": "expired",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let response = try XCTUnwrap(ActivationResponse(payload: payload))
        XCTAssertEqual(response.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_no_subscription_found() throws {
        let payload: [String: Any] = [
            "response": "no_subscription_found",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let response = try XCTUnwrap(ActivationResponse(payload: payload))
        XCTAssertEqual(response.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_multiple_subscriptions() throws {
        let payload: [String: Any] = [
            "response": "multiple_subscriptions",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let response = try XCTUnwrap(ActivationResponse(payload: payload))
        XCTAssertEqual(response.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_login_failed() throws {
        let payload: [String: Any] = [
            "response": "login_failed",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let response = try XCTUnwrap(ActivationResponse(payload: payload))
        XCTAssertEqual(response.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIsSomeRandomText() throws {
        let payload: [String: Any] = [
            "response": "the quick brown fox jumped over the lazy dog",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let response = try XCTUnwrap(ActivationResponse(payload: payload))
        XCTAssertEqual(response.state, .unknown)
    }
}
