//
//  CoppiceModelControllerCanvasTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 23/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

class CoppiceModelControllerCanvasTests: XCTestCase {
    var undoManager: UndoManager!
    var modelController: CoppiceModelController!

    override func setUp() {
        super.setUp()

        self.undoManager = UndoManager()
        self.modelController = CoppiceModelController(undoManager: self.undoManager)
    }


    //MARK: - createCanvas(setup:)
    func test_createCanvas_addsCanvasToCollection() throws {
        let canvas = self.modelController.createCanvas()
        XCTAssertTrue(self.modelController.canvasCollection.contains(canvas))
    }

    func test_createCanvas_callsSetupWithCreatedCanvas() throws {
        var actualCanvas: Canvas?
        let expectedCanvas = self.modelController.createCanvas() { actualCanvas = $0 }
        XCTAssertEqual(actualCanvas, expectedCanvas)
    }

    func test_createCanvas_undoingRemovesCanvasFromCollection() throws {
        let canvas = self.modelController.createCanvas()
        self.undoManager.undo()
        XCTAssertFalse(self.modelController.canvasCollection.contains(canvas))
    }

    func test_createCanvas_redoingRecreatesCanvasWithSameIDAndProperties() throws {
        let canvas = self.modelController.createCanvas()
        canvas.title = "Foo Bar"
        canvas.sortIndex = 5
        canvas.theme = .dark
        canvas.viewPort = CGRect(x: 10, y: 9, width: 80, height: 60)

        self.undoManager.undo()
        XCTAssertFalse(self.modelController.canvasCollection.contains(canvas))
        self.undoManager.redo()

        let redoneCanvas = try XCTUnwrap(self.modelController.canvasCollection.objectWithID(canvas.id))
        XCTAssertEqual(redoneCanvas.title, canvas.title)
        XCTAssertEqual(redoneCanvas.sortIndex, canvas.sortIndex)
        XCTAssertEqual(redoneCanvas.theme, canvas.theme)
        XCTAssertEqual(redoneCanvas.viewPort, canvas.viewPort)
        XCTAssertEqual(redoneCanvas.dateCreated, canvas.dateCreated)
        XCTAssertEqual(redoneCanvas.dateModified, canvas.dateModified)
    }


    //MARK: - deleteCanvas(_:)
    func test_deleteCanvas_removesCanvasFromCollection() throws {
        let canvas = self.modelController.createCanvas()
        self.undoManager.removeAllActions()

        self.modelController.delete(canvas)

        XCTAssertFalse(self.modelController.canvasCollection.contains(canvas))
    }

    func test_deleteCanvas_removesAllCanvasPagesOnCanvas() throws {
        let canvas = self.modelController.createCanvas()
        let page1 = Page.create(in: self.modelController)
        let page2 = Page.create(in: self.modelController)
        let page3 = Page.create(in: self.modelController)
        let canvasPages = canvas.addPages([page1, page2, page3])

        self.modelController.delete(canvas)

        let canvasPage1 = try XCTUnwrap(canvasPages[safe: 0])
        let canvasPage2 = try XCTUnwrap(canvasPages[safe: 0])
        let canvasPage3 = try XCTUnwrap(canvasPages[safe: 0])

        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage1))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage2))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage3))
    }

    func test_deleteCanvas_undoingRecreatesCanvasWithSameIDAndProperties() throws {
        let canvas = self.modelController.createCanvas()
        canvas.title = "Foo Bar"
        canvas.sortIndex = 5
        canvas.theme = .dark
        canvas.viewPort = CGRect(x: 10, y: 9, width: 80, height: 60)
        self.undoManager.removeAllActions()

        self.modelController.delete(canvas)

        self.undoManager.undo()

        let undoneCanvas = try XCTUnwrap(self.modelController.canvasCollection.objectWithID(canvas.id))
        XCTAssertEqual(undoneCanvas.title, canvas.title)
        XCTAssertEqual(undoneCanvas.sortIndex, canvas.sortIndex)
        XCTAssertEqual(undoneCanvas.theme, canvas.theme)
        XCTAssertEqual(undoneCanvas.viewPort, canvas.viewPort)
        XCTAssertEqual(undoneCanvas.dateCreated, canvas.dateCreated)
        XCTAssertEqual(undoneCanvas.dateModified, canvas.dateModified)
    }

    func test_deleteCanvas_undoingRecreatesAllPagesOnCanvasWithSameIDsAndProperties() throws {
        let canvas = self.modelController.createCanvas()
        let page1 = Page.create(in: self.modelController)
        let page2 = Page.create(in: self.modelController)
        let page3 = Page.create(in: self.modelController)
        let canvasPages = canvas.addPages([page1, page2, page3])

        let canvasPage1 = try XCTUnwrap(canvasPages[safe: 0])
        canvasPage1.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
        let canvasPage2 = try XCTUnwrap(canvasPages[safe: 1])
        canvasPage2.frame = CGRect(x: -20, y: -110, width: 456, height: 654)
        let canvasPage3 = try XCTUnwrap(canvasPages[safe: 2])
        canvasPage3.frame = CGRect(x: -120, y: 110, width: 922, height: 741)
        self.undoManager.removeAllActions()

        self.modelController.delete(canvas)
        self.undoManager.undo()

        let undoneCanvas = try XCTUnwrap(self.modelController.canvasCollection.objectWithID(canvas.id))
        let undoneCanvasPage1 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage1.id))
        XCTAssertEqual(undoneCanvasPage1.frame, canvasPage1.frame)
        XCTAssertEqual(undoneCanvasPage1.canvas, undoneCanvas)
        XCTAssertEqual(undoneCanvasPage1.page, page1)
        let undoneCanvasPage2 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage2.id))
        XCTAssertEqual(undoneCanvasPage2.frame, canvasPage2.frame)
        XCTAssertEqual(undoneCanvasPage2.canvas, undoneCanvas)
        XCTAssertEqual(undoneCanvasPage2.page, page2)
        let undoneCanvasPage3 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage3.id))
        XCTAssertEqual(undoneCanvasPage3.frame, canvasPage3.frame)
        XCTAssertEqual(undoneCanvasPage3.canvas, undoneCanvas)
        XCTAssertEqual(undoneCanvasPage3.page, page3)
    }

    func test_deleteCanvas_redoingRemovesCanvasFromCollectionAgain() throws {
        let canvas = self.modelController.createCanvas()
        self.undoManager.removeAllActions()

        self.modelController.delete(canvas)

        self.undoManager.undo()
        XCTAssertNotNil(self.modelController.object(with: canvas.id))
        self.undoManager.redo()

        XCTAssertNil(self.modelController.object(with: canvas.id))
    }

    func test_deleteCanvas_redoingRemovesCanvasPagesAgain() throws {
        let canvas = self.modelController.createCanvas()
        let page1 = Page.create(in: self.modelController)
        let page2 = Page.create(in: self.modelController)
        let page3 = Page.create(in: self.modelController)

        let canvasPages = canvas.addPages([page1, page2, page3])
        let canvasPage1 = try XCTUnwrap(canvasPages[safe: 0])
        let canvasPage2 = try XCTUnwrap(canvasPages[safe: 0])
        let canvasPage3 = try XCTUnwrap(canvasPages[safe: 0])
        self.undoManager.removeAllActions()

        self.modelController.delete(canvas)

        self.undoManager.undo()
        XCTAssertNotNil(self.modelController.canvasPageCollection.objectWithID(canvasPage1.id))
        XCTAssertNotNil(self.modelController.canvasPageCollection.objectWithID(canvasPage2.id))
        XCTAssertNotNil(self.modelController.canvasPageCollection.objectWithID(canvasPage3.id))
        self.undoManager.redo()

        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(canvasPage1.id))
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(canvasPage2.id))
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(canvasPage3.id))
    }
}
