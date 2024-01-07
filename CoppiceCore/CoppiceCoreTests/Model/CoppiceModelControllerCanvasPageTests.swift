//
//  CoppiceModelControllerCanvasPageTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 23/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

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
        let openedPages = self.modelController.openPage(at: link, on: self.canvas, mode: .new)
        XCTAssertEqual(openedPages, [])
    }

    func test_openPageAtLink_addsPageToCanvasIfThereIsNoSourceInLink() throws {
        XCTFail("Re-implement")
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage()

        let openedPages = self.modelController.openPage(at: link, on: self.canvas, mode: .new)
        XCTAssertEqual(openedPages.count, 1)

        let canvasPage = try XCTUnwrap(openedPages.first)

        XCTAssertEqual(canvasPage.page, linkedPage)
        XCTAssertEqual(canvasPage.canvas, self.canvas)
//        XCTAssertNil(canvasPage.parent)
    }

    func test_openPageAtLink_addsPageToCanvasIfSourcePageDoesntExist() throws {
        XCTFail("Re-implement")
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage().withSource(CanvasPage.modelID(with: UUID()))

        let openedPages = self.modelController.openPage(at: link, on: self.canvas, mode: .new)
        XCTAssertEqual(openedPages.count, 1)

        let canvasPage = try XCTUnwrap(openedPages.first)

        XCTAssertEqual(canvasPage.page, linkedPage)
        XCTAssertEqual(canvasPage.canvas, self.canvas)
//        XCTAssertNil(canvasPage.parent)
    }

    func test_openPageAtLink_opensPageOnCanvasIfDoesntExistOnSource() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage().withSource(self.canvasPage.id)

        let openedPages = self.modelController.openPage(at: link, on: self.canvas, mode: .new)
        XCTAssertEqual(openedPages.count, 1)

        let canvasPage = try XCTUnwrap(openedPages.first)

        XCTAssertEqual(canvasPage.page, linkedPage)
        XCTAssertEqual(canvasPage.canvas, self.canvas)
        XCTAssertEqual(canvasPage.linksIn.first?.sourcePage, self.canvasPage)
    }

    func test_openPageAtLink_undoingOpeningLinkWithNoSourceRemovesPageFromCanvas() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage()
        self.undoManager.removeAllActions()

        let openedPages = self.modelController.openPage(at: link, on: self.canvas, mode: .new)
        let canvasPage = try XCTUnwrap(openedPages.first)

        self.undoManager.undo()

        XCTAssertFalse(self.canvas.pages.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.page.canvasPages.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage))
    }

    func test_openPageAtLink_undoingOpeningLinkWithSourceClosesCanvasPage() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage().withSource(self.canvasPage.id)
        self.undoManager.removeAllActions()

        let openedPages = self.modelController.openPage(at: link, on: self.canvas, mode: .new)
        let canvasPage = try XCTUnwrap(openedPages.first)

        self.undoManager.undo()

        XCTAssertFalse(self.canvas.pages.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.page.canvasPages.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage))
    }

    func test_openPageAtLink_redoingOpeningLinkWithNoSourceAddsPageAgain() throws {
        let linkedPage = Page.create(in: self.modelController)
        let link = linkedPage.linkToPage()
        self.undoManager.removeAllActions()

        let openedPages = self.modelController.openPage(at: link, on: self.canvas, mode: .new)
        let canvasPage = try XCTUnwrap(openedPages.first)
        canvasPage.frame = CGRect(x: 90, y: -40, width: 300, height: 300)

        self.undoManager.undo()
        XCTAssertFalse(self.canvas.pages.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.page.canvasPages.contains(where: { $0.id == canvasPage.id }))
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

        let openedPages = self.modelController.openPage(at: link, on: self.canvas, mode: .new)
        let canvasPage = try XCTUnwrap(openedPages.first)
        canvasPage.frame = CGRect(x: 90, y: -40, width: 300, height: 300)

        self.undoManager.undo()
        XCTAssertFalse(self.canvas.pages.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.page.canvasPages.contains(where: { $0.id == canvasPage.id }))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage))
        self.undoManager.redo()

        let redoneCanvas = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage.id))
        XCTAssertEqual(redoneCanvas.canvas, self.canvas)
        XCTAssertEqual(redoneCanvas.page, linkedPage)
        XCTAssertEqual(redoneCanvas.frame, canvasPage.frame)
        XCTAssertEqual(redoneCanvas.linksIn.first?.sourcePage, self.canvasPage)
    }


    //MARK: - close(_:)
    func test_closeCanvasPage_removesCanvasPageFromCanvas() {
        self.modelController.close(self.canvasPage)
        XCTAssertFalse(self.canvas.pages.contains(self.canvasPage))
    }

    func test_closeCanvasPage_deletesCanvasPage() {
        self.modelController.close(self.canvasPage)
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(self.canvasPage.id))
    }

    func test_closeCanvasPage_removesAllChildPagesFromCanvas() {
        let child1 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
        }
        let linkToChild1 = self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child1
        }
        let linkToChild2 = self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child2
        }

        self.modelController.close(self.canvasPage)
        XCTAssertFalse(self.canvas.pages.contains(child1))
        XCTAssertFalse(self.canvas.pages.contains(child2))
        XCTAssertFalse(self.canvas.links.contains(linkToChild1))
        XCTAssertFalse(self.canvas.links.contains(linkToChild2))
    }

    func test_closeCanvasPage_deletesChildCanvasPagesAndLinks() {
        let child1 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
        }
        let linkToChild1 = self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child1
        }
        let linkToChild2 = self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child2
        }

        self.modelController.close(self.canvasPage)
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(child1.id))
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(child2.id))
        XCTAssertNil(self.modelController.canvasLinkCollection.objectWithID(linkToChild1.id))
        XCTAssertNil(self.modelController.canvasLinkCollection.objectWithID(linkToChild2.id))
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
            $0.frame = CGRect(x: 5, y: 4, width: 3, height: 2)
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.frame = CGRect(x: 99, y: 100, width: 101, height: 102)
        }
        self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child1
        }
        self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child2
        }
        self.undoManager.removeAllActions()

        self.modelController.close(self.canvasPage)
        XCTAssertEqual(self.modelController.canvasPageCollection.all.count, 0)
        XCTAssertEqual(self.modelController.canvasLinkCollection.all.count, 0)

        self.undoManager.undo()

        let undoneChild1 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(child1.id))
        XCTAssertEqual(undoneChild1.frame, child1.frame)
        let undoneChild2 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(child2.id))
        XCTAssertEqual(undoneChild2.frame, child2.frame)
    }

    func test_closeCanvasPage_undoingAddsAllChildPagesBacktoCanvas() throws {
        let child1 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
        }
        self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child1
        }
        self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child2
        }
        self.undoManager.removeAllActions()

        self.modelController.close(self.canvasPage)
        XCTAssertEqual(self.modelController.canvasPageCollection.all.count, 0)
        XCTAssertEqual(self.modelController.canvasLinkCollection.all.count, 0)

        self.undoManager.undo()

        let undoneChild1 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(child1.id))
        XCTAssertEqual(undoneChild1.canvas, self.canvas)
        let undoneChild2 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(child2.id))
        XCTAssertEqual(undoneChild2.canvas, self.canvas)
    }

    func test_closeCanvasPage_undoingAddsAllLinksBacktoCanvas() throws {
        let child1 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
        }
        let linkToChild1 = self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child1
        }
        let linkToChild2 = self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child2
        }
        self.undoManager.removeAllActions()

        self.modelController.close(self.canvasPage)
        XCTAssertEqual(self.modelController.canvasPageCollection.all.count, 0)
        XCTAssertEqual(self.modelController.canvasLinkCollection.all.count, 0)

        self.undoManager.undo()

        let undoneLink1 = try XCTUnwrap(self.modelController.canvasLinkCollection.objectWithID(linkToChild1.id))
        XCTAssertEqual(undoneLink1.canvas, self.canvas)
        XCTAssertEqual(undoneLink1.sourcePage?.id, self.canvasPage.id)
        XCTAssertEqual(undoneLink1.destinationPage?.id, child1.id)
        let undoneLink2 = try XCTUnwrap(self.modelController.canvasLinkCollection.objectWithID(linkToChild2.id))
        XCTAssertEqual(undoneLink2.canvas, self.canvas)
        XCTAssertEqual(undoneLink2.sourcePage?.id, self.canvasPage.id)
        XCTAssertEqual(undoneLink2.destinationPage?.id, child2.id)
    }

    func test_closeCanvasPage_redoingRemovesAndDeletesAllCanvasPagesAgain() {
        let child1 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
        }
        let child2 = self.modelController.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
        }
        let linkToChild1 = self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child1
        }
        let linkToChild2 = self.modelController.canvasLinkCollection.newObject() {
            $0.canvas = self.canvas
            $0.sourcePage = self.canvasPage
            $0.destinationPage = child2
        }
        self.undoManager.removeAllActions()

        self.modelController.close(self.canvasPage)
        XCTAssertEqual(self.modelController.canvasPageCollection.all.count, 0)
        XCTAssertEqual(self.modelController.canvasLinkCollection.all.count, 0)

        self.undoManager.undo()
        self.undoManager.redo()

        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(self.canvasPage.id))
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(child1.id))
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(child2.id))
        XCTAssertNil(self.modelController.canvasLinkCollection.objectWithID(linkToChild1.id))
        XCTAssertNil(self.modelController.canvasLinkCollection.objectWithID(linkToChild2.id))
    }
}
