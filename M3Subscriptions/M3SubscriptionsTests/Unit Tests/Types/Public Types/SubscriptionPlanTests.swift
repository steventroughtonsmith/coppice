//
//  SubscriptionPlanTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class SubscriptionPlanTests: XCTestCase {

    func test_init_returnsNilIfIDIsMissing() throws {
        let payload: [String: Any] = [
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2
        ]
        XCTAssertNil(SubscriptionPlan(payload: payload))
    }

    func test_init_returnsNilIfIDIsNotString() throws {
        let payload: [String: Any] = [
            "id": 42,
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2
        ]
        XCTAssertNil(SubscriptionPlan(payload: payload))
    }

    func test_init_returnsNilIfNameIsMissing() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2
        ]
        XCTAssertNil(SubscriptionPlan(payload: payload))
    }

    func test_init_returnsNilIfNameIsNotString() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": 31,
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2
        ]
        XCTAssertNil(SubscriptionPlan(payload: payload))
    }

    func test_init_returnsNilIfExpirationDateIsMissing() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2
        ]
        XCTAssertNil(SubscriptionPlan(payload: payload))
    }

    func test_init_returnsNilIfExpirationDateIsNotString() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": 1931,
            "maxDeviceCount": 4,
            "currentDeviceCount": 2
        ]
        XCTAssertNil(SubscriptionPlan(payload: payload))
    }

    func test_init_returnsNilIfExpirationDateIsNotISO8601Date() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": "Hello World!",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2
        ]
        XCTAssertNil(SubscriptionPlan(payload: payload))
    }

    func test_init_returnsNilIfMaxDeviceCountisMissing() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "currentDeviceCount": 2
        ]
        XCTAssertNil(SubscriptionPlan(payload: payload))
    }

    func test_init_returnsNilIfMaxDeviceCountIsNotInteger() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": "16",
            "currentDeviceCount": 2
        ]
        XCTAssertNil(SubscriptionPlan(payload: payload))
    }

    func test_init_returnsNilIfCurrentDeviceCountIsMissing() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
        ]
        XCTAssertNil(SubscriptionPlan(payload: payload))
    }

    func test_init_returnsNilIfCurrentDeviceCountIsNotInteger() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
            "currentDeviceCount": "Possum"
        ]
        XCTAssertNil(SubscriptionPlan(payload: payload))
    }

    func test_init_createsSubscriptionPlanWithCorrectProperties() throws {
        let payload: [String: Any] = [
            "id": "planID",
            "name": "Plan B",
            "expirationDate": "2019-11-10T09:08:07Z",
            "maxDeviceCount": 4,
            "currentDeviceCount": 2
        ]
        let subscription = try XCTUnwrap(SubscriptionPlan(payload: payload))

        XCTAssertEqual(subscription.id, "planID")
        XCTAssertEqual(subscription.name, "Plan B")
        XCTAssertEqual(subscription.maxDeviceCount, 4)
        XCTAssertEqual(subscription.currentDeviceCount, 2)

        let components = NSCalendar(calendarIdentifier: .ISO8601)?.components([.year, .month, .day, .hour, .minute, .second], from: subscription.expirationDate)
        XCTAssertEqual(components?.year, 2019)
        XCTAssertEqual(components?.month, 11)
        XCTAssertEqual(components?.day, 10)
        XCTAssertEqual(components?.hour, 9)
        XCTAssertEqual(components?.minute, 8)
        XCTAssertEqual(components?.second, 7)
    }

}
