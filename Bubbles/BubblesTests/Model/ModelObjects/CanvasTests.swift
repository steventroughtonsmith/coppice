//
//  CanvasTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class CanvasTests: XCTestCase {

    func test_plistRepresentation_containsID() throws {
        let canvas = Canvas()
        let plist = canvas.plistRepresentation
        let id = try XCTUnwrap(plist["id"] as? String)
        XCTAssertEqual(id, canvas.id.stringRepresentation)
    }

    func test_plistRepresentation_containsTitle() throws {
        let canvas = Canvas()
        canvas.title = "Hello World"
        let plist = canvas.plistRepresentation
        let title = try XCTUnwrap(plist["title"] as? String)
        XCTAssertEqual(title, "Hello World")
    }

    func test_plistRepresentation_containsDateCreated() throws {
        let canvas = Canvas()
        canvas.dateCreated = Date(timeIntervalSinceReferenceDate: 1000)
        let plist = canvas.plistRepresentation
        let date = try XCTUnwrap(plist["dateCreated"] as? Date)
        XCTAssertEqual(date, Date(timeIntervalSinceReferenceDate: 1000))
    }

    func test_plistRepresentation_containsDateModified() throws {
        let canvas = Canvas()
        canvas.dateModified = Date(timeIntervalSinceReferenceDate: 42)
        let plist = canvas.plistRepresentation
        let date = try XCTUnwrap(plist["dateModified"] as? Date)
        XCTAssertEqual(date, Date(timeIntervalSinceReferenceDate: 42))
    }

    func test_plistRepresentation_containsSortIndex() throws {
        let canvas = Canvas()
        canvas.sortIndex = 4
        let plist = canvas.plistRepresentation
        let sortIndex = try XCTUnwrap(plist["sortIndex"] as? Int)
        XCTAssertEqual(sortIndex, 4)
    }

    func test_plistRepresentation_containsViewPortIfSet() throws {
        let canvas = Canvas()
        canvas.viewPort = CGRect(x: 1, y: 2, width: 30, height: 40)
        let plist = canvas.plistRepresentation
        let viewPort = try XCTUnwrap(plist["viewPort"] as? String)
        XCTAssertEqual(viewPort, NSStringFromRect(CGRect(x: 1, y: 2, width: 30, height: 40)))
    }

    func test_plistRepresentation_doesntContainViewPortIfNotSet() {
        let canvas = Canvas()
        canvas.viewPort = nil
        let plist = canvas.plistRepresentation
        XCTAssertNil(plist["viewPort"])
    }


    //MARK: - Update
    func test_updateFromPlistRepresentation_doesntUpdateIfIDsDontMatch() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": "baz",
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 30),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1453),
            "sortIndex": 5
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .idsDontMatch)
        }
    }

    func test_updateFromPlistRepresentation_updatesTitle() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 31),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1454),
            "sortIndex": 4
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.title, "Hello Bar")
    }

    func test_updateFromPlistRepresentation_throwsIfTitleMissing() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "dateCreated": Date(timeIntervalSinceReferenceDate: 30),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1453),
            "sortIndex": 5
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("title"))
        }
    }

    func test_updateFromPlistRepresentation_updatesDateCreated() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 3
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.dateCreated, Date(timeIntervalSinceReferenceDate: 32))
    }

    func test_updateFromPlistRepresentation_throwsIfDateCreatedMissing() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateModified": Date(timeIntervalSinceReferenceDate: 1453),
            "sortIndex": 5
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("dateCreated"))
        }
    }

    func test_updateFromPlistRepresentation_updatesDateModified() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 33),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1456),
            "sortIndex": 2
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.dateModified, Date(timeIntervalSinceReferenceDate: 1456))
    }

    func test_updateFromPlistRepresentation_throwsIfDateModifiedMissing() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 30),
            "sortIndex": 5
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("dateModified"))
        }
    }

    func test_updateFromPlistRepresentation_updatesSortIndex() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.sortIndex, 1)
    }

    func test_updateFromPlistRepresentation_throwsIfSortIndexMissing() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 30),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1453),
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("sortIndex"))
        }
    }

    func test_updateFromPlistRepresentation_updatesViewPortIfInPlist() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "viewPort": NSStringFromRect(CGRect(x: 9, y: 8, width: 7, height: 6))
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.viewPort, CGRect(x: 9, y: 8, width: 7, height: 6))
    }

    func test_updateFromPlistRepresentation_setsViewPortToNilIfNotInPlist() {
        let canvas = Canvas()
        canvas.viewPort = CGRect(x: 99, y: 88, width: 77, height: 66)
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertNil(canvas.viewPort)
    }
}
