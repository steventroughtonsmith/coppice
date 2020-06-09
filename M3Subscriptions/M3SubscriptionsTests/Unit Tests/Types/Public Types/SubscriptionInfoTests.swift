//
//  SubscriptionInfoTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 09/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class SubscriptionInfoTests: XCTestCase {

    func test_init_returnsNilIfResponseIsMissing() throws {
        let payload: [String: Any] = [
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        XCTAssertNil(SubscriptionInfo(payload: payload))
    }

    func test_init_returnsNilIfResponseIsNotString() throws {
        let payload: [String: Any] = [
            "response": 13,
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        XCTAssertNil(SubscriptionInfo(payload: payload))
    }

    func test_init_returnsNilIfSubscriptionNameIsMissing() throws {
        let payload: [String: Any] = [
            "response": "foo",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        XCTAssertNil(SubscriptionInfo(payload: payload))
    }

    func test_init_returnsNilIfSubscriptionNameIsNotString() throws {
        let payload: [String: Any] = [
            "response": "foo",
            "subscriptionName": 19251212512,
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        XCTAssertNil(SubscriptionInfo(payload: payload))
    }

    func test_init_returnsNilIfExpirationDateIsMissing() throws {
        let payload: [String: Any] = [
            "response": "foo",
            "subscriptionName": "My Subscription Plan",
        ]
        XCTAssertNil(SubscriptionInfo(payload: payload))
    }

    func test_init_returnsNilIfExpirationDateIsNotString() throws {
        let payload: [String: Any] = [
            "response": "foo",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": 2000
        ]
        XCTAssertNil(SubscriptionInfo(payload: payload))
    }

    func test_init_returnsNilIfExpirationDateIsNotISO8601Date() throws {
        let payload: [String: Any] = [
            "response": "foo",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "Not a date!"
        ]
        XCTAssertNil(SubscriptionInfo(payload: payload))
    }

    func test_init_returnsSubscriptionInfoWithCorrectProperties() throws {
        let payload: [String: Any] = [
            "response": "foo",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let info = try XCTUnwrap(SubscriptionInfo(payload: payload))
        XCTAssertEqual(info.state, .unknown)

        let subscription = try XCTUnwrap(info.subscription)
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
        let info = try XCTUnwrap(SubscriptionInfo(payload: payload))
        XCTAssertEqual(info.state, .active)
    }

    func test_state_setsStateTo_billingFailed_ifResponseIs_billing_failed() throws {
        let payload: [String: Any] = [
            "response": "billing_failed",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let info = try XCTUnwrap(SubscriptionInfo(payload: payload))
        XCTAssertEqual(info.state, .billingFailed)
    }

    func test_state_setsStateTo_deactivated_ifResponseIs_deactivated() throws {
        let payload: [String: Any] = [
            "response": "deactivated",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let info = try XCTUnwrap(SubscriptionInfo(payload: payload))
        XCTAssertEqual(info.state, .deactivated)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_no_device_found() throws {
        let payload: [String: Any] = [
            "response": "no_device_found",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let info = try XCTUnwrap(SubscriptionInfo(payload: payload))
        XCTAssertEqual(info.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_subscription_expired() throws {
        let payload: [String: Any] = [
            "response": "expired",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let info = try XCTUnwrap(SubscriptionInfo(payload: payload))
        XCTAssertEqual(info.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_no_subscription_found() throws {
        let payload: [String: Any] = [
            "response": "no_subscription_found",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let info = try XCTUnwrap(SubscriptionInfo(payload: payload))
        XCTAssertEqual(info.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_multiple_subscriptions() throws {
        let payload: [String: Any] = [
            "response": "multiple_subscriptions",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let info = try XCTUnwrap(SubscriptionInfo(payload: payload))
        XCTAssertEqual(info.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_login_failed() throws {
        let payload: [String: Any] = [
            "response": "login_failed",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let info = try XCTUnwrap(SubscriptionInfo(payload: payload))
        XCTAssertEqual(info.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIsSomeRandomText() throws {
        let payload: [String: Any] = [
            "response": "the quick brown fox jumped over the lazy dog",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let info = try XCTUnwrap(SubscriptionInfo(payload: payload))
        XCTAssertEqual(info.state, .unknown)
    }
}
