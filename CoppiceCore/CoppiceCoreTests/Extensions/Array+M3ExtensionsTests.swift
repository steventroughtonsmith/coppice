//
//  Array+M3ExtensionsTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 10/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

class Array_M3ExtensionsTests: XCTestCase {
    //MARK: - [safe:]
    func test_safe_returnsNilIfTheIndexIsEqualToTheCount() {
        let array = ["one", "two", "three"]
        XCTAssertNil(array[safe: 3])
    }

    func test_safe_returnsNilIfTheIndexIsAboveTheCount() {
        let array = ["one", "two", "three"]
        XCTAssertNil(array[safe: 4])
    }

    func test_safe_returnsElementIfIndexIsBelowTheCount() {
        let array = ["one", "two", "three"]
        XCTAssertEqual(array[safe: 1], "two")
    }


    //MARK: - .indexed(by:)
    struct TestValue: Equatable {
        let name: String
        let age: Int
    }

    func test_indexedByKeyPath_returnsDictionaryContainingAllElements() {
        let array = [
            TestValue(name: "Bob", age: 42),
            TestValue(name: "Alice", age: 31),
            TestValue(name: "Patrick", age: 12),
        ]

        let dictionary = array.indexed(by: \.name)

        XCTAssertEqual(dictionary.count, 3)
        XCTAssertTrue(dictionary.values.contains(array[0]))
        XCTAssertTrue(dictionary.values.contains(array[1]))
        XCTAssertTrue(dictionary.values.contains(array[2]))
    }

    func test_indexedByKeyPath_eachElementsKeyMatchesTheSelectedProperty() {
        let array = [
            TestValue(name: "Bob", age: 42),
            TestValue(name: "Alice", age: 31),
            TestValue(name: "Patrick", age: 12),
        ]

        let dictionary = array.indexed(by: \.name)

        XCTAssertEqual(dictionary.count, 3)
        XCTAssertEqual(dictionary["Bob"]?.name, "Bob")
        XCTAssertEqual(dictionary["Alice"]?.name, "Alice")
        XCTAssertEqual(dictionary["Patrick"]?.name, "Patrick")
    }


    //MARK: - [indexSet:]
    func test_indexSet_returnsEmptyArrayForEmptyIndexSet() {
        let array = [10, 20, 30, 40, 50, 60]
        XCTAssertEqual(array[IndexSet()].count, 0)
    }

    func test_indexSet_returnsElementsMatchingIndexesInSet() {
        let array = [10, 20, 30, 40, 50, 60]

        let results = array[IndexSet(arrayLiteral: 1, 3, 4)]
        XCTAssertEqual(results, [20, 40, 50])
    }

    func test_indexSet_ignoresIndexesBelow0() {
        let array = [10, 20, 30, 40, 50, 60]

        let results = array[IndexSet(arrayLiteral: -1, 3, 5)]
        XCTAssertEqual(results, [40, 60])
    }

    func test_indexSet_ignoresIndexesAboveOrEqualToTheCount() {
        let array = [10, 20, 30, 40, 50, 60]

        let results = array[IndexSet(arrayLiteral: 2, 3, 6)]
        XCTAssertEqual(results, [30, 40])
    }
}
