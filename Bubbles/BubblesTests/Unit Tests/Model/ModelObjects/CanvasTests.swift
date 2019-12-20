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


    //MARK: - objectWasInserted()
    func test_objectWasInserted_updatesSortIndexAfterInsertingInCollection() {
        let canvasCollection = ModelCollection<Canvas>()
        XCTAssertEqual(canvasCollection.newObject().sortIndex, 1)
        XCTAssertEqual(canvasCollection.newObject().sortIndex, 2)
        XCTAssertEqual(canvasCollection.newObject().sortIndex, 3)
        XCTAssertEqual(canvasCollection.newObject().sortIndex, 4)
    }


    //MARK: - add(_:linkedFrom:centredOn:)
    func test_addPage_createsANewCanvasPageWithSuppliedPage() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = modelController.collection(for: Canvas.self).newObject()
        let page = modelController.collection(for: Page.self).newObject() {
            $0.contentSize = CGSize(width: 20, height: 20)
        }

        let canvasPage = canvas.add(page)
        XCTAssertEqual(canvasPage.page, page)
        XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(canvasPage))
    }

    func test_addPage_createsANewCanvasPageWithSourcePageAsParent() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let sourcePage = modelController.collection(for: CanvasPage.self).newObject()
        let canvas = modelController.collection(for: Canvas.self).newObject()
        let page = modelController.collection(for: Page.self).newObject() {
            $0.contentSize = CGSize(width: 20, height: 20)
        }

        let canvasPage = canvas.add(page, linkedFrom: sourcePage)
        XCTAssertEqual(canvasPage.parent, sourcePage)
    }

    func test_addPage_centresCanvasPageOnViewPortIfNoPointSupplied() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = modelController.collection(for: Canvas.self).newObject() {
            $0.viewPort = CGRect(x: 40, y: 40, width: 100, height: 100)
        }
        let page = modelController.collection(for: Page.self).newObject() {
            $0.contentSize = CGSize(width: 20, height: 20)
        }

        let canvasPage = canvas.add(page)
        XCTAssertEqual(canvasPage.frame, CGRect(x: 80, y: 80, width: 20, height: 20))
    }

    func test_addPage_centresCanvasPageOnSuppliedPoint() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = modelController.collection(for: Canvas.self).newObject() {
            $0.viewPort = CGRect(x: 40, y: 40, width: 100, height: 100)
        }
        let page = modelController.collection(for: Page.self).newObject() {
            $0.contentSize = CGSize(width: 20, height: 20)
        }

        let canvasPage = canvas.add(page, centredOn: CGPoint(x: 60, y: 30))
        XCTAssertEqual(canvasPage.frame, CGRect(x: 50, y: 20, width: 20, height: 20))
    }


    //MARK: - isMatchForSearch(_:)
    func test_isMatchForSearch_returnsTrueForNilSearchTerm() {
        let canvas = Canvas()
        canvas.title = "Hello"
        XCTAssertTrue(canvas.isMatchForSearch(nil))
    }

    func test_isMatchForSearch_returnsTrueForEmptySearchTerm() {
        let canvas = Canvas()
        canvas.title = "Hello"
        XCTAssertTrue(canvas.isMatchForSearch(""))
    }

    func test_isMatchForSearch_returnsTrueIfTitleIsSearchTerm() {
        let canvas = Canvas()
        canvas.title = "Hello World"
        XCTAssertTrue(canvas.isMatchForSearch("Hello World"))
    }

    func test_isMatchForSearch_returnsTrueIfTitleContainsSearchTerm() {
        let canvas = Canvas()
        canvas.title = "Foo Bar Baz"
        XCTAssertTrue(canvas.isMatchForSearch("Bar B"))
    }

    func test_isMatchForSearch_returnsTrueIfTitleContainsSearchTermIgnoringCase() {
        let canvas = Canvas()
        canvas.title = "I am SHOUTING loudly"
        XCTAssertTrue(canvas.isMatchForSearch("shouting"))
    }

    func test_isMatchForSearch_returnsTrueIfAnyPagesOnCanvasMatchSearchTerm() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let canvas = Canvas.create(in: modelController)
        canvas.title = "test"

        let matchingPage = Page.create(in: modelController) {
            $0.title = "This is a matching page"
        }
        canvas.add(matchingPage)

        let nonMatchingPage = Page.create(in: modelController) {
            $0.title = "This doesnt affect the outcome"
        }
        canvas.add(nonMatchingPage)

        XCTAssertTrue(canvas.isMatchForSearch("matching"))
    }

    func test_isMatchForSearch_returnsFalseIfTitleAndNoPagesMatchSearchTerm() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let canvas = Canvas.create(in: modelController)
        canvas.title = "test"

        let page1 = Page.create(in: modelController) {
            $0.title = "This page doesnt match"
        }
        canvas.add(page1)

        let page2 = Page.create(in: modelController) {
            $0.title = "Neither does this"
        }
        canvas.add(page2)

        XCTAssertFalse(canvas.isMatchForSearch("POSSUM"))
    }
}
