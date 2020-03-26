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
            "sortIndex": 4,
            "theme": "auto",
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
            "sortIndex": 5,
            "theme": "auto",
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
            "sortIndex": 3,
            "theme": "auto",
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
            "sortIndex": 5,
            "theme": "auto",
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
            "sortIndex": 2,
            "theme": "auto",
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
            "sortIndex": 5,
            "theme": "auto",
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
            "sortIndex": 1,
            "theme": "auto",
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
            "theme": "auto",
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
            "theme": "auto",
            "viewPort": NSStringFromRect(CGRect(x: 9, y: 8, width: 7, height: 6)),
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
            "theme": "auto",
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


    //MARK: - add(_:linkedFrom:)
    func test_addPageLinkedFrom_createsNewCanvasPageWithSuppliedPageAndSetsParentAsSource() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let canvasPage = CanvasPage.create(in: modelController)

        let newCanvasPage = canvas.open(page, linkedFrom: canvasPage)
        XCTAssertEqual(newCanvasPage.page, page)
        XCTAssertEqual(newCanvasPage.parent, canvasPage)
        XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(newCanvasPage))
    }

    func test_addPageLinkedFrom_addsNewPageToRightIfNoOtherPageThere() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 30 + GlobalConstants.linkedPageOffset, y: 30, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_addsNewPageToLeftIfPageOnRightAndNoOtherPageThere() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) { $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20) }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 40, y: 20, width: 100, height: 100)
            $0.canvas = canvas
        } //Left

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 - GlobalConstants.linkedPageOffset - 20, y: 30, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_addsNewPageToBottomIfPagesOnLeftAndRightAndNoOtherPageThere() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 40, y: 20, width: 100, height: 100)
            $0.canvas = canvas
        } //Left
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -50, y: 20, width: 50, height: 20)
            $0.canvas = canvas
        } // Right

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10, y: 50 + GlobalConstants.linkedPageOffset, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_addsNewPageToTopIfPagesOnLeftRightAndBottomAndNoOtherPageThere() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 40, y: 20, width: 100, height: 100)
            $0.canvas = canvas
        } //Left
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -50, y: 20, width: 50, height: 20)
            $0.canvas = canvas
        } // Right
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 0, y: 60, width: 50, height: 40)
            $0.canvas = canvas
        } // Bottom

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10, y: 30 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_addsNewPageToRightIfPagesOnAllSides() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 40, y: 20, width: 100, height: 100)
            $0.canvas = canvas
        } //Left
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -50, y: 20, width: 50, height: 20)
            $0.canvas = canvas
        } // Right
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 0, y: 60, width: 50, height: 40)
            $0.canvas = canvas
        } // Bottom
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 0, y: -20, width: 50, height: 40)
            $0.canvas = canvas
        } // Top

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 30 + GlobalConstants.linkedPageOffset, y: 30, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_addsNewPageToLeftIfParentOfSourceSetAndOnRightAndNoOtherPageExistsThere() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let rootPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 40, y: 40, width: 20, height: 20)
            $0.canvas = canvas
        }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
            $0.parent = rootPage
        }

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: 30, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_addsNewPageToTopIfParentOfSourceSetAndOnBottomAndNoOtherPageExistsThere() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let rootPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 90, width: 20, height: 20)
            $0.canvas = canvas
        }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
            $0.parent = rootPage
        }

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10, y: 30 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_addsNewPageToBottomIfParentOfSourceSetAndOnTopAndNoOtherPageExistsThere() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let rootPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: -90, width: 20, height: 20)
            $0.canvas = canvas
        }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
            $0.parent = rootPage
        }

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10, y: 50 + GlobalConstants.linkedPageOffset, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnRightAddsAbove() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 90, y: 30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 90, y: 30 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnTopRightAddsToBottomRight() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 90, y: 30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing right child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 90, y: -30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top right child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 90, y: 50 + GlobalConstants.linkedPageOffset, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnBottomRightAddsToTopRight() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 90, y: 20, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing right child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 90, y: 80, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom right child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 90, y: 20 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnLeftAddsAbove() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -110, y: 30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: -110, y: 30 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnTopLeftAddsToBottomLeft() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -110, y: 30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing right child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -110, y: -30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top left child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: -110, y: 50 + GlobalConstants.linkedPageOffset, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnBottomLeftAddsToTopLeft() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -110, y: 20, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing right child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -110, y: 80, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom left child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: -110, y: 20 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnTopAddsToRight() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: -90, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: -90, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnTopLeftAddsToTopRight() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: -90, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -20, y: -90, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top left child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: -90, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnTopRightAddsToTopLeft() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 20, y: -90, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 60, y: -90, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top right child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 20 - GlobalConstants.linkedPageOffset - 20, y: -90, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnBottomAddsToRight() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 110, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: 110, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnBottomLeftAddsToBottomRight() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 110, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -20, y: 110, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom left child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: 110, width: 20, height: 20))
    }

    func test_addPageLinkedFrom_ifChildAlreadyExistsOnBottomRightAddsToBottomLeft() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 20, y: 110, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 60, y: 110, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom right child

        let newCanvasPage = canvas.open(page, linkedFrom: parentPage)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 20 - GlobalConstants.linkedPageOffset - 20, y: 110, width: 20, height: 20))
    }


    //MARK: - addPages(_:centredOn:)
    func test_addPagesCentredOn_createsNewCanvasPageForEachSuppliedPage() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page1 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let page2 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 30, height: 40) }
        let page3 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 50, height: 30) }

        let newCanvasPages = canvas.addPages([page1, page2, page3])
        XCTAssertEqual(newCanvasPages.count, 3)
        if let canvasPage = newCanvasPages[safe: 0] {
            XCTAssertEqual(canvasPage.page, page1)
            XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(canvasPage))
        } else {
            XCTFail()
        }

        if let canvasPage = newCanvasPages[safe: 1] {
            XCTAssertEqual(canvasPage.page, page2)
            XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(canvasPage))
        } else {
            XCTFail()
        }

        if let canvasPage = newCanvasPages[safe: 2] {
            XCTAssertEqual(canvasPage.page, page3)
            XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(canvasPage))
        } else {
            XCTFail()
        }
    }

    func test_addPagesCentredOn_centresFirstPageOnSuppliedPoint() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController) {
            $0.viewPort = CGRect(x: 40, y: 40, width: 100, height: 100)
        }
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 80, height: 90) }
        let page2 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 100, height: 50) }
        let page3 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 50, height: 120) }

        let canvasPages = canvas.addPages([page, page2, page3], centredOn: CGPoint(x: 60, y: 30))
        XCTAssertEqual(canvasPages.first?.frame, CGRect(x: 20, y: -15, width: 80, height: 90))
    }

    func test_addPagesCentredOn_centresFirstPageInViewPortIfNoPointSupplied() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController) {
            $0.viewPort = CGRect(x: 40, y: 40, width: 100, height: 100)
        }
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 80, height: 90) }
        let page2 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 100, height: 50) }
        let page3 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 50, height: 120) }

        let canvasPages = canvas.addPages([page, page2, page3])
        XCTAssertEqual(canvasPages.first?.frame, CGRect(x: 50, y: 45, width: 80, height: 90))
    }

    func test_addPagesCentredOn_stacksSubsequentPagesDownFromFirstIfGivenPoint() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController) {
            $0.viewPort = CGRect(x: 40, y: 40, width: 100, height: 100)
        }
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 80, height: 90) }
        let page2 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 100, height: 50) }
        let page3 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 50, height: 120) }

        let canvasPages = canvas.addPages([page, page2, page3], centredOn: CGPoint(x: 60, y: 30))
        XCTAssertEqual(canvasPages[safe: 1]?.frame, CGRect(x: 40, y: 5, width: 100, height: 50))
        XCTAssertEqual(canvasPages[safe: 2]?.frame, CGRect(x: 60, y: 25, width: 50, height: 120))
    }

    func test_addPagesCentredOn_stacksSubsequentPagesDownFromFirstIfNoPointSupplieds() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController) {
            $0.viewPort = CGRect(x: 40, y: 40, width: 100, height: 100)
        }
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 80, height: 90) }
        let page2 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 100, height: 50) }
        let page3 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 50, height: 120) }

        let canvasPages = canvas.addPages([page, page2, page3])
        XCTAssertEqual(canvasPages[safe: 1]?.frame, CGRect(x: 70, y: 65, width: 100, height: 50))
        XCTAssertEqual(canvasPages[safe: 2]?.frame, CGRect(x: 90, y: 85, width: 50, height: 120))
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
        canvas.addPages([matchingPage])

        let nonMatchingPage = Page.create(in: modelController) {
            $0.title = "This doesnt affect the outcome"
        }
        canvas.addPages([nonMatchingPage])

        XCTAssertTrue(canvas.isMatchForSearch("matching"))
    }

    func test_isMatchForSearch_returnsFalseIfTitleAndNoPagesMatchSearchTerm() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let canvas = Canvas.create(in: modelController)
        canvas.title = "test"

        let page1 = Page.create(in: modelController) {
            $0.title = "This page doesnt match"
        }
        canvas.addPages([page1])

        let page2 = Page.create(in: modelController) {
            $0.title = "Neither does this"
        }
        canvas.addPages([page2])

        XCTAssertFalse(canvas.isMatchForSearch("POSSUM"))
    }
}
