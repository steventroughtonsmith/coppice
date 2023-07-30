//
//  DeviceTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

class Mac_DeviceTests: XCTestCase {
    func test_type_isMac() throws {
        let device = Device()
        XCTAssertEqual(device.type, .mac)
    }

    func test_id_isAUUID() throws {
        let device = Device()
        let id = device.id
        let uuid = UUID(uuidString: id)
        XCTAssertNotNil(uuid)
    }
}
