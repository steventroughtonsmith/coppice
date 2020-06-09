//
//  SubscriptionTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class SubscriptionTests: XCTestCase {
    func test_returnsNilIfNoNameFound() throws {
        let payload: [String: Any] = [
            "expirationDate": "2020-03-02T00:01:03Z"
        ]

        XCTAssertNil(Subscription(payload: payload))
    }

    func test_returnsNilIfNameIsNotString() throws {
        let payload: [String: Any] = [
            "subscriptionName": 42,
            "expirationDate": "2020-03-02T00:01:03Z"
        ]

        XCTAssertNil(Subscription(payload: payload))
    }

    func test_returnsNilIfNoExpirationDateFound() throws {
        let payload: [String: Any] = [
            "subscriptionName": "Hello World"
        ]

        XCTAssertNil(Subscription(payload: payload))
    }

    func test_returnsNilIfExpirationDateIsNotString() throws {
        let payload: [String: Any] = [
            "subscriptionName": "Hello World",
            "expirationDate": 1234567
        ]

        XCTAssertNil(Subscription(payload: payload))
    }

    func test_returnsNilIfExpirationDateIsNotValidDate() throws {
        let payload: [String: Any] = [
            "subscriptionName": "Hello World",
            "expirationDate": "Foo Bar"
        ]

        XCTAssertNil(Subscription(payload: payload))
    }

    func test_returnsSubscriptionWithNameAndExpirationDate() throws {
        let payload: [String: Any] = [
            "subscriptionName": "Hello World",
            "expirationDate": "2020-03-02T02:01:03Z"
        ]

        let subscription = try XCTUnwrap(Subscription(payload: payload))
        XCTAssertEqual(subscription.name, "Hello World")

        let components = NSCalendar(calendarIdentifier: .ISO8601)?.components([.year, .month, .day, .hour, .minute, .second], from: subscription.expirationDate)
        XCTAssertEqual(components?.year, 2020)
        XCTAssertEqual(components?.month, 3)
        XCTAssertEqual(components?.day, 2)
        XCTAssertEqual(components?.hour, 2)
        XCTAssertEqual(components?.minute, 1)
        XCTAssertEqual(components?.second, 3)
    }
}
