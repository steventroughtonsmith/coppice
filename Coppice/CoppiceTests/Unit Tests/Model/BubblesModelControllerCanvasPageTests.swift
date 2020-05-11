//
//  CoppiceModelControllerCanvasPageTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 23/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class CoppiceModelControllerCanvasPageTests: XCTestCase {
    var undoManager: UndoManager!
    var modelController: CoppiceModelController!
    var canvas: Canvas!
    var page: Page!
    var canvasPage: CanvasPage!

    override func setUp() {
        super.setUp()

        self.undoManager = UndoManager()
        self.modelController = CoppiceModelController(undoManager: self.undoManager)
        self.canvas = Canvas.create(in: self.modelController)
        self.page = Page.create(in: self.modelController)
        self.canvasPage = CanvasPage.create(in: self.modelController) {
            $0.canvas = self.canvas
            $0.page = self.page
        }
    }


    //MARK: - openPage(at:on:)
    func test_openPageAtLink_returnsEmptyArrayIfDestinationNotFound() throws {
        let link = PageLink(destination: Page.modelID(with: UUID()))
        let openedPages = self.modelController.openPage(at: link, on: self.canvas)
        XCTAssertEqual(openedPages, [])
    }

    func test_openPageAtLink_addsPageToCanvasIfThereIsNoSourceInLink() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage()

        let openedPages = self.modelController.openPage(at: link, on: self.canvas)
        XCTAssertEqual(openedPages.count, 1)

        let canvasPage = try XCTUnwrap(openedPages.first)

        XCTAssertEqual(canvasPage.page, linkedPage)
        XCTAssertEqual(canvasPage.canvas, self.canvas)
        XCTAssertNil(canvasPage.parent)
    }

    func test_openPageAtLink_addsPageToCanvasIfSourcePageDoesntExist() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage().withSource(CanvasPage.modelID(with: UUID()))

        let openedPages = self.modelController.openPage(at: link, on: self.canvas)
        XCTAssertEqual(openedPages.count, 1)

        let canvasPage = try XCTUnwrap(openedPages.first)

        XCTAssertEqual(canvasPage.page, linkedPage)
        XCTAssertEqual(canvasPage.canvas, self.canvas)
        XCTAssertNil(canvasPage.parent)
    }

    func test_openPageAtLink_returnsExistingPageIfOneExistsOnSourcePage() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage().withSource(self.canvasPage.id)

        let expectedCanvasPage = try XCTUnwrap(self.canvas.addPages([linkedPage]).first)
        expectedCanvasPage.parent = self.canvasPage

        let openedPages = self.modelController.openPage(at: link, on: self.canvas)
        XCTAssertEqual(openedPages.count, 1)

        let canvasPage = try XCTUnwrap(openedPages.first)
        XCTAssertEqual(canvasPage, expectedCanvasPage)
    }

    func test_openPageAtLink_opensPageOnCanvasIfDoesntExistOnSource() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage().withSource(self.canvasPage.id)

        let openedPages = self.modelController.openPage(at: link, on: self.canvas)
        XCTAssertEqual(openedPages.count, 1)

        let canvasPage = try XCTUnwrap(openedPages.first)

        XCTAssertEqual(canvasPage.page, linkedPage)
        XCTAssertEqual(canvasPage.canvas, self.canvas)
        XCTAssertEqual(canvasPage.parent, self.canvasPage)
    }

    func test_openPageAtLink_undoingOpeningLinkWithNoSourceRemovesPageFromCanvas() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage()
        self.undoManager.removeAllActions()

        let openedPages = self.modelController.openPage(at: link, on: self.canvas)
        let canvasPage = try XCTUnwrap(openedPages.first)

        self.undoManager.undo()

        XCTAssertFalse(self.canvas.pages.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.page.canvases.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage))
    }

    func test_openPageAtLink_undoingOpeningLinkWithSourceClosesCanvasPage() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage().withSource(self.canvasPage.id)
        self.undoManager.removeAllActions()

        let openedPages = self.modelController.openPage(at: link, on: self.canvas)
        let canvasPage = try XCTUnwrap(openedPages.first)

        self.undoManager.undo()

        XCTAssertFalse(self.canvas.pages.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.page.canvases.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage))
    }

    func test_openPageAtLink_redoingOpeningLinkWithNoSourceAddsPageAgain() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage()
        self.undoManager.removeAllActions()

        let openedPages = self.modelController.openPage(at: link, on: self.canvas)
        let canvasPage = try XCTUnwrap(openedPages.first)
        canvasPage.frame = CGRect(x: 90, y: -40, width: 300, height: 300)

        self.undoManager.undo()
        XCTAssertFalse(self.canvas.pages.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.page.canvases.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage))
        self.undoManager.redo()

        let redoneCanvasPage = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage.id))
        XCTAssertEqual(redoneCanvasPage.canvas, self.canvas)
        XCTAssertEqual(redoneCanvasPage.page, linkedPage)
        XCTAssertEqual(redoneCanvasPage.frame, canvasPage.frame)
    }

    func test_openPageAtLink_redoingOpeningLinkWithSourceOpensCanvasPage() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage().withSource(self.canvasPage.id)
        self.undoManager.removeAllActions()

        let openedPages = self.modelController.openPage(at: link, on: self.canvas)
        let canvasPage = try XCTUnwrap(openedPages.first)
        canvasPage.frame = CGRect(x: 90, y: -40, width: 300, height: 300)

        self.undoManager.undo()
        XCTAssertFalse(self.canvas.pages.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.page.canvases.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage))
        self.undoManager.redo()

        let redoneCanvas = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage.id))
        XCTAssertEqual(redoneCanvas.canvas, self.canvas)
        XCTAssertEqual(redoneCanvas.page, linkedPage)
        XCTAssertEqual(redoneCanvas.frame, canvasPage.frame)
        XCTAssertEqual(redoneCanvas.parent, self.canvasPage)
    }


    //MARK: - close(_:)
    func test_closeCanvasPage_removesCanvasPageFromCanvas() {
        self.modelController.close(self.canvasPage)
        XCTAssertNil(self.canvasPage.canvas)
        XCTAssertFalse(self.canvas.pages.contains(self.canvasPage))
    }

    func test_closeCanvasPage_deletesCanvasPage() {
        self.modelController.close(self.canvasPage)
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(self.canvasPage.id))
    }

    func test_closeCanvasPage_removesAllChildPagesFromCanvas() {
        let child1 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }

        self.modelController.close(self.canvasPage)
        XCTAssertNil(child1.canvas)
        XCTAssertFalse(self.canvas.pages.contains(child1))
        XCTAssertNil(child2.canvas)
        XCTAssertFalse(self.canvas.pages.contains(child2))
    }

    func test_closeCanvasPage_deletesChildCanvasPages() {
        let child1 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }

        self.modelController.close(self.canvasPage)
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(child1.id))
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(child2.id))
    }

    func test_closeCanvasPage_undoingRecreatesCanvasPageWithSameIDAndProperties() throws {
        self.undoManager.removeAllActions()
        self.modelController.close(self.canvasPage)

        //Sanity check
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(self.canvasPage))

        self.undoManager.undo()

        let undonePage = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(self.canvasPage.id))
        XCTAssertEqual(undonePage.frame, self.canvasPage.frame)
    }

    func test_closeCanvasPage_undoingAddsCanvasPageBackToCanvas() throws {
        self.undoManager.removeAllActions()
        self.modelController.close(self.canvasPage)

        //Sanity Check
        XCTAssertFalse(self.canvas.pages.contains(self.canvasPage))

        self.undoManager.undo()

        let undonePage = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(self.canvasPage.id))
        XCTAssertEqual(undonePage.canvas, self.canvas)
    }

    func test_closeCanvasPage_undoingRecreatesAllChildPagesWithSameIDsAndProperties() throws {
        let child1 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
            $0.frame = CGRect(x: 5, y: 4, width: 3, height: 2)
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
            $0.frame = CGRect(x: 99, y: 100, width: 101, height: 102)
        }
        self.undoManager.removeAllActions()

        self.modelController.close(self.canvasPage)

        self.undoManager.undo()

        let undoneChild1 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(child1.id))
        XCTAssertEqual(undoneChild1.frame, child1.frame)
        let undoneChild2 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(child2.id))
        XCTAssertEqual(undoneChild2.frame, child2.frame)
    }

    func test_closeCanvasPage_undoingAddsAllChildPagesBacktoCanvas() throws {
        let child1 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        self.undoManager.removeAllActions()

        self.modelController.close(self.canvasPage)

        self.undoManager.undo()

        let undoneChild1 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(child1.id))
        XCTAssertEqual(undoneChild1.canvas, self.canvas)
        let undoneChild2 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(child2.id))
        XCTAssertEqual(undoneChild2.canvas, self.canvas)
    }

    func test_closeCanvasPage_undoingCorrectlyConnectsAllParentChildRelationships() throws {
        let child1 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        self.undoManager.removeAllActions()

        self.modelController.close(self.canvasPage)

        self.undoManager.undo()

        let undonePage = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(self.canvasPage.id))
        let undoneChild1 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(child1.id))
        XCTAssertEqual(undoneChild1.parent, undonePage)
        let undoneChild2 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(child2.id))
        XCTAssertEqual(undoneChild2.parent, undonePage)
    }

    func test_closeCanvasPage_redoingRemovesAndDeletesAllCanvasPagesAgain() {
        let child1 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        self.undoManager.removeAllActions()

        self.modelController.close(self.canvasPage)

        self.undoManager.undo()
        self.undoManager.redo()

        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(self.canvasPage.id))
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(child1.id))
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(child2.id))
    }
}
