//
//  CoppiceModelControllerPageTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 23/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

class CoppiceModelControllerPageTests: XCTestCase {
    var undoManager: UndoManager!
    var modelController: CoppiceModelController!
    var folder: Folder!

    override func setUp() {
        super.setUp()

        self.undoManager = UndoManager()
//        self.undoManager.groupsByEvent = false
        self.modelController = CoppiceModelController(undoManager: self.undoManager)

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

    func test_createPageOfType_addsItemToStartOfSuppliedFolderIfItemIsNil() {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let newPage = self.modelController.createPage(in: self.folder, below: nil)
        XCTAssertEqual(newPage.containingFolder, self.folder)
        XCTAssertEqual(self.folder.folderContents[safe: 0] as? Page, newPage)
    }

    func test_createPageOfType_addsItemInSuppliedFolderBelowSuppliedItem() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let newPage = self.modelController.createPage(in: self.folder, below: initialPage1)
        XCTAssertEqual(newPage.containingFolder, self.folder)
        XCTAssertEqual(self.folder.folderContents[safe: 1] as? Page, newPage)
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
        XCTAssertFalse(self.folder.folderContents.contains(where: { $0.id == page.id }))
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
        XCTAssertEqual(self.folder.folderContents[safe: 1] as? Page, redonePage)
        XCTAssertEqual(redonePage.containingFolder, self.folder)
    }


    //MARK: - createPages(fromFilesAt:in:below:setup:)
    func test_createPagesFromFilesAtURLs_createsNewPagesForSuppliedFileURLs() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()
        XCTAssertEqual(imagePage.content.contentType, .image)
        XCTAssertEqual(textPage.content.contentType, .text)
    }

    func test_createPagesFromFilesAtURLs_addsPagesToStartOfSuppliedFolderIfItemIsNil() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        XCTAssertEqual(imagePage.containingFolder, self.folder)
        XCTAssertEqual(textPage.containingFolder, self.folder)

        XCTAssertEqual(self.folder.folderContents[safe: 0] as? Page, imagePage)
        XCTAssertEqual(self.folder.folderContents[safe: 1] as? Page, textPage)
    }

    func test_createPagesFromFilesAtURLs_addsPagesToFolderBelowSuppliedItem() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let (imagePage, textPage) = try self.createTestPagesFromFiles(below: initialPage1)

        XCTAssertEqual(imagePage.containingFolder, self.folder)
        XCTAssertEqual(textPage.containingFolder, self.folder)

        XCTAssertEqual(self.folder.folderContents[safe: 1] as? Page, imagePage)
        XCTAssertEqual(self.folder.folderContents[safe: 2] as? Page, textPage)
    }

    func test_createPagesFromFilesAtURLs_callsSetupBlock() {
        let fileURLs = [
            self.testBundle.url(forResource: "test-image", withExtension: "png")!,
            self.testBundle.url(forResource: "test-rtf", withExtension: "rtf")!,
        ]

        var actualPages: [Page]?
        let expectedPages = self.modelController.createPages(fromFilesAt: fileURLs, in: self.folder) { pages in
            actualPages = pages
        }

        XCTAssertEqual(actualPages, expectedPages)
    }

    func test_createPagesFromFilesAtURLs_undoingRemovesPagesFromCollection() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        self.undoManager.undo()

        XCTAssertNil(self.modelController.pageCollection.objectWithID(imagePage.id))
        XCTAssertNil(self.modelController.pageCollection.objectWithID(textPage.id))
    }

    func test_createPagesFromFilesAtURLs_undoingRemovesPagesFromFolder() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        self.undoManager.undo()

        XCTAssertFalse(self.folder.folderContents.contains(where: { $0.id == imagePage.id }))
        XCTAssertFalse(self.folder.folderContents.contains(where: { $0.id == textPage.id }))
    }

    func test_createPagesFromFilesAtURLs_redoingRecreatesPagesWithSameIDsAndContent() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        self.undoManager.undo()
        XCTAssertFalse(self.modelController.pageCollection.contains(imagePage))
        XCTAssertFalse(self.modelController.pageCollection.contains(textPage))
        self.undoManager.redo()

        let redoneImagePage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(imagePage.id))
        XCTAssertEqual(redoneImagePage.title, imagePage.title)
        XCTAssertEqual(redoneImagePage.dateCreated, imagePage.dateCreated)
        XCTAssertEqual(redoneImagePage.dateModified, imagePage.dateModified)
        XCTAssertEqual(redoneImagePage.content.contentType, imagePage.content.contentType)
        XCTAssertEqual((redoneImagePage.content as? Page.Content.Image)?.image, (imagePage.content as? Page.Content.Image)?.image)

        let redoneTextPage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(textPage.id))
        XCTAssertEqual(redoneTextPage.title, textPage.title)
        XCTAssertEqual(redoneTextPage.dateCreated, textPage.dateCreated)
        XCTAssertEqual(redoneTextPage.dateModified, textPage.dateModified)
        XCTAssertEqual(redoneTextPage.content.contentType, textPage.content.contentType)
        XCTAssertEqual((redoneTextPage.content as? Page.Content.Text)?.text, (textPage.content as? Page.Content.Text)?.text)
    }

    func test_createPagesFromFilesAtURLs_redoingAddsPagesBackToFolder() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let (imagePage, textPage) = try self.createTestPagesFromFiles(below: initialPage1)

        self.undoManager.undo()

        XCTAssertFalse(self.folder.folderContents.contains(where: { $0.id == imagePage.id }))
        XCTAssertFalse(self.folder.folderContents.contains(where: { $0.id == textPage.id }))

        self.undoManager.redo()

        let redoneImagePage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(imagePage.id))
        let redoneTextPage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(textPage.id))

        XCTAssertEqual(self.folder.folderContents[safe: 1] as? Page, redoneImagePage)
        XCTAssertEqual(self.folder.folderContents[safe: 2] as? Page, redoneTextPage)
    }


    //MARK: - duplicate(_:)
    func test_duplicatePages_returnedPagesHaveDifferentIDsToSuppliedPages() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        let duplicatedPages = self.modelController.duplicatePages([imagePage, textPage])
        let duplicatedImagePage = try XCTUnwrap(duplicatedPages[safe: 0])
        let duplicatedTextPage = try XCTUnwrap(duplicatedPages[safe: 1])

        XCTAssertNotEqual(duplicatedImagePage.id, imagePage.id)
        XCTAssertNotEqual(duplicatedTextPage.id, textPage.id)
    }

    func test_duplicatePages_returnedPagesHaveSameTitleAsSuppliedPages() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        let duplicatedPages = self.modelController.duplicatePages([imagePage, textPage])
        let duplicatedImagePage = try XCTUnwrap(duplicatedPages[safe: 0])
        let duplicatedTextPage = try XCTUnwrap(duplicatedPages[safe: 1])

        XCTAssertEqual(duplicatedImagePage.title, imagePage.title)
        XCTAssertEqual(duplicatedTextPage.title, textPage.title)
    }

    func test_duplicatePages_returnedPagesHaveSameContentAsSuppliedPages() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()
        let imagePageContent = try XCTUnwrap(imagePage.content as? Page.Content.Image)
        let textPageContent = try XCTUnwrap(textPage.content as? Page.Content.Text)

        let duplicatedPages = self.modelController.duplicatePages([imagePage, textPage])
        let duplicatedImagePageContent = try XCTUnwrap(duplicatedPages[safe: 0]?.content as? Page.Content.Image)
        let duplicatedTextPageContent = try XCTUnwrap(duplicatedPages[safe: 1]?.content as? Page.Content.Text)

        XCTAssertEqual(duplicatedImagePageContent.image?.pngData(), imagePageContent.image?.pngData())
        XCTAssertEqual(duplicatedImagePageContent.imageDescription, imagePageContent.imageDescription)
        XCTAssertEqual(duplicatedTextPageContent.text, textPageContent.text)
    }

    func test_duplicatePages_returnedPagesHaveNewDates() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        let currentDate = Date()
        let duplicatedPages = self.modelController.duplicatePages([imagePage, textPage])
        let duplicatedImagePage = try XCTUnwrap(duplicatedPages[safe: 0])
        let duplicatedTextPage = try XCTUnwrap(duplicatedPages[safe: 1])

        XCTAssertGreaterThanOrEqual(duplicatedImagePage.dateCreated, currentDate)
        XCTAssertEqual(duplicatedImagePage.dateCreated, duplicatedImagePage.dateModified)
        XCTAssertGreaterThanOrEqual(duplicatedTextPage.dateCreated, currentDate)
        XCTAssertEqual(duplicatedTextPage.dateCreated, duplicatedTextPage.dateModified)
    }

    func test_duplicatePages_returnedPagesAreAddedToSameFolderAsOriginalAndBelowOriginalIfFoldersAreSame() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        let duplicatedPages = self.modelController.duplicatePages([imagePage, textPage])
        let duplicatedImagePage = try XCTUnwrap(duplicatedPages[safe: 0])
        let duplicatedTextPage = try XCTUnwrap(duplicatedPages[safe: 1])

        XCTAssertEqual(self.folder.folderContents[safe: 1] as? Page, duplicatedImagePage)
        XCTAssertEqual(self.folder.folderContents[safe: 3] as? Page, duplicatedTextPage)
    }

    func test_duplicatePages_returnedPagesAreAddedToSameFolderAsOriginalAndBelowOriginalIfFoldersAreDifferent() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        self.modelController.rootFolder.insert([imagePage], below: nil)

        let duplicatedPages = self.modelController.duplicatePages([imagePage, textPage])
        let duplicatedImagePage = try XCTUnwrap(duplicatedPages[safe: 0])
        let duplicatedTextPage = try XCTUnwrap(duplicatedPages[safe: 1])

        XCTAssertEqual(self.modelController.rootFolder.folderContents[safe: 1] as? Page, duplicatedImagePage)
        XCTAssertEqual(self.folder.folderContents[safe: 1] as? Page, duplicatedTextPage)
    }

    func test_duplicatePages_undoRemovesDuplicatedPagesFromCollection() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        let duplicatedPages = self.modelController.duplicatePages([imagePage, textPage])
        let duplicatedImagePage = try XCTUnwrap(duplicatedPages[safe: 0])
        let duplicatedTextPage = try XCTUnwrap(duplicatedPages[safe: 1])

        self.undoManager.undo()

        XCTAssertNil(self.modelController.pageCollection.objectWithID(duplicatedImagePage.id))
        XCTAssertNil(self.modelController.pageCollection.objectWithID(duplicatedTextPage.id))
    }

    func test_duplicatePages_redoAddsDuplicatedPagesBackToCollectionWithSameIDAndContent() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        let duplicatedPages = self.modelController.duplicatePages([imagePage, textPage])
        let duplicatedImagePage = try XCTUnwrap(duplicatedPages[safe: 0])
        let duplicatedTextPage = try XCTUnwrap(duplicatedPages[safe: 1])

        self.undoManager.undo()
        self.undoManager.redo()

        let redoneImagePage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(duplicatedImagePage.id))
        XCTAssertEqual(redoneImagePage.title, duplicatedImagePage.title)
        XCTAssertEqual(redoneImagePage.dateCreated, duplicatedImagePage.dateCreated)
        XCTAssertEqual(redoneImagePage.dateModified, duplicatedImagePage.dateModified)
        XCTAssertEqual(redoneImagePage.content.contentType, duplicatedImagePage.content.contentType)
        XCTAssertEqual((redoneImagePage.content as? Page.Content.Image)?.image, (duplicatedImagePage.content as? Page.Content.Image)?.image)

        let redoneTextPage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(duplicatedTextPage.id))
        XCTAssertEqual(redoneTextPage.title, duplicatedTextPage.title)
        XCTAssertEqual(redoneTextPage.dateCreated, duplicatedTextPage.dateCreated)
        XCTAssertEqual(redoneTextPage.dateModified, duplicatedTextPage.dateModified)
        XCTAssertEqual(redoneTextPage.content.contentType, duplicatedTextPage.content.contentType)
        XCTAssertEqual((redoneTextPage.content as? Page.Content.Text)?.text, (duplicatedTextPage.content as? Page.Content.Text)?.text)
    }

    func test_duplicatePages_redoAddsDuplicatedPagesBackToFolder() throws {
        let (imagePage, textPage) = try self.createTestPagesFromFiles()

        self.modelController.rootFolder.insert([imagePage], below: nil)

        let duplicatedPages = self.modelController.duplicatePages([imagePage, textPage])
        let duplicatedImagePage = try XCTUnwrap(duplicatedPages[safe: 0])
        let duplicatedTextPage = try XCTUnwrap(duplicatedPages[safe: 1])

        self.undoManager.undo()
        self.undoManager.redo()

        XCTAssertEqual(self.modelController.rootFolder.folderContents[safe: 1] as? Page, duplicatedImagePage)
        XCTAssertEqual(self.folder.folderContents[safe: 1] as? Page, duplicatedTextPage)
    }


    //MARK: - delete(_:)
    func test_deletePage_removesPageFromCollection() throws {
        let page = self.modelController.createPage(in: self.folder)

        self.modelController.delete(page)

        XCTAssertFalse(self.modelController.pageCollection.contains(page))
    }

    func test_deletePage_removesPageFromAllCanvases() throws {
        XCTFail("Re-implement")
        let page = self.modelController.createPage(in: self.folder)
        let canvas1 = self.modelController.createCanvas()
        let canvasPage1 = try XCTUnwrap(canvas1.addPages([page]).first)
        let canvas2 = self.modelController.createCanvas()
        let canvasPage2 = try XCTUnwrap(canvas2.addPages([page]).first)
        canvasPage2.frame = CGRect(x: 10, y: 20, width: 300, height: 400)
        let canvasPage3 = try XCTUnwrap(canvas2.addPages([page]).first)
//        canvasPage3.parent = canvasPage2

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

        XCTAssertFalse(self.folder.folderContents.contains(where: { $0.id == page.id }))
    }

    func test_deletePage_undoAddsPageBackToCollectionWithSameIDAndContents() throws {
        let page = self.modelController.createPage(in: self.folder)
        self.undoManager.removeAllActions()

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
        XCTFail("Re-implement")
        let page = self.modelController.createPage(in: self.folder)
        let canvas1 = self.modelController.createCanvas()
        let canvasPage1 = try XCTUnwrap(canvas1.addPages([page]).first)
        canvasPage1.frame = CGRect(x: 90, y: -50, width: 765, height: 345)
        let canvas2 = self.modelController.createCanvas()
        let canvasPage2 = try XCTUnwrap(canvas2.addPages([page]).first)
        canvasPage2.frame = CGRect(x: 10, y: 20, width: 300, height: 400)
        let canvasPage3 = try XCTUnwrap(canvas2.addPages([page]).first)
        canvasPage3.frame = CGRect(x: -10, y: -20, width: 400, height: 500)
//        canvasPage3.parent = canvasPage2
        self.undoManager.removeAllActions()

        self.modelController.delete(page)

        self.undoManager.undo()

        let redoneCanvasPage1 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage1.id))
        XCTAssertEqual(redoneCanvasPage1.frame, canvasPage1.frame)
//        XCTAssertNil(redoneCanvasPage1.parent)
        let redoneCanvasPage2 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage2.id))
        XCTAssertEqual(redoneCanvasPage2.frame, canvasPage2.frame)
//        XCTAssertNil(redoneCanvasPage2.parent)
        let redoneCanvasPage3 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage3.id))
        XCTAssertEqual(redoneCanvasPage3.frame, canvasPage3.frame)
//        XCTAssertEqual(redoneCanvasPage3.parent, redoneCanvasPage2)
    }

    func test_deletePage_undoAddsPagesBackToFolder() throws {
        let initialPage1 = self.modelController.collection(for: Page.self).newObject()
        let initialPage2 = self.modelController.collection(for: Page.self).newObject()
        self.folder.insert([initialPage1, initialPage2])

        let page = self.modelController.createPage(in: self.folder, below: initialPage1)
        self.undoManager.removeAllActions()

        self.modelController.delete(page)

        self.undoManager.undo()

        let redonePage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(page.id))
        XCTAssertEqual(redonePage.containingFolder, self.folder)
        XCTAssertEqual(self.folder.folderContents[safe: 1] as? Page, redonePage)
    }

    func test_deletePage_redoDeletesPageAgain() throws {
        let page = self.modelController.createPage(in: self.folder)
        self.undoManager.removeAllActions()

        self.modelController.delete(page)

        self.undoManager.undo()
        XCTAssertNotNil(self.modelController.pageCollection.objectWithID(page.id))
        self.undoManager.redo()

        XCTAssertNil(self.modelController.pageCollection.objectWithID(page.id))
    }

    func test_deletePage_redoRemovesPageFromCanvasesAgain() throws {
        XCTFail("Re-implement")
        let page = self.modelController.createPage(in: self.folder)
        let canvas1 = self.modelController.createCanvas()
        let canvasPage1 = try XCTUnwrap(canvas1.addPages([page]).first)
        let canvas2 = self.modelController.createCanvas()
        let canvasPage2 = try XCTUnwrap(canvas2.addPages([page]).first)
        canvasPage2.frame = CGRect(x: 10, y: 20, width: 300, height: 400)
        let canvasPage3 = try XCTUnwrap(canvas2.addPages([page]).first)
//        canvasPage3.parent = canvasPage2
        self.undoManager.removeAllActions()

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
        self.undoManager.removeAllActions()

        self.modelController.delete(page)

        self.undoManager.undo()
        XCTAssertTrue(self.folder.folderContents.contains(where: { $0.id == page.id }))
        self.undoManager.redo()

        XCTAssertFalse(self.folder.folderContents.contains(where: { $0.id == page.id }))
    }


    //MARK: - Helper
    private func createTestPagesFromFiles(below containable: FolderContainable? = nil) throws -> (imagePage: Page, textPage: Page) {
        let fileURLs = [
            self.testBundle.url(forResource: "test-image", withExtension: "png")!,
            self.testBundle.url(forResource: "test-rtf", withExtension: "rtf")!,
        ]

        let pages = self.modelController.createPages(fromFilesAt: fileURLs, in: self.folder, below: containable)
        let imagePage = try XCTUnwrap(pages[safe: 0])
        let textPage = try XCTUnwrap(pages[safe: 1])

        return (imagePage, textPage)
    }
}
