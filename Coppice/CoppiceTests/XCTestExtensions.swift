//
//  XCTestExtensions.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 07/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest

extension XCTestCase {
    func performAndWaitFor(_ description: String, timeout seconds: TimeInterval = 1, block: (XCTestExpectation) -> Void) {
        let expectation = self.expectation(description: description)
        block(expectation)
        self.wait(for: [expectation], timeout: seconds)
    }

    var testBundle: Bundle {
        return Bundle(for: type(of: self))
    }
}


func XCTAssertDateEquals(_ date: Date, _ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int, _ calendarIdentifier: NSCalendar.Identifier = .ISO8601) {
    do {
        let calendar = try XCTUnwrap(NSCalendar(calendarIdentifier: calendarIdentifier))
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = try XCTUnwrap(calendar.components([.year, .month, .day, .hour, .minute, .second], from: date))
        XCTAssertEqual(components.year, year)
        XCTAssertEqual(components.month, month)
        XCTAssertEqual(components.day, day)
        XCTAssertEqual(components.hour, hour)
        XCTAssertEqual(components.minute, minute)
        XCTAssertEqual(components.second, second)
    } catch let e {
        XCTFail("Failed to get components: \(e)")
    }
}

