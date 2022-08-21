//
//  CanvasPageTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import M3Data
import XCTest

class CanvasPageTests: XCTestCase {
    var modelController: CoppiceModelController!

    override func setUp() {
        super.setUp()

        self.modelController = CoppiceModelController(undoManager: UndoManager())
    }


    //MARK: - .plistRepresentation
    func test_plistRepresentation_containsID() throws {
        let canvasPage = CanvasPage.create(in: self.modelController)
        let id = try XCTUnwrap(canvasPage.plistRepresentation[.id] as? ModelID)
        XCTAssertEqual(id, canvasPage.id)
    }

    func test_plistRepresentation_containsFrame() throws {
        let canvasPage = CanvasPage.create(in: self.modelController)
        canvasPage.frame = CGRect(x: 20, y: 30, width: 40, height: 50)
        let frame = try XCTUnwrap(canvasPage.plistRepresentation[.CanvasPage.frame] as? String)
        XCTAssertEqual(frame, NSStringFromRect(CGRect(x: 20, y: 30, width: 40, height: 50)))
    }

    func test_plistRepresentation_containsPageID() throws {
        let page = Page.create(in: self.modelController)
        let canvasPage = CanvasPage.create(in: self.modelController)
        canvasPage.page = page
        let pageID = try XCTUnwrap(canvasPage.plistRepresentation[.CanvasPage.page] as? ModelID)
        XCTAssertEqual(pageID, page.id)
    }

    func test_plistRepresentation_containsCanvasID() throws {
        let canvas = Canvas.create(in: self.modelController)
        let canvasPage = CanvasPage.create(in: self.modelController)
        canvasPage.canvas = canvas
        let canvasID = try XCTUnwrap(canvasPage.plistRepresentation[.CanvasPage.canvas] as? ModelID)
        XCTAssertEqual(canvasID, canvas.id)
    }

    func test_plistRepresentation_containsZIndex() throws {
        let canvasPage = CanvasPage.create(in: self.modelController)
        canvasPage.zIndex = 42
        let zIndex = try XCTUnwrap(canvasPage.plistRepresentation[.CanvasPage.zIndex] as? Int)
        XCTAssertEqual(zIndex, canvasPage.zIndex)
    }

    func test_plistRepresentation_includesAnyOtherProperties() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: Any] = [
            .id: canvasPage.id,
            ModelPlistKey(rawValue: "bar"): "foo",
            .CanvasPage.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            .CanvasPage.zIndex: 31,
            ModelPlistKey(rawValue: "point"): NSStringFromPoint(CGPoint(x: 15, y: 51)),
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        let plistRepresentation = canvasPage.plistRepresentation
        XCTAssertEqual(plistRepresentation[ModelPlistKey(rawValue: "bar")] as? String, "foo")
        XCTAssertEqual(plistRepresentation[ModelPlistKey(rawValue: "point")] as? String, NSStringFromPoint(CGPoint(x: 15, y: 51)))
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

        let plist: [ModelPlistKey: Any] = [
            .id: "foobar",
            .CanvasPage.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            .CanvasPage.page: newPage.id.stringRepresentation,
            .CanvasPage.canvas: newCanvas.id.stringRepresentation,
            .CanvasPage.parent: parent.id.stringRepresentation,
        ]

        XCTAssertThrowsError(try canvasPage.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), ModelObjectUpdateErrors.idsDontMatch)
        }
    }

    func test_updateFromPlistRepresentation_updatesFrame() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: Any] = [
            .id: canvasPage.id,
            .CanvasPage.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvasPage.frame, CGRect(x: 1, y: 2, width: 3, height: 4))
    }

    func test_updateFromPlistRepresentation_updatesZIndex() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: Any] = [
            .id: canvasPage.id,
            .CanvasPage.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            .CanvasPage.zIndex: 31,
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvasPage.zIndex, 31)
    }

    func test_updateFromPlistRepresentation_updatesPage() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        modelController.collection(for: Page.self).newObject() //Separate test page
        let newPage = modelController.collection(for: Page.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: Any] = [
            .id: canvasPage.id,
            .CanvasPage.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            .CanvasPage.page: newPage.id,
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvasPage.page, newPage)
    }

    func test_updateFromPlistRepresentation_updatesCanvas() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        modelController.collection(for: Canvas.self).newObject() //Separate test page
        let newCanvas = modelController.collection(for: Canvas.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: Any] = [
            .id: canvasPage.id,
            .CanvasPage.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            .CanvasPage.canvas: newCanvas.id,
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvasPage.canvas, newCanvas)
    }

    func test_updateFromPlistRepresentation_addsAnythingElseInPlistToOtherProperties() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: Any] = [
            .id: canvasPage.id,
            ModelPlistKey(rawValue: "bar"): "foo",
            .CanvasPage.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            .CanvasPage.zIndex: 31,
            ModelPlistKey(rawValue: "point"): NSStringFromPoint(CGPoint(x: 15, y: 51)),
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvasPage.otherProperties[ModelPlistKey(rawValue: "bar")] as? String, "foo")
        XCTAssertEqual(canvasPage.otherProperties[ModelPlistKey(rawValue: "point")] as? String, NSStringFromPoint(CGPoint(x: 15, y: 51)))
    }

    func test_updateFromPlistRepresentation_doesntIncludeAnySupportPlistKeysInOtherProperties() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: Any] = [
            .id: canvasPage.id,
            ModelPlistKey(rawValue: "bar"): "foo",
            .CanvasPage.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            .CanvasPage.zIndex: 31,
            ModelPlistKey(rawValue: "point"): NSStringFromPoint(CGPoint(x: 15, y: 51)),
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvasPage.otherProperties.count, 2)
        for key in ModelPlistKey.CanvasPage.all {
            XCTAssertNil(canvasPage.otherProperties[key])
        }
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
