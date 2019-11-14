//
//  CanvasPageTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class CanvasPageTests: XCTestCase {

    override func setUp() {
        super.setUp()

    }

    func test_plistRepresentation_containsID() throws {
        let canvasPage = CanvasPage()
        let id = try XCTUnwrap(canvasPage.plistRepresentation["id"] as? String)
        XCTAssertEqual(id, canvasPage.id.stringRepresentation)
    }

    func test_plistRepresentation_containsFrame() throws {
        let canvasPage = CanvasPage()
        canvasPage.frame = CGRect(x: 20, y: 30, width: 40, height: 50)
        let frame = try XCTUnwrap(canvasPage.plistRepresentation["frame"] as? String)
        XCTAssertEqual(frame, NSStringFromRect(CGRect(x: 20, y: 30, width: 40, height: 50)))
    }

    func test_plistRepresentation_containsPageID() throws {
        let page = Page()
        let canvasPage = CanvasPage()
        canvasPage.page = page
        let pageID = try XCTUnwrap(canvasPage.plistRepresentation["page"] as? String)
        XCTAssertEqual(pageID, page.id.stringRepresentation)
    }

    func test_plistRepresentation_containsCanvasID() throws {
        let canvas = Canvas()
        let canvasPage = CanvasPage()
        canvasPage.canvas = canvas
        let canvasID = try XCTUnwrap(canvasPage.plistRepresentation["canvas"] as? String)
        XCTAssertEqual(canvasID, canvas.id.stringRepresentation)
    }

    func test_plistRepresentation_containsParentID() throws {
        let parent = CanvasPage()
        let canvasPage = CanvasPage()
        canvasPage.parent = parent
        let parentID = try XCTUnwrap(canvasPage.plistRepresentation["parent"] as? String)
        XCTAssertEqual(parentID, parent.id.stringRepresentation)
    }


    //MARK: - update(fromPlistRepresentation:)
    func test_updateFromPlistRepresentation_throwsErrorIfModelControllerNotSet() {
        let canvasPage = CanvasPage()
        XCTAssertThrowsError(try canvasPage.update(fromPlistRepresentation: [:]), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .modelControllerNotSet)
        }
    }

    func test_updateFromPlistRepresentation_doesntUpdateIfIDsDontMatch() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        let newPage = modelController.collection(for: Page.self).newObject()
        let newCanvas = modelController.collection(for: Canvas.self).newObject()
        let parent = modelController.collection(for: CanvasPage.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [String: Any] = [
            "id": "foobar",
            "frame": NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            "page": newPage.id.stringRepresentation,
            "canvas": newCanvas.id.stringRepresentation,
            "canvasPage": parent.id.stringRepresentation
        ]

        XCTAssertThrowsError(try canvasPage.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), ModelObjectUpdateErrors.idsDontMatch)
        }
    }

    func test_updateFromPlistRepresentation_updatesFrame() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [String: Any] = [
            "id": canvasPage.id.stringRepresentation,
            "frame": NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvasPage.frame, CGRect(x: 1, y: 2, width: 3, height: 4))
    }

    func test_updateFromPlistRepresentation_updatesPage() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        modelController.collection(for: Page.self).newObject() //Separate test page
        let newPage = modelController.collection(for: Page.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [String: Any] = [
            "id": canvasPage.id.stringRepresentation,
            "frame": NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            "page": newPage.id.stringRepresentation,
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvasPage.page, newPage)
    }

    func test_updateFromPlistRepresentation_updatesCanvas() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        modelController.collection(for: Canvas.self).newObject() //Separate test page
        let newCanvas = modelController.collection(for: Canvas.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [String: Any] = [
            "id": canvasPage.id.stringRepresentation,
            "frame": NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            "canvas": newCanvas.id.stringRepresentation,
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvasPage.canvas, newCanvas)
    }

    func test_updateFromPlistRepresentation_updatesParent() {
        let modelController = BubblesModelController(undoManager: UndoManager())

        modelController.collection(for: CanvasPage.self).newObject() //Separate test page
        let parent = modelController.collection(for: CanvasPage.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [String: Any] = [
            "id": canvasPage.id.stringRepresentation,
            "frame": NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            "parent": parent.id.stringRepresentation,
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvasPage.parent, parent)
    }
}
