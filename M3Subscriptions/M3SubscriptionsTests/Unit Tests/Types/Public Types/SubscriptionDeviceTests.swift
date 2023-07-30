//
//  SubscriptionDeviceTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 09/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

extension API.V1 {
    class SubscriptionDeviceTests: XCTestCase {
        func test_init_returnsNilIfDeactivationTokenIsMissing() throws {
            let payload: [String: Any] = [
                "name": "My Favourite Mac",
                "activationDate": "1999-08-07T06:05:04Z",
            ]
            XCTAssertNil(SubscriptionDevice(payload: payload))
        }

        func test_init_returnsNilIfDeactivationTokenIsNotString() throws {
            let payload: [String: Any] = [
                "deactivationToken": 54,
                "name": "My Favourite Mac",
                "activationDate": "1999-08-07T06:05:04Z",
            ]
            XCTAssertNil(SubscriptionDevice(payload: payload))
        }

        func test_init_returnsNilIfNameIsMissing() throws {
            let payload: [String: Any] = [
                "deactivationToken": "token-to-deactivate",
                "activationDate": "1999-08-07T06:05:04Z",
            ]
            XCTAssertNil(SubscriptionDevice(payload: payload))
        }

        func test_init_returnsNilIfNameIsNotString() throws {
            let payload: [String: Any] = [
                "deactivationToken": "token-to-deactivate",
                "name": 999,
                "activationDate": "1999-08-07T06:05:04Z",
            ]
            XCTAssertNil(SubscriptionDevice(payload: payload))
        }

        func test_init_returnsNilIfActivationDateIsMissing() throws {
            let payload: [String: Any] = [
                "deactivationToken": "token-to-deactivate",
                "name": "My Favourite Mac",
            ]
            XCTAssertNil(SubscriptionDevice(payload: payload))
        }

        func test_init_returnsNilIfActivationDateIsNotString() throws {
            let payload: [String: Any] = [
                "deactivationToken": "token-to-deactivate",
                "name": "My Favourite Mac",
                "activationDate": 912,
            ]
            XCTAssertNil(SubscriptionDevice(payload: payload))
        }

        func test_init_returnsNilIfActivationDateIsNotISO8601() throws {
            let payload: [String: Any] = [
                "deactivationToken": "token-to-deactivate",
                "name": "My Favourite Mac",
                "activationDate": "WAT?!",
            ]
            XCTAssertNil(SubscriptionDevice(payload: payload))
        }

        func test_init_createSubscriptionDeviceWithCorrectProperties() throws {
            let payload: [String: Any] = [
                "deactivationToken": "token-to-deactivate",
                "name": "My Favourite Mac",
                "activationDate": "1999-08-07T06:05:04Z",
            ]
            let device = try XCTUnwrap(SubscriptionDevice(payload: payload))
            XCTAssertEqual(device.deactivationToken, "token-to-deactivate")
            XCTAssertEqual(device.name, "My Favourite Mac")

            XCTAssertDateEquals(device.activationDate, 1999, 8, 7, 6, 5, 4)
        }
    }
}
