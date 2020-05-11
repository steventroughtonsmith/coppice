//
//  CanvasPageTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class CanvasPageTests: XCTestCase {
    var modelController: CoppiceModelController!

    override func setUp() {
        super.setUp()

        self.modelController = CoppiceModelController(undoManager: UndoManager())
    }


    //MARK: - .plistRepresentation
    func test_plistRepresentation_containsID() throws {
        let canvasPage = CanvasPage.create(in: self.modelController)
        let id = try XCTUnwrap(canvasPage.plistRepresentation["id"] as? String)
        XCTAssertEqual(id, canvasPage.id.stringRepresentation)
    }

    func test_plistRepresentation_containsFrame() throws {
        let canvasPage = CanvasPage.create(in: self.modelController)
        canvasPage.frame = CGRect(x: 20, y: 30, width: 40, height: 50)
        let frame = try XCTUnwrap(canvasPage.plistRepresentation["frame"] as? String)
        XCTAssertEqual(frame, NSStringFromRect(CGRect(x: 20, y: 30, width: 40, height: 50)))
    }

    func test_plistRepresentation_containsPageID() throws {
        let page = Page.create(in: self.modelController)
        let canvasPage = CanvasPage.create(in: self.modelController)
        canvasPage.page = page
        let pageID = try XCTUnwrap(canvasPage.plistRepresentation["page"] as? String)
        XCTAssertEqual(pageID, page.id.stringRepresentation)
    }

    func test_plistRepresentation_containsCanvasID() throws {
        let canvas = Canvas.create(in: self.modelController)
        let canvasPage = CanvasPage.create(in: self.modelController)
        canvasPage.canvas = canvas
        let canvasID = try XCTUnwrap(canvasPage.plistRepresentation["canvas"] as? String)
        XCTAssertEqual(canvasID, canvas.id.stringRepresentation)
    }

    func test_plistRepresentation_containsParentID() throws {
        let parent = CanvasPage.create(in: self.modelController)
        let canvasPage = CanvasPage.create(in: self.modelController)
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
        let modelController = CoppiceModelController(undoManager: UndoManager())

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
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [String: Any] = [
            "id": canvasPage.id.stringRepresentation,
            "frame": NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvasPage.frame, CGRect(x: 1, y: 2, width: 3, height: 4))
    }

    func test_updateFromPlistRepresentation_updatesPage() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

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
        let modelController = CoppiceModelController(undoManager: UndoManager())

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
        let modelController = CoppiceModelController(undoManager: UndoManager())

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


    //MARK: - existingCanvasPage(for:)
    func test_existingCanvasPageForPage_returnsSelfIfSuppliedPageMatchesReceiversPage() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let page = modelController.collection(for: Page.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = page
        }

        XCTAssertEqual(canvasPage.existingCanvasPage(for: page), canvasPage)
    }

    func test_existingCanvasPageForPage_returnsChildWithMatchingPageIfOneExists() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let page = modelController.collection(for: Page.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = page
        }

        let childPage = modelController.collection(for: Page.self).newObject()
        let childCanvasPage = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = childPage
            $0.parent = canvasPage
        }

        XCTAssertEqual(canvasPage.existingCanvasPage(for: childPage), childCanvasPage)
    }

    func test_existingCanvasPageForPage_returnsNilIfNoDirectChildMatchesPage() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let page = modelController.collection(for: Page.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = page
        }

        let childPage = modelController.collection(for: Page.self).newObject()
        modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = childPage
            $0.parent = canvasPage
        }

        XCTAssertNil(canvasPage.existingCanvasPage(for: Page()))
    }
}
