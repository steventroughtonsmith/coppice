//
//  DocumentWindowViewModelTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 10/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class DocumentWindowViewModelTests: XCTestCase {

    var modelController: ModelController!
    var viewModel: DocumentWindowViewModel!

    var canvas: Canvas!
    var canvasPage: CanvasPage!
    var page: Page!

    override func setUp() {
        super.setUp()
        self.modelController = BubblesModelController(undoManager: UndoManager())

        self.canvas = self.modelController.collection(for: Canvas.self).newObject()
        self.page = self.modelController.collection(for: Page.self).newObject()
        self.canvasPage = self.modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = self.page
            $0.canvas = self.canvas
        }

        self.viewModel = DocumentWindowViewModel(modelController: modelController)
    }


    //MARK: - createPage()
    func test_createPage_addsANewPageToCollection() {
        let page = self.viewModel.createPage()
        XCTAssertTrue(self.viewModel.pageCollection.all.contains(page))
    }

    func test_createPage_ifSelectedSidebarObjectIsNilSetsToNewPage() {
        let page = self.viewModel.createPage()

        XCTAssertEqual(self.viewModel.selectedSidebarObjectID, page.id)
    }

    func test_createPage_ifSelectedSidebarObjectIsPageSetsToNewPage() {
        self.viewModel.selectedSidebarObjectID = self.page.id
        let page = self.viewModel.createPage()
        XCTAssertEqual(self.viewModel.selectedSidebarObjectID, page.id)
    }

    func test_createPage_ifSelectedSidebarObjectIsCanvasDoesntChangeSidebar() {
        self.viewModel.selectedSidebarObjectID = self.canvas.id
        self.viewModel.createPage()
        XCTAssertEqual(self.viewModel.selectedSidebarObjectID, self.canvas.id)
    }

    func test_createPage_ifSelectedSidebarObjectIsCanvasAddsPageToCanvas() {
        self.viewModel.selectedSidebarObjectID = self.canvas.id
        let page = self.viewModel.createPage()
        XCTAssertEqual(page.canvases.first?.canvas, self.canvas)
    }


    //MARK: - createPages(fromFilesAtURLs:addingTo:centredOn:)
    func test_createPagesFromFilesAtURLs_createsNewPagesForSuppliedFileURLs() {
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.viewModel.createPages(fromFilesAtURLs: fileURLs)
        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages.first?.content.contentType, .image)
        XCTAssertEqual(pages.last?.content.contentType, .text)
    }

    func test_createPagesFromFilesAtURLs_doesntAddPagesToCanvasIfNoneSupplied() {
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.viewModel.createPages(fromFilesAtURLs: fileURLs)
        XCTAssertEqual(pages.first?.canvases.count, 0)
        XCTAssertEqual(pages.last?.canvases.count, 0)
    }

    func test_createPagesFromFilesAtURLs_addsPagesToCanvasIfOneSupplied() {
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.viewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: self.canvas)
        XCTAssertEqual(pages.first?.canvases.first?.canvas, self.canvas)
        XCTAssertEqual(pages.last?.canvases.first?.canvas, self.canvas)
    }


    //MARK: - delete(_: Page)
    func test_deletePage_showsAlertIfPageOnCanvas() {
        let window = MockWindow()
        self.viewModel.window = window

        self.viewModel.delete(self.page)

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deletePage_doesntShowAlertIfPageNotOnAnyCanvases() {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.viewModel.pageCollection.newObject()

        self.viewModel.delete(page)

        XCTAssertNil(window.suppliedAlert)
    }

    func test_deletePage_deletesPageIfNotOnAnyCanvases() {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.viewModel.pageCollection.newObject()

        self.viewModel.delete(page)

        XCTAssertFalse(self.viewModel.pageCollection.all.contains(page))
    }

    func test_deletePage_doesntDeletePageIfOnCanvasesButAlertReturnsCancel() throws {
        let window = MockWindow()
        self.viewModel.window = window

        self.viewModel.delete(self.page)

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertTrue(self.viewModel.pageCollection.all.contains(self.page))
        XCTAssertTrue(self.viewModel.canvasPageCollection.all.contains(self.canvasPage))
    }

    func test_deletePage_deletesPageIfOnCanvasesAndAlertReturnsOK() throws {
        let window = MockWindow()
        self.viewModel.window = window

        self.viewModel.delete(self.page)

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertFalse(self.viewModel.pageCollection.all.contains(self.page))
    }

    func test_deletePage_deletingPageRemovesFromAllCanvases() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let canvas2 = self.viewModel.canvasCollection.newObject()
        let canvas2Page = self.viewModel.canvasPageCollection.newObject() {
            $0.canvas = canvas2
            $0.page = self.page
        }

        self.viewModel.delete(self.page)

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertFalse(self.viewModel.pageCollection.all.contains(self.page))
        XCTAssertFalse(self.viewModel.canvasPageCollection.all.contains(self.canvasPage))
        XCTAssertFalse(self.viewModel.canvasPageCollection.all.contains(canvas2Page))
    }

    func test_deletePage_setsSelectedSidebarObjectIDToNilIfPageWasSelected() {
        let page = self.viewModel.pageCollection.newObject()
        self.viewModel.selectedSidebarObjectID = page.id

        self.viewModel.delete(page)

        XCTAssertNil(self.viewModel.selectedSidebarObjectID)
    }


    //MARK: - addPage(at:to:centredOn:)
    func test_addPage_addsPageMatchingLinkToCanvas() {
        let page = self.viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id)
        self.viewModel.addPage(at: link, to: self.canvas)

        XCTAssertEqual(self.canvas.pages.count, 2)
        XCTAssertTrue(self.canvas.pages.map { $0.page }.contains(page))
    }

    func test_addPage_addedPageDoesntHaveParentIfLinkDoesntHaveSource() {
        let page = self.viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id)
        self.viewModel.addPage(at: link, to: self.canvas)

        let canvasPage = self.canvas.pages.first(where: { $0.page == page })
        XCTAssertNil(canvasPage?.parent)
    }

    func test_addPage_addingPageSetsSourcePageAsParent() {
        let page = self.viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id, source: self.canvasPage.id)
        self.viewModel.addPage(at: link, to: self.canvas)

        let canvasPage = self.canvas.pages.first(where: { $0.page == page })
        XCTAssertEqual(canvasPage?.parent, self.canvasPage)
    }


    //MARK: - createCanvas()
    func test_createCanvas_createsNewCanvas() {
        let canvas = self.viewModel.createCanvas()
        XCTAssert(self.viewModel.canvasCollection.all.contains(canvas))
    }


    //MARK: - delete(_:Canvas)
    func test_deleteCanvas_showsAlertIfCanvasHasPages() {
        let window = MockWindow()
        self.viewModel.window = window

        self.viewModel.delete(self.canvas)

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deleteCanvas_doesntShowAlertIfCanvasDoesntHaveAnyPages() {
        let window = MockWindow()
        self.viewModel.window = window

        let canvas = self.viewModel.canvasCollection.newObject()

        self.viewModel.delete(canvas)

        XCTAssertNil(window.suppliedAlert)
    }

    func test_deleteCanvas_deletesCanvasIfItDoesntHaveAnyPages() {
        let window = MockWindow()
        self.viewModel.window = window

        let canvas = self.viewModel.canvasCollection.newObject()

        self.viewModel.delete(canvas)

        XCTAssertFalse(self.viewModel.canvasCollection.all.contains(canvas))
    }

    func test_deleteCanvas_doesntDeleteCanvasIfItHasPagesButAlertReturnsCancel() throws {
        let window = MockWindow()
        self.viewModel.window = window

        self.viewModel.delete(self.canvas)

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertTrue(self.viewModel.canvasCollection.all.contains(self.canvas))
        XCTAssertTrue(self.viewModel.canvasPageCollection.all.contains(self.canvasPage))
    }

    func test_deleteCanvas_deletesCanvasIfItHasPagesAndAlertReturnsOK() throws {
        let window = MockWindow()
        self.viewModel.window = window

        self.viewModel.delete(self.canvas)

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertFalse(self.viewModel.canvasCollection.all.contains(self.canvas))
    }

    func test_deleteCanvas_deletingCanvasRemovesAllCanvasPages() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page2 = self.viewModel.pageCollection.newObject()
        let canvasPage2 = self.viewModel.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.page = page2
        }

        self.viewModel.delete(self.canvas)

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertFalse(self.viewModel.canvasCollection.all.contains(self.canvas))
        XCTAssertFalse(self.viewModel.canvasPageCollection.all.contains(self.canvasPage))
        XCTAssertFalse(self.viewModel.canvasPageCollection.all.contains(canvasPage2))
    }

    func test_deleteCanvas_setsSelectedSidebarObjectIDToNilIfCanvasWasSelected() {
        let canvas = self.viewModel.canvasCollection.newObject()
        self.viewModel.selectedSidebarObjectID = canvas.id

        self.viewModel.delete(canvas)

        XCTAssertNil(self.viewModel.selectedSidebarObjectID)
    }


    //MARK: - remove(_: CanvasPage)
    func test_removeCanvasPage_removesCanvasPageFromCanvas() {
        self.viewModel.remove(self.canvasPage)
        XCTAssertNil(self.canvasPage.canvas)
        XCTAssertFalse(self.canvas.pages.contains(self.canvasPage))
    }

    func test_removeCanvasPage_deletesCanvasPage() {
        self.viewModel.remove(self.canvasPage)
        XCTAssertNil(self.viewModel.canvasPageCollection.objectWithID(self.canvasPage.id))
    }

    func test_removeCanvasPage_removesAllChildPagesFromCanvas() {
        let canvasPageCollection = self.viewModel.canvasPageCollection
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }

        self.viewModel.remove(self.canvasPage)
        XCTAssertNil(child1.canvas)
        XCTAssertFalse(self.canvas.pages.contains(child1))
        XCTAssertNil(child2.canvas)
        XCTAssertFalse(self.canvas.pages.contains(child2))
    }

    func test_removeCanvasPage_deletesChildCanvasPages() {
        let canvasPageCollection = self.viewModel.canvasPageCollection
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }

        self.viewModel.remove(self.canvasPage)
        XCTAssertNil(canvasPageCollection.objectWithID(child1.id))
        XCTAssertNil(canvasPageCollection.objectWithID(child2.id))
    }


}
