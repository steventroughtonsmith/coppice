//
//  BubblesModelControllerPageTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 23/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class BubblesModelControllerPageTests: XCTestCase {
    var undoManager: UndoManager!
    var modelController: BubblesModelController!
    var folder: Folder!

    override func setUp() {
        super.setUp()

        self.undoManager = UndoManager()
//        self.undoManager.groupsByEvent = false
        self.modelController = BubblesModelController(undoManager: self.undoManager)

        self.folder = Folder.create(in: self.modelController)
    }


    //MARK: - createPage(ofType:in:below:setup:)
    func test_createPageOfType_addsANewPageToCollection() {
        let page = self.modelController.createPage(in: self.folder)
        XCTAssertTrue(self.modelController.pageCollection.contains(page))
    }

    func test_createPageOfType_setsContentToTextContent() throws {
        let page = self.modelController.createPage(ofType: .text, in: self.folder)
        XCTAssertEqual(page.content.contentType, .text)
    }

    func test_createPageOfType_setsContentToImageContent() throws {
        let page = self.modelController.createPage(ofType: .image, in: self.folder)
        XCTAssertEqual(page.content.contentType, .image)
    }

    func test_createPageOfType_addsItemToEndOfSuppliedFolderIfItemIsNil() {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let newPage = self.modelController.createPage(in: self.folder, below: nil)
        XCTAssertEqual(newPage.containingFolder, self.folder)
        XCTAssertEqual(self.folder.contents[safe: 2] as? Page, newPage)
    }

    func test_createPageOfType_addsItemInSuppliedFolderBelowSuppliedItem() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let newPage = self.modelController.createPage(in: self.folder, below: initialPage1)
        XCTAssertEqual(newPage.containingFolder, self.folder)
        XCTAssertEqual(self.folder.contents[safe: 1] as? Page, newPage)
    }

    func test_createPageOfType_callsSetupBlockWithCreatedPage() throws {
        var actualPage: Page? = nil
        let expectedPage = self.modelController.createPage(in: self.folder) { createdPage in
            actualPage = createdPage
        }

        XCTAssertEqual(expectedPage, actualPage)
    }

    func test_createPageOfType_undoingRemovesPageFromCollection() {
        let page = self.modelController.createPage(in: self.folder)
        self.undoManager.undo()
        XCTAssertNil(self.modelController.pageCollection.objectWithID(page.id))
    }

    func test_createPageOfType_undoingRemovesPageFromFolder() {
        let page = self.modelController.createPage(in: self.folder)

        self.undoManager.undo()
        XCTAssertFalse(self.folder.contents.contains(where: { $0.id == page.id }))
    }

    func test_createPageOfType_redoRecreatesPageWithSameIDAndProperties() throws {
        let page = self.modelController.createPage(in: self.folder)

        self.undoManager.undo()
        XCTAssertNil(self.modelController.pageCollection.objectWithID(page.id))
        self.undoManager.redo()

        let redonePage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(page.id))

        XCTAssertEqual(redonePage.title, page.title)
        XCTAssertEqual(redonePage.dateCreated, page.dateCreated)
        XCTAssertEqual(redonePage.dateModified, page.dateModified)
        XCTAssertEqual(redonePage.content.contentType, page.content.contentType)
        XCTAssertEqual(redonePage.content.page, redonePage)
    }

    func test_createPageOfType_redoRecreatesPageInFolder() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let page = self.modelController.createPage(in: self.folder, below: initialPage1)

        self.undoManager.undo()
        XCTAssertNil(self.modelController.pageCollection.objectWithID(page.id))
        self.undoManager.redo()

        let redonePage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(page.id))
        XCTAssertEqual(self.folder.contents[safe: 1] as? Page, redonePage)
        XCTAssertEqual(redonePage.containingFolder, self.folder)
    }


    //MARK: - createPages(fromFilesAt:in:below:setup:)
    func test_createPagesFromFilesAtURLs_createsNewPagesForSuppliedFileURLs() {
        let fileURLs = [
            self.testBundle.url(forResource: "test-image", withExtension: "png")!,
            self.testBundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.modelController.createPages(fromFilesAt: fileURLs, in: self.folder)
        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages[safe: 0]?.content.contentType, .image)
        XCTAssertEqual(pages[safe: 1]?.content.contentType, .text)
    }

    func test_createPagesFromFilesAtURLs_addsPagesToEndOfSuppliedFolderIfItemIsNil() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let fileURLs = [
            self.testBundle.url(forResource: "test-image", withExtension: "png")!,
            self.testBundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.modelController.createPages(fromFilesAt: fileURLs, in: self.folder, below: nil)
        let imagePage = try XCTUnwrap(pages[safe: 0])
        let textPage = try XCTUnwrap(pages[safe: 1])

        XCTAssertEqual(imagePage.containingFolder, self.folder)
        XCTAssertEqual(textPage.containingFolder, self.folder)

        XCTAssertEqual(self.folder.contents[safe:2] as? Page, imagePage)
        XCTAssertEqual(self.folder.contents[safe:3] as? Page, textPage)
    }

    func test_createPagesFromFilesAtURLs_addsPagesToFolderBelowSuppliedItem() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let fileURLs = [
            self.testBundle.url(forResource: "test-image", withExtension: "png")!,
            self.testBundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.modelController.createPages(fromFilesAt: fileURLs, in: self.folder, below: initialPage1)
        let imagePage = try XCTUnwrap(pages[safe: 0])
        let textPage = try XCTUnwrap(pages[safe: 1])

        XCTAssertEqual(imagePage.containingFolder, self.folder)
        XCTAssertEqual(textPage.containingFolder, self.folder)

        XCTAssertEqual(self.folder.contents[safe:1] as? Page, imagePage)
        XCTAssertEqual(self.folder.contents[safe:2] as? Page, textPage)
    }

    func test_createPagesFromFilesAtURLs_callsSetupBlock() {
        let fileURLs = [
            self.testBundle.url(forResource: "test-image", withExtension: "png")!,
            self.testBundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        var actualPages: [Page]?
        let expectedPages = self.modelController.createPages(fromFilesAt: fileURLs, in: self.folder) { pages in
            actualPages = pages
        }

        XCTAssertEqual(actualPages, expectedPages)
    }

    func test_createPagesFromFilesAtURLs_undoingRemovesPagesFromCollection() throws {
        let fileURLs = [
            self.testBundle.url(forResource: "test-image", withExtension: "png")!,
            self.testBundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.modelController.createPages(fromFilesAt: fileURLs, in: self.folder)
        let imagePage = try XCTUnwrap(pages[safe: 0])
        let textPage = try XCTUnwrap(pages[safe: 1])

        self.undoManager.undo()

        XCTAssertNil(self.modelController.pageCollection.objectWithID(imagePage.id))
        XCTAssertNil(self.modelController.pageCollection.objectWithID(textPage.id))
    }

    func test_createPagesFromFilesAtURLs_undoingRemovesPagesFromFolder() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let fileURLs = [
            self.testBundle.url(forResource: "test-image", withExtension: "png")!,
            self.testBundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.modelController.createPages(fromFilesAt: fileURLs, in: self.folder)
        let imagePage = try XCTUnwrap(pages[safe: 0])
        let textPage = try XCTUnwrap(pages[safe: 1])

        self.undoManager.undo()

        XCTAssertFalse(self.folder.contents.contains(where: { $0.id == imagePage.id }))
        XCTAssertFalse(self.folder.contents.contains(where: { $0.id == textPage.id }))
    }

    func test_createPagesFromFilesAtURLs_redoingRecreatesPagesWithSameIDsAndContent() throws {
        let fileURLs = [
            self.testBundle.url(forResource: "test-image", withExtension: "png")!,
            self.testBundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.modelController.createPages(fromFilesAt: fileURLs, in: self.folder)
        let imagePage = try XCTUnwrap(pages.first)
        let textPage = try XCTUnwrap(pages.last)

        self.undoManager.undo()
        XCTAssertNil(self.modelController.pageCollection.contains(imagePage))
        XCTAssertNil(self.modelController.pageCollection.contains(textPage))
        self.undoManager.redo()

        let redoneImagePage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(imagePage.id))
        XCTAssertEqual(redoneImagePage.title, imagePage.title)
        XCTAssertEqual(redoneImagePage.dateCreated, imagePage.dateCreated)
        XCTAssertEqual(redoneImagePage.dateModified, imagePage.dateModified)
        XCTAssertEqual(redoneImagePage.content.contentType, imagePage.content.contentType)
        XCTAssertEqual((redoneImagePage.content as? ImagePageContent)?.image, (imagePage.content as? ImagePageContent)?.image)

        let redoneTextPage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(textPage.id))
        XCTAssertEqual(redoneTextPage.title, textPage.title)
        XCTAssertEqual(redoneTextPage.dateCreated, textPage.dateCreated)
        XCTAssertEqual(redoneTextPage.dateModified, textPage.dateModified)
        XCTAssertEqual(redoneTextPage.content.contentType, textPage.content.contentType)
        XCTAssertEqual((redoneTextPage.content as? TextPageContent)?.text, (textPage.content as? TextPageContent)?.text)
    }

    func test_createPagesFromFilesAtURLs_redoingAddsPagesBackToFolder() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let fileURLs = [
            self.testBundle.url(forResource: "test-image", withExtension: "png")!,
            self.testBundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.modelController.createPages(fromFilesAt: fileURLs, in: self.folder, below: initialPage1)
        let imagePage = try XCTUnwrap(pages[safe: 0])
        let textPage = try XCTUnwrap(pages[safe: 1])

        self.undoManager.undo()

        XCTAssertFalse(self.folder.contents.contains(where: { $0.id == imagePage.id }))
        XCTAssertFalse(self.folder.contents.contains(where: { $0.id == textPage.id }))

        self.undoManager.redo()

        let redoneImagePage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(imagePage.id))
        let redoneTextPage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(textPage.id))

        XCTAssertEqual(self.folder.contents[safe: 1] as? Page, redoneImagePage)
        XCTAssertEqual(self.folder.contents[safe: 2] as? Page, redoneTextPage)
    }


    //MARK: - delete(_:)
    func test_deletePage_removesPageFromCollection() throws {
        let page = self.modelController.createPage(in: self.folder)

        self.modelController.delete(page)

        XCTAssertFalse(self.modelController.pageCollection.contains(page))
    }

    func test_deletePage_removesPageFromAllCanvases() throws {
        let page = self.modelController.createPage(in: self.folder)
        let canvas1 = self.modelController.createCanvas()
        let canvasPage1 = try XCTUnwrap(canvas1.addPages([page]).first)
        let canvas2 = self.modelController.createCanvas()
        let canvasPage2 = try XCTUnwrap(canvas2.addPages([page]).first)
        canvasPage2.frame = CGRect(x: 10, y: 20, width: 300, height: 400)
        let canvasPage3 = try XCTUnwrap(canvas2.addPages([page]).first)
        canvasPage3.parent = canvasPage2

        self.modelController.delete(page)

        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage1))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage2))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage3))

        XCTAssertFalse(canvas1.pages.contains(canvasPage1))
        XCTAssertFalse(canvas2.pages.contains(canvasPage2))
        XCTAssertFalse(canvas2.pages.contains(canvasPage3))
    }

    func test_deletePage_removesPageFromContainingFolder() throws {
        let page = self.modelController.createPage(in: self.folder)

        self.modelController.delete(page)

        XCTAssertFalse(self.folder.contents.contains(where: { $0.id == page.id }))
    }

    func test_deletePage_undoAddsPageBackToCollectionWithSameIDAndContents() throws {
        let page = self.modelController.createPage(in: self.folder)

        self.modelController.delete(page)

        self.undoManager.undo()

        let redonePage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(page.id))

        XCTAssertEqual(redonePage.title, page.title)
        XCTAssertEqual(redonePage.dateCreated, page.dateCreated)
        XCTAssertEqual(redonePage.dateModified, page.dateModified)
        XCTAssertEqual(redonePage.content.contentType, page.content.contentType)
        XCTAssertEqual(redonePage.content.page, redonePage)
    }

    func test_deletePage_undoAddsPageBackToAnyCanvasesWithSameIDsAndProperties() throws {
        let page = self.modelController.createPage(in: self.folder)
        let canvas1 = self.modelController.createCanvas()
        let canvasPage1 = try XCTUnwrap(canvas1.addPages([page]).first)
        canvasPage1.frame = CGRect(x: 90, y: -50, width: 765, height: 345)
        let canvas2 = self.modelController.createCanvas()
        let canvasPage2 = try XCTUnwrap(canvas2.addPages([page]).first)
        canvasPage2.frame = CGRect(x: 10, y: 20, width: 300, height: 400)
        let canvasPage3 = try XCTUnwrap(canvas2.addPages([page]).first)
        canvasPage3.frame = CGRect(x: -10, y: -20, width: 400, height: 500)
        canvasPage3.parent = canvasPage2

        self.modelController.delete(page)

        self.undoManager.undo()

        let redoneCanvasPage1 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage1.id))
        XCTAssertEqual(redoneCanvasPage1.frame, canvasPage1.frame)
        XCTAssertNil(redoneCanvasPage1.parent)
        let redoneCanvasPage2 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage2.id))
        XCTAssertEqual(redoneCanvasPage2.frame, canvasPage2.frame)
        XCTAssertNil(redoneCanvasPage2.parent)
        let redoneCanvasPage3 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage3.id))
        XCTAssertEqual(redoneCanvasPage3.frame, canvasPage3.frame)
        XCTAssertEqual(redoneCanvasPage3.parent, redoneCanvasPage2)
    }

    func test_deletePage_undoAddsPagesBackToFolder() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let page = self.modelController.createPage(in: self.folder, below: initialPage1)

        self.modelController.delete(page)

        self.undoManager.undo()

        let redonePage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(page.id))
        XCTAssertEqual(redonePage.containingFolder, self.folder)
        XCTAssertEqual(self.folder.contents[safe: 1] as? Page, redonePage)
    }

    func test_deletePage_redoDeletesPageAgain() throws {
        let page = self.modelController.createPage(in: self.folder)

        self.modelController.delete(page)

        self.undoManager.undo()
        XCTAssertNotNil(self.modelController.pageCollection.objectWithID(page.id))
        self.undoManager.redo()

        XCTAssertNil(self.modelController.pageCollection.objectWithID(page.id))
    }

    func test_deletePage_redoRemovesPageFromCanvasesAgain() throws {
        let page = self.modelController.createPage(in: self.folder)
        let canvas1 = self.modelController.createCanvas()
        let canvasPage1 = try XCTUnwrap(canvas1.addPages([page]).first)
        let canvas2 = self.modelController.createCanvas()
        let canvasPage2 = try XCTUnwrap(canvas2.addPages([page]).first)
        canvasPage2.frame = CGRect(x: 10, y: 20, width: 300, height: 400)
        let canvasPage3 = try XCTUnwrap(canvas2.addPages([page]).first)
        canvasPage3.parent = canvasPage2

        self.modelController.delete(page)

        self.undoManager.undo()
        XCTAssertNotNil(self.modelController.canvasPageCollection.objectWithID(canvasPage1.id))
        XCTAssertNotNil(self.modelController.canvasPageCollection.objectWithID(canvasPage2.id))
        XCTAssertNotNil(self.modelController.canvasPageCollection.objectWithID(canvasPage3.id))
        self.undoManager.redo()

        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(canvasPage1.id))
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(canvasPage2.id))
        XCTAssertNil(self.modelController.canvasPageCollection.objectWithID(canvasPage3.id))
    }

    func test_deletePage_redoRemovesPageFromFolderAgain() throws {
        let page = self.modelController.createPage(in: self.folder)

        self.modelController.delete(page)

        self.undoManager.undo()
        XCTAssertTrue(self.folder.contents.contains(where: { $0.id == page.id }))
        self.undoManager.redo()

        XCTAssertFalse(self.folder.contents.contains(where: { $0.id == page.id }))
    }
}
