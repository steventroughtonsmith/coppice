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
        let id: ModelID = try canvasPage.plistRepresentation[required: .id]
        XCTAssertEqual(id, canvasPage.id)
    }

    func test_plistRepresentation_containsFrame() throws {
        let canvasPage = CanvasPage.create(in: self.modelController)
        canvasPage.frame = CGRect(x: 20, y: 30, width: 40, height: 50)
        let frame: CGRect = try canvasPage.plistRepresentation[required: CanvasPage.PlistKeys.frame]
        XCTAssertEqual(frame, CGRect(x: 20, y: 30, width: 40, height: 50))
    }

    func test_plistRepresentation_containsPageID() throws {
        let page = Page.create(in: self.modelController)
        let canvasPage = CanvasPage.create(in: self.modelController)
        canvasPage.page = page
        let pageID: ModelID? = try canvasPage.plistRepresentation[CanvasPage.PlistKeys.page]
        XCTAssertEqual(pageID, page.id)
    }

    func test_plistRepresentation_containsCanvasID() throws {
        let canvas = Canvas.create(in: self.modelController)
        let canvasPage = CanvasPage.create(in: self.modelController)
        canvasPage.canvas = canvas
        let canvasID: ModelID? = try canvasPage.plistRepresentation[CanvasPage.PlistKeys.canvas]
        XCTAssertEqual(canvasID, canvas.id)
    }

    func test_plistRepresentation_containsZIndex() throws {
        let canvasPage = CanvasPage.create(in: self.modelController)
        canvasPage.zIndex = 42
        let zIndex: Int = try canvasPage.plistRepresentation[required: CanvasPage.PlistKeys.zIndex]
        XCTAssertEqual(zIndex, canvasPage.zIndex)
    }

    func test_plistRepresentation_includesAnyOtherProperties() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: PlistValue] = [
            .id: canvasPage.id.stringRepresentation,
            ModelPlistKey(rawValue: "bar"): "foo",
            CanvasPage.PlistKeys.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            CanvasPage.PlistKeys.zIndex: 31,
            ModelPlistKey(rawValue: "point"): NSStringFromPoint(CGPoint(x: 15, y: 51)),
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: .init(id: canvasPage.id, plist: plist)))

        let plistRepresentation = try canvasPage.plistRepresentation
        XCTAssertEqual(try plistRepresentation[ModelPlistKey(rawValue: "bar")], "foo")
        XCTAssertEqual(try plistRepresentation[ModelPlistKey(rawValue: "point")], CGPoint(x: 15, y: 51))
    }


    //MARK: - update(fromPlistRepresentation:)
    func test_updateFromPlistRepresentation_doesntUpdateIfIDsDontMatch() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let newPage = modelController.collection(for: Page.self).newObject()
        let newCanvas = modelController.collection(for: Canvas.self).newObject()
        let parent = modelController.collection(for: CanvasPage.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: PlistValue] = [
            .id: "foobar",
            CanvasPage.PlistKeys.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            CanvasPage.PlistKeys.page: newPage.id.stringRepresentation,
            CanvasPage.PlistKeys.canvas: newCanvas.id.stringRepresentation,
            ModelPlistKey(rawValue: "parent"): parent.id.stringRepresentation,
        ]

        XCTAssertThrowsError(try canvasPage.update(fromPlistRepresentation: .init(id: CanvasPage.modelID(with: UUID()), plist: plist)), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), ModelObjectUpdateErrors.idsDontMatch)
        }
    }

    func test_updateFromPlistRepresentation_updatesFrame() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: PlistValue] = [
            .id: canvasPage.id.stringRepresentation,
            CanvasPage.PlistKeys.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            CanvasPage.PlistKeys.zIndex: 31,
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: .init(id: canvasPage.id, plist: plist)))

        XCTAssertEqual(canvasPage.frame, CGRect(x: 1, y: 2, width: 3, height: 4))
    }

    func test_updateFromPlistRepresentation_updatesZIndex() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: PlistValue] = [
            .id: canvasPage.id.stringRepresentation,
            CanvasPage.PlistKeys.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            CanvasPage.PlistKeys.zIndex: 31,
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: .init(id: canvasPage.id, plist: plist)))

        XCTAssertEqual(canvasPage.zIndex, 31)
    }

    func test_updateFromPlistRepresentation_updatesPage() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        modelController.collection(for: Page.self).newObject() //Separate test page
        let newPage = modelController.collection(for: Page.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: PlistValue] = [
            .id: canvasPage.id.stringRepresentation,
            CanvasPage.PlistKeys.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            CanvasPage.PlistKeys.zIndex: 31,
            CanvasPage.PlistKeys.page: newPage.id.stringRepresentation,
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: .init(id: canvasPage.id, plist: plist)))

        XCTAssertEqual(canvasPage.page, newPage)
    }

    func test_updateFromPlistRepresentation_updatesCanvas() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        modelController.collection(for: Canvas.self).newObject() //Separate test page
        let newCanvas = modelController.collection(for: Canvas.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: PlistValue] = [
            .id: canvasPage.id.stringRepresentation,
            CanvasPage.PlistKeys.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            CanvasPage.PlistKeys.zIndex: 31,
            CanvasPage.PlistKeys.canvas: newCanvas.id.stringRepresentation,
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: .init(id: canvasPage.id, plist: plist)))

        XCTAssertEqual(canvasPage.canvas, newCanvas)
    }

    func test_updateFromPlistRepresentation_addsAnythingElseInPlistToOtherProperties() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: PlistValue] = [
            .id: canvasPage.id.stringRepresentation,
            ModelPlistKey(rawValue: "bar"): "foo",
            CanvasPage.PlistKeys.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            CanvasPage.PlistKeys.zIndex: 31,
            ModelPlistKey(rawValue: "point"): NSStringFromPoint(CGPoint(x: 15, y: 51)),
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: .init(id: canvasPage.id, plist: plist)))

        XCTAssertEqual(canvasPage.otherProperties[ModelPlistKey(rawValue: "bar")] as? String, "foo")
        XCTAssertEqual(canvasPage.otherProperties[ModelPlistKey(rawValue: "point")] as? String, NSStringFromPoint(CGPoint(x: 15, y: 51)))
    }

    func test_updateFromPlistRepresentation_doesntIncludeAnySupportPlistKeysInOtherProperties() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        let plist: [ModelPlistKey: PlistValue] = [
            .id: canvasPage.id.stringRepresentation,
            ModelPlistKey(rawValue: "bar"): "foo",
            CanvasPage.PlistKeys.frame: NSStringFromRect(CGRect(x: 1, y: 2, width: 3, height: 4)),
            CanvasPage.PlistKeys.zIndex: 31,
            ModelPlistKey(rawValue: "point"): NSStringFromPoint(CGPoint(x: 15, y: 51)),
        ]

        XCTAssertNoThrow(try canvasPage.update(fromPlistRepresentation: .init(id: canvasPage.id, plist: plist)))

        XCTAssertEqual(canvasPage.otherProperties.count, 2)
        for key in CanvasPage.PlistKeys.all {
            XCTAssertNil(canvasPage.otherProperties[key])
        }
    }


    //MARK: - existingLinkedCanvasPage(for:)
    func test_existingLinkedCanvasPageForPage_returnsSelfIfSuppliedPageMatchesReceiversPage() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let page = modelController.collection(for: Page.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = page
        }

        XCTAssertEqual(canvasPage.existingLinkedCanvasPage(for: page), canvasPage)
    }

    func test_existingLinkedCanvasPageForPage_returnsChildWithMatchingPageIfOneExists() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let page = modelController.collection(for: Page.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = page
        }

        let childPage = modelController.collection(for: Page.self).newObject()
        let childCanvasPage = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = childPage
        }

        _ = modelController.collection(for: CanvasLink.self).newObject() {
            $0.sourcePage = canvasPage
            $0.destinationPage = childCanvasPage
            $0.link = PageLink(destination: childPage.id, source: canvasPage.id)
        }

        XCTAssertEqual(canvasPage.existingLinkedCanvasPage(for: childPage), childCanvasPage)
    }

    func test_existingLinkedCanvasPageForPage_returnsNilIfNoDirectChildMatchesPage() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let page = modelController.collection(for: Page.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = page
        }

        let childPage = modelController.collection(for: Page.self).newObject()
        let childCanvasPage = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = childPage
        }

        _ = modelController.collection(for: CanvasLink.self).newObject() {
            $0.sourcePage = canvasPage
            $0.destinationPage = childCanvasPage
            $0.link = PageLink(destination: childPage.id, source: canvasPage.id)
        }

        XCTAssertNil(canvasPage.existingLinkedCanvasPage(for: Page()))
    }
}
