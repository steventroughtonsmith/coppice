//
//  NSRange+M3ExtensionsTests.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 22/11/2021.
//

import CoppiceCore
import XCTest

class NSRange_M3ExtensionsTests: XCTestCase {
    func test_contains_returnsFalseIfOtherRangeLowerBoundLessThanLowerBound() throws {
        let baseRange = NSRange(location: 10, length: 24)
        XCTAssertFalse(baseRange.contains(NSRange(location: 5, length: 10)))
    }

    func test_contains_returnsFalseIfOtherRangeUpperBoundGreaterThanUpperBound() throws {
        let baseRange = NSRange(location: 10, length: 24)
        XCTAssertFalse(baseRange.contains(NSRange(location: 30, length: 10)))
    }

    func test_contains_returnsTrueIfOtherRangeEqualsSelf() throws {
        let baseRange = NSRange(location: 10, length: 24)
        XCTAssertTrue(baseRange.contains(NSRange(location: 10, length: 24)))
    }

    func test_contains_returnsTrueIfOtherRangeBoundsInsideSelfBounds() throws {
        let baseRange = NSRange(location: 10, length: 24)
        XCTAssertTrue(baseRange.contains(NSRange(location: 15, length: 10)))
    }
}
