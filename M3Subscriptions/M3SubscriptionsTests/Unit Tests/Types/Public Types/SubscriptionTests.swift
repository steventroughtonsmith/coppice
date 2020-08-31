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
    func test_init_returnsNilIfNameIsMissing() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "expirationDate": "2019-11-10T09:08:07Z",
            "renewalStatus": "renew",
        ]
        XCTAssertNil(Subscription(payload: payload, hasExpired: false))
    }

    func test_init_returnsNilIfNameIsNotString() throws {
        let payload: [String: Any] = [
            "name": 31,
            "expirationDate": "2019-11-10T09:08:07Z",
            "renewalStatus": "renew"
        ]
        XCTAssertNil(Subscription(payload: payload, hasExpired: false))
    }

    func test_init_returnsNilIfExpirationDateIsMissing() throws {
        let payload: [String: Any] = [
            "name": "Plan B",
            "renewalStatus": "renew"
        ]
        XCTAssertNil(Subscription(payload: payload, hasExpired: false))
    }

    func test_init_returnsNilIfExpirationDateIsNotString() throws {
        let payload: [String: Any] = [
            "name": "Plan B",
            "expirationDate": 1931,
            "renewalStatus": "renew"
        ]
        XCTAssertNil(Subscription(payload: payload, hasExpired: false))
    }

    func test_init_returnsNilIfExpirationDateIsNotISO8601Date() throws {
        let payload: [String: Any] = [
            "name": "Plan B",
            "expirationDate": "Hello World!",
            "renewalStatus": "renew"
        ]
        XCTAssertNil(Subscription(payload: payload, hasExpired: false))
    }

    func test_init_returnsNilIfRenewalStatusIsMissing() throws {
        let payload: [String: Any] = [
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
        ]
        XCTAssertNil(Subscription(payload: payload, hasExpired: false))
    }

    func test_init_returnsNilIfRenewalStatusIsNotString() throws {
        let payload: [String: Any] = [
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "renewalStatus": 5
        ]
        XCTAssertNil(Subscription(payload: payload, hasExpired: false))
    }

    func test_init_createsSubscriptionWithCorrectProperties() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2,
            "renewalStatus": "renew",
        ]
        let subscription = try XCTUnwrap(Subscription(payload: payload, hasExpired: false))

        XCTAssertEqual(subscription.id, "planID")
        XCTAssertEqual(subscription.name, "Plan B")
        XCTAssertEqual(subscription.maxDeviceCount, 4)
        XCTAssertEqual(subscription.currentDeviceCount, 2)
        XCTAssertEqual(subscription.renewalStatus, .renew)

        let components = NSCalendar(calendarIdentifier: .ISO8601)?.components([.year, .month, .day, .hour, .minute, .second], from: subscription.expirationDate)
        XCTAssertEqual(components?.year, 2019)
        XCTAssertEqual(components?.month, 11)
        XCTAssertEqual(components?.day, 10)
        XCTAssertEqual(components?.hour, 9)
        XCTAssertEqual(components?.minute, 8)
        XCTAssertEqual(components?.second, 7)
    }

    func test_init_createsSubscriptionWithNilDeviceCountsIfNotSupplied() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "renewalStatus": "renew",
        ]
        let subscription = try XCTUnwrap(Subscription(payload: payload, hasExpired: false))

        XCTAssertEqual(subscription.id, "planID")
        XCTAssertEqual(subscription.name, "Plan B")
        XCTAssertNil(subscription.maxDeviceCount)
        XCTAssertNil(subscription.currentDeviceCount)
        XCTAssertEqual(subscription.renewalStatus, .renew)

        let components = NSCalendar(calendarIdentifier: .ISO8601)?.components([.year, .month, .day, .hour, .minute, .second], from: subscription.expirationDate)
        XCTAssertEqual(components?.year, 2019)
        XCTAssertEqual(components?.month, 11)
        XCTAssertEqual(components?.day, 10)
        XCTAssertEqual(components?.hour, 9)
        XCTAssertEqual(components?.minute, 8)
        XCTAssertEqual(components?.second, 7)
    }

    func test_init_createsSubscriptionWithNilIDIfNotSupplied() throws {
        let payload: [String: Any] = [
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2,
            "renewalStatus": "renew",
        ]
        let subscription = try XCTUnwrap(Subscription(payload: payload, hasExpired: false))

        XCTAssertNil(subscription.id)
        XCTAssertEqual(subscription.name, "Plan B")
        XCTAssertEqual(subscription.maxDeviceCount, 4)
        XCTAssertEqual(subscription.currentDeviceCount, 2)
        XCTAssertEqual(subscription.renewalStatus, .renew)

        let components = NSCalendar(calendarIdentifier: .ISO8601)?.components([.year, .month, .day, .hour, .minute, .second], from: subscription.expirationDate)
        XCTAssertEqual(components?.year, 2019)
        XCTAssertEqual(components?.month, 11)
        XCTAssertEqual(components?.day, 10)
        XCTAssertEqual(components?.hour, 9)
        XCTAssertEqual(components?.minute, 8)
        XCTAssertEqual(components?.second, 7)
    }

    func test_init_createsSubscriptionWithFailedRenewalStatus() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2,
            "renewalStatus": "failed",
        ]
        let subscription = try XCTUnwrap(Subscription(payload: payload, hasExpired: false))

        XCTAssertEqual(subscription.id, "planID")
        XCTAssertEqual(subscription.name, "Plan B")
        XCTAssertEqual(subscription.maxDeviceCount, 4)
        XCTAssertEqual(subscription.currentDeviceCount, 2)
        XCTAssertEqual(subscription.renewalStatus, .failed)

        let components = NSCalendar(calendarIdentifier: .ISO8601)?.components([.year, .month, .day, .hour, .minute, .second], from: subscription.expirationDate)
        XCTAssertEqual(components?.year, 2019)
        XCTAssertEqual(components?.month, 11)
        XCTAssertEqual(components?.day, 10)
        XCTAssertEqual(components?.hour, 9)
        XCTAssertEqual(components?.minute, 8)
        XCTAssertEqual(components?.second, 7)
    }

    func test_init_createsSubscriptionWithCancelledRenewalStatus() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2,
            "renewalStatus": "cancelled",
        ]
        let subscription = try XCTUnwrap(Subscription(payload: payload, hasExpired: false))

        XCTAssertEqual(subscription.id, "planID")
        XCTAssertEqual(subscription.name, "Plan B")
        XCTAssertEqual(subscription.maxDeviceCount, 4)
        XCTAssertEqual(subscription.currentDeviceCount, 2)
        XCTAssertEqual(subscription.renewalStatus, .cancelled)

        let components = NSCalendar(calendarIdentifier: .ISO8601)?.components([.year, .month, .day, .hour, .minute, .second], from: subscription.expirationDate)
        XCTAssertEqual(components?.year, 2019)
        XCTAssertEqual(components?.month, 11)
        XCTAssertEqual(components?.day, 10)
        XCTAssertEqual(components?.hour, 9)
        XCTAssertEqual(components?.minute, 8)
        XCTAssertEqual(components?.second, 7)
    }

    func test_init_createsSubscriptionWithUnknownRenewalStatus() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2,
            "renewalStatus": "possum!",
        ]
        let subscription = try XCTUnwrap(Subscription(payload: payload, hasExpired: false))

        XCTAssertEqual(subscription.id, "planID")
        XCTAssertEqual(subscription.name, "Plan B")
        XCTAssertEqual(subscription.maxDeviceCount, 4)
        XCTAssertEqual(subscription.currentDeviceCount, 2)
        XCTAssertEqual(subscription.renewalStatus, .unknown)

        let components = NSCalendar(calendarIdentifier: .ISO8601)?.components([.year, .month, .day, .hour, .minute, .second], from: subscription.expirationDate)
        XCTAssertEqual(components?.year, 2019)
        XCTAssertEqual(components?.month, 11)
        XCTAssertEqual(components?.day, 10)
        XCTAssertEqual(components?.hour, 9)
        XCTAssertEqual(components?.minute, 8)
        XCTAssertEqual(components?.second, 7)
    }
}
