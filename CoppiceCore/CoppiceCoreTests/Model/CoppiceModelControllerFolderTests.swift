//
//  CoppiceModelControllerFolderTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 23/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

class CoppiceModelControllerFolderTests: XCTestCase {
    var undoManager: UndoManager!
    var modelController: CoppiceModelController!
    var parentFolder: Folder!

    override func setUp() {
        super.setUp()

        self.undoManager = UndoManager()
        self.modelController = CoppiceModelController(undoManager: self.undoManager)
        self.parentFolder = Folder.create(in: self.modelController)
    }


    //MARK: - .rootFolder
    func test_rootFolder_createsNewRootFolderIfNotInSettings() {
        let folderCollection = self.modelController.collection(for: Folder.self)
        XCTAssertEqual(folderCollection.all.count, 1)
        XCTAssertEqual(folderCollection.all.first, self.parentFolder)

        let rootFolder = self.modelController.rootFolder

        XCTAssertNotNil(folderCollection.objectWithID(rootFolder.id))
    }

    func test_rootFolder_createsNewRootFolderIfIDInSettingsNotFoundInCollection() {
        let folderCollection = self.modelController.collection(for: Folder.self)
        XCTAssertEqual(folderCollection.all.count, 1)
        XCTAssertEqual(folderCollection.all.first, self.parentFolder)

        self.modelController.settings.set(Folder.modelID(with: UUID()), for: .rootFolder)

        let rootFolder = self.modelController.rootFolder

        XCTAssertNotNil(folderCollection.objectWithID(rootFolder.id))
    }

    func test_rootFolder_returnsExistingRootFolderIfItExistsAndSetInSettings() {
        let folderCollection = self.modelController.collection(for: Folder.self)
        let expectedRootFolder = folderCollection.newObject()

        self.modelController.settings.set(expectedRootFolder.id, for: .rootFolder)

        let rootFolder = self.modelController.rootFolder

        XCTAssertEqual(rootFolder, expectedRootFolder)
    }


    //MARK: - createFolder(in:below:setup:)
    func test_createFolder_addsANewFolderToCollection() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)
        XCTAssertTrue(self.modelController.folderCollection.contains(folder))
    }

    func test_createFolder_addsFolderToStartOfSuppliedFolderIfItemIsNil() throws {
        let initialPage1 = Page.create(in: self.modelController)
        let initialPage2 = Page.create(in: self.modelController)
        self.parentFolder.insert([initialPage1, initialPage2])

        let folder = self.modelController.createFolder(in: self.parentFolder, below: nil)
        XCTAssertEqual(self.parentFolder.contents[safe: 0] as? Folder, folder)
    }

    func test_createFolder_addsFolderInSuppliedFolderBelowSuppliedItem() throws {
        let initialPage1 = Page.create(in: self.modelController)
        let initialPage2 = Page.create(in: self.modelController)
        self.parentFolder.insert([initialPage1, initialPage2])

        let folder = self.modelController.createFolder(in: self.parentFolder, below: initialPage1)
        XCTAssertEqual(self.parentFolder.contents[safe: 1] as? Folder, folder)
    }

    func test_createFolder_callsSetupBlockWithCreatedFolder() throws {
        var actualFolder: Folder? = nil
        let expectedFolder = self.modelController.createFolder(in: self.parentFolder) { folder in
            actualFolder = folder
        }
        XCTAssertEqual(actualFolder, expectedFolder)
    }

    func test_createFolder_undoRemovesFolderFromCollection() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)

        self.undoManager.undo()

        XCTAssertFalse(self.modelController.folderCollection.contains(folder))
    }

    func test_createFolder_undoingRemovesFolderFromParent() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)

        self.undoManager.undo()

        XCTAssertFalse(self.parentFolder.contents.contains(where: { $0.id == folder.id }))
    }

    func test_createFolder_redoingRecreatesFolderWithSameIDAndProperties() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)

        self.undoManager.undo()
        XCTAssertFalse(self.modelController.folderCollection.contains(folder))
        self.undoManager.redo()

        let redoneFolder = try XCTUnwrap(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertEqual(folder.title, redoneFolder.title)
    }

    func test_createFolder_redoingAddsFolderBackToParentAtSameLocation() throws {
        let initialPage1 = Page.create(in: self.modelController)
        let initialPage2 = Page.create(in: self.modelController)
        self.parentFolder.insert([initialPage1, initialPage2])
        self.undoManager.removeAllActions()

        let folder = self.modelController.createFolder(in: self.parentFolder, below: initialPage1)

        self.undoManager.undo()
        XCTAssertFalse(self.parentFolder.contents.contains(where: { $0.id == folder.id }))
        self.undoManager.redo()

        let redoneFolder = try XCTUnwrap(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertEqual(redoneFolder.containingFolder, self.parentFolder)
        XCTAssertEqual(self.parentFolder.contents[safe: 1] as? Folder, redoneFolder)
    }


    //MARK: - delete(_: Folder)
    func test_deleteFolder_removesFolderFromCollection() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)

        self.modelController.delete(folder)

        XCTAssertFalse(self.modelController.folderCollection.contains(folder))
    }

    func test_deleteFolder_removesFolderFromParent() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)

        self.modelController.delete(folder)

        XCTAssertFalse(self.parentFolder.contents.contains(where: { $0.id == folder.id }))
    }

    func test_deleteFolder_removesContentsOfFolder() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)
        let page1 = Page.create(in: self.modelController)
        let subFolder1 = Folder.create(in: self.modelController)
        let page2 = Page.create(in: self.modelController)
        folder.insert([page1, subFolder1, page2])

        self.modelController.delete(folder)

        XCTAssertFalse(self.modelController.folderCollection.contains(subFolder1))
        XCTAssertFalse(self.modelController.pageCollection.contains(page1))
        XCTAssertFalse(self.modelController.pageCollection.contains(page2))
    }

    func test_deleteFolder_alsoRemovesContentsOfAnyContainedFolders() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)
        let subFolder1 = Folder.create(in: self.modelController)
        let subPage1 = Page.create(in: self.modelController)
        let subPage2 = Page.create(in: self.modelController)
        subFolder1.insert([subPage1, subPage2])
        folder.insert([subFolder1])

        self.modelController.delete(folder)

        XCTAssertFalse(self.modelController.folderCollection.contains(subFolder1))
        XCTAssertFalse(self.modelController.pageCollection.contains(subPage1))
        XCTAssertFalse(self.modelController.pageCollection.contains(subPage2))
    }

    func test_deleteFolder_anyPagesContainedInFolderAreAlsoRemovedFromCanvases() throws {
        let canvas1 = Canvas.create(in: self.modelController)
        let canvas2 = Canvas.create(in: self.modelController)
        let folder = self.modelController.createFolder(in: self.parentFolder)
        let page1 = Page.create(in: self.modelController)
        let page2 = Page.create(in: self.modelController)

        let canvasPage1 = try XCTUnwrap(canvas1.addPages([page1]).first)
        let canvasPage2 = try XCTUnwrap(canvas2.addPages([page1]).first)
        let canvasPage3 = try XCTUnwrap(canvas2.addPages([page2]).first)
        folder.insert([page1, page2])

        self.modelController.delete(folder)

        XCTAssertFalse(self.modelController.pageCollection.contains(page1))
        XCTAssertFalse(self.modelController.pageCollection.contains(page2))

        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage1))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage2))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage3))
    }

    func test_deleteFolder_undoingAddsFolderBackToCollectionWithSameIDAndProperties() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)
        folder.title = "Foo Bar"
        folder.dateCreated = Date(timeIntervalSinceNow: 60)
        self.undoManager.removeAllActions()

        self.modelController.delete(folder)

        self.undoManager.undo()

        let undoneFolder = try XCTUnwrap(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertEqual(undoneFolder.title, folder.title)
        XCTAssertEqual(undoneFolder.dateCreated, folder.dateCreated)
    }

    func test_deleteFolder_undoingAddsFolderBacktoParentAtSameLocation() throws {
        let initialPage1 = Page.create(in: self.modelController)
        let initialPage2 = Page.create(in: self.modelController)
        self.parentFolder.insert([initialPage1, initialPage2])
        let folder = self.modelController.createFolder(in: self.parentFolder, below: initialPage1)
        self.undoManager.removeAllActions()

        self.modelController.delete(folder)

        self.undoManager.undo()

        let undoneFolder = try XCTUnwrap(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertEqual(self.parentFolder.contents[safe: 1] as? Folder, undoneFolder)
        XCTAssertEqual(undoneFolder.containingFolder, self.parentFolder)
    }

    func test_deleteFolder_undoingAddsContentsOfFolderBackWithSameIDsAndProperties() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)
        let page1 = Page.create(in: self.modelController) { $0.title = "Hello World" }
        let subFolder1 = Folder.create(in: self.modelController) { $0.title = "Folders!" }
        let page2 = Page.create(in: self.modelController) { $0.title = "Foo Bar" }

        folder.insert([page1, subFolder1, page2])
        self.undoManager.removeAllActions()

        self.modelController.delete(folder)

        self.undoManager.undo()

        let undonePage1 = try XCTUnwrap(self.modelController.pageCollection.objectWithID(page1.id))
        XCTAssertEqual(undonePage1.title, page1.title)
        XCTAssertEqual(undonePage1.dateModified, page1.dateModified)
        XCTAssertEqual(undonePage1.dateCreated, page1.dateCreated)
        let undoneSubFolder1 = try XCTUnwrap(self.modelController.folderCollection.objectWithID(subFolder1.id))
        XCTAssertEqual(undoneSubFolder1.title, subFolder1.title)
        XCTAssertEqual(undoneSubFolder1.dateModified, subFolder1.dateModified)
        XCTAssertEqual(undoneSubFolder1.dateCreated, subFolder1.dateCreated)
        let undonePage2 = try XCTUnwrap(self.modelController.pageCollection.objectWithID(page2.id))
        XCTAssertEqual(undonePage2.title, page2.title)
        XCTAssertEqual(undonePage2.dateModified, page2.dateModified)
        XCTAssertEqual(undonePage2.dateCreated, page2.dateCreated)

        let undoneFolder = try XCTUnwrap(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertEqual(undoneFolder.contents[safe: 0] as? Page, undonePage1)
        XCTAssertEqual(undonePage1.containingFolder, undoneFolder)
        XCTAssertEqual(undoneFolder.contents[safe: 1] as? Folder, undoneSubFolder1)
        XCTAssertEqual(undonePage1.containingFolder, undoneFolder)
        XCTAssertEqual(undoneFolder.contents[safe: 2] as? Page, undonePage2)
        XCTAssertEqual(undonePage2.containingFolder, undoneFolder)
    }

    func test_deleteFolder_undoingAddsContentsOfAnyContainedFoldersBack() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)
        let subFolder1 = Folder.create(in: self.modelController)
        let subPage1 = Page.create(in: self.modelController)
        let subPage2 = Page.create(in: self.modelController)

        subFolder1.insert([subPage1, subPage2])
        folder.insert([subFolder1])
        self.undoManager.removeAllActions()

        self.modelController.delete(folder)

        self.undoManager.undo()
        let undoneSubFolder = try XCTUnwrap(self.modelController.folderCollection.objectWithID(subFolder1.id))
        let undoneSubPage1 = try XCTUnwrap(self.modelController.pageCollection.objectWithID(subPage1.id))
        let undoneSubPage2 = try XCTUnwrap(self.modelController.pageCollection.objectWithID(subPage2.id))

        XCTAssertEqual(undoneSubFolder.contents[safe: 0] as? Page, undoneSubPage1)
        XCTAssertEqual(undoneSubPage1.containingFolder, undoneSubFolder)
        XCTAssertEqual(undoneSubFolder.contents[safe: 1] as? Page, undoneSubPage2)
        XCTAssertEqual(undoneSubPage2.containingFolder, undoneSubFolder)
    }

    func test_deleteFolder_undoingAddsAnyContainedPagesThatWereOnCanvasesBackToThoseCanvases() throws {
        let canvas1 = Canvas.create(in: self.modelController)
        let canvas2 = Canvas.create(in: self.modelController)
        let folder = self.modelController.createFolder(in: self.parentFolder)
        let page1 = Page.create(in: self.modelController)
        let page2 = Page.create(in: self.modelController)

        let canvasPage1 = try XCTUnwrap(canvas1.addPages([page1]).first)
        let canvasPage2 = try XCTUnwrap(canvas2.addPages([page1]).first)
        let canvasPage3 = try XCTUnwrap(canvas2.addPages([page2]).first)

        folder.insert([page1, page2])
        self.undoManager.removeAllActions()

        self.modelController.delete(folder)

        self.undoManager.undo()

        let undonePage1 = try XCTUnwrap(self.modelController.pageCollection.objectWithID(page1.id))
        let undonePage2 = try XCTUnwrap(self.modelController.pageCollection.objectWithID(page2.id))

        let undoneCanvasPage1 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage1.id))
        let undoneCanvasPage2 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage2.id))
        let undoneCanvasPage3 = try XCTUnwrap(self.modelController.canvasPageCollection.objectWithID(canvasPage3.id))

        XCTAssertEqual(undoneCanvasPage1.page, undonePage1)
        XCTAssertEqual(undoneCanvasPage1.canvas, canvas1)

        XCTAssertEqual(undoneCanvasPage2.page, undonePage1)
        XCTAssertEqual(undoneCanvasPage2.canvas, canvas2)

        XCTAssertEqual(undoneCanvasPage3.page, undonePage2)
        XCTAssertEqual(undoneCanvasPage3.canvas, canvas2)
    }

    func test_deleteFolder_redoingRemovesFolderFromCollectionAgain() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)
        self.undoManager.removeAllActions()

        self.modelController.delete(folder)

        self.undoManager.undo()
        XCTAssertNotNil(self.modelController.folderCollection.objectWithID(folder.id))
        self.undoManager.redo()

        XCTAssertNil(self.modelController.folderCollection.objectWithID(folder.id))
    }

    func test_deleteFolder_redoingRemovesFolderFromParentAgain() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)
        self.undoManager.removeAllActions()

        self.modelController.delete(folder)

        self.undoManager.undo()
        XCTAssertTrue(self.parentFolder.contents.contains(where: { $0.id == folder.id }))
        self.undoManager.redo()

        XCTAssertFalse(self.parentFolder.contents.contains(where: { $0.id == folder.id }))
    }

    func test_deleteFolder_redoingRemovesContentsOfFolderAgain() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)
        let page1 = Page.create(in: self.modelController)
        let subFolder1 = Folder.create(in: self.modelController)
        let page2 = Page.create(in: self.modelController)

        folder.insert([page1, subFolder1, page2])
        self.undoManager.removeAllActions()

        self.modelController.delete(folder)

        self.undoManager.undo()
        XCTAssertTrue(self.modelController.folderCollection.contains(subFolder1))
        XCTAssertTrue(self.modelController.pageCollection.contains(page1))
        XCTAssertTrue(self.modelController.pageCollection.contains(page2))
        self.undoManager.redo()

        XCTAssertFalse(self.modelController.folderCollection.contains(subFolder1))
        XCTAssertFalse(self.modelController.pageCollection.contains(page1))
        XCTAssertFalse(self.modelController.pageCollection.contains(page2))
    }

    func test_deleteFolder_redoingRemovesContentsOfAnyContainedFoldersAgain() throws {
        let folder = self.modelController.createFolder(in: self.parentFolder)
        let subFolder1 = Folder.create(in: self.modelController)
        let subPage1 = Page.create(in: self.modelController)
        let subPage2 = Page.create(in: self.modelController)

        subFolder1.insert([subPage1, subPage2])
        folder.insert([subFolder1])
        self.undoManager.removeAllActions()

        self.modelController.delete(folder)

        self.undoManager.undo()
        XCTAssertTrue(self.modelController.folderCollection.contains(subFolder1))
        XCTAssertTrue(self.modelController.pageCollection.contains(subPage1))
        XCTAssertTrue(self.modelController.pageCollection.contains(subPage2))
        self.undoManager.redo()

        XCTAssertFalse(self.modelController.folderCollection.contains(subFolder1))
        XCTAssertFalse(self.modelController.pageCollection.contains(subPage1))
        XCTAssertFalse(self.modelController.pageCollection.contains(subPage2))
    }

    func test_deleteFolder_redoingRemovesAnyContainedPagesFromCanvasesAgain() throws {
        let canvas1 = Canvas.create(in: self.modelController)
        let canvas2 = Canvas.create(in: self.modelController)
        let folder = self.modelController.createFolder(in: self.parentFolder)
        let page1 = Page.create(in: self.modelController)
        let page2 = Page.create(in: self.modelController)

        let canvasPage1 = try XCTUnwrap(canvas1.addPages([page1]).first)
        let canvasPage2 = try XCTUnwrap(canvas2.addPages([page1]).first)
        let canvasPage3 = try XCTUnwrap(canvas2.addPages([page2]).first)

        folder.insert([page1, page2])
        self.undoManager.removeAllActions()

        self.modelController.delete(folder)

        self.undoManager.undo()
        XCTAssertTrue(self.modelController.pageCollection.contains(page1))
        XCTAssertTrue(self.modelController.pageCollection.contains(page2))
        XCTAssertTrue(self.modelController.canvasPageCollection.contains(canvasPage1))
        XCTAssertTrue(self.modelController.canvasPageCollection.contains(canvasPage2))
        XCTAssertTrue(self.modelController.canvasPageCollection.contains(canvasPage3))
        self.undoManager.redo()

        XCTAssertFalse(self.modelController.pageCollection.contains(page1))
        XCTAssertFalse(self.modelController.pageCollection.contains(page2))

        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage1))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage2))
        XCTAssertFalse(self.modelController.canvasPageCollection.contains(canvasPage3))
    }


    //MARK: - delete(_:[FolderContainable])
    func test_deleteFolderItems_deletesSinglePage() throws {
        let page = self.modelController.createPage(in: self.modelController.rootFolder)
        self.modelController.delete([page])

        XCTAssertNil(self.modelController.pageCollection.objectWithID(page.id))
        XCTAssertEqual(self.modelController.rootFolder.contents.count, 0)
    }

    func test_deleteFolderItems_deletesSingleFolder() throws {
        let folder = self.modelController.createFolder(in: self.modelController.rootFolder)
        self.modelController.delete([folder])

        XCTAssertNil(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertEqual(self.modelController.rootFolder.contents.count, 0)
    }

    func test_deleteFolderItems_deletesMultipleItems() throws {
        let page1 = self.modelController.createPage(in: self.modelController.rootFolder)
        let folder = self.modelController.createFolder(in: self.modelController.rootFolder)
        let subPage = self.modelController.createPage(in: folder)
        let page2 = self.modelController.createPage(in: self.modelController.rootFolder)

        self.modelController.delete([page1, folder, subPage])

        XCTAssertNil(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertNil(self.modelController.pageCollection.objectWithID(page1.id))
        XCTAssertNil(self.modelController.pageCollection.objectWithID(subPage.id))

        XCTAssertNotNil(self.modelController.pageCollection.objectWithID(page2.id))
    }

    func test_deleteFolderItems_undoingSinglePageDeleteRestoresPage() throws {
        let page = self.modelController.createPage(in: self.modelController.rootFolder)
        page.title = "Foo Bar Baz"
        self.undoManager.removeAllActions()

        self.modelController.delete([page])
        self.undoManager.undo()

        let undonePage = try XCTUnwrap(self.modelController.pageCollection.objectWithID(page.id))
        XCTAssertEqual(undonePage.title, page.title)
        XCTAssertEqual(undonePage.dateCreated, page.dateCreated)
        XCTAssertEqual(undonePage.dateModified, page.dateModified)
        XCTAssertEqual(undonePage.containingFolder, self.modelController.rootFolder)

        XCTAssertEqual(self.modelController.rootFolder.contents[safe: 0] as? Page, undonePage)
    }

    func test_deleteFolderItems_undoingSingleFolderDeleteRestoresFolder() throws {
        let folder = self.modelController.createFolder(in: self.modelController.rootFolder)
        folder.title = "Foo Bar Baz"
        self.undoManager.removeAllActions()

        self.modelController.delete([folder])
        self.undoManager.undo()

        let undoneFolder = try XCTUnwrap(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertEqual(undoneFolder.title, folder.title)
        XCTAssertEqual(undoneFolder.dateCreated, folder.dateCreated)
        XCTAssertEqual(undoneFolder.containingFolder, self.modelController.rootFolder)

        XCTAssertEqual(self.modelController.rootFolder.contents[safe: 0] as? Folder, undoneFolder)
    }

    func test_deleteFolderItems_undoingMultipleItemDeletionRestoresAllItems() throws {
        let page1 = self.modelController.createPage(in: self.modelController.rootFolder)
        let folder = self.modelController.createFolder(in: self.modelController.rootFolder)
        let subPage = self.modelController.createPage(in: folder)
        let page2 = self.modelController.createPage(in: self.modelController.rootFolder)
        self.undoManager.removeAllActions()

        self.modelController.delete([page1, folder, subPage])
        self.undoManager.undo()

        XCTAssertNotNil(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertNotNil(self.modelController.pageCollection.objectWithID(page1.id))
        XCTAssertNotNil(self.modelController.pageCollection.objectWithID(subPage.id))

        XCTAssertNotNil(self.modelController.pageCollection.objectWithID(page2.id))
    }

    func test_deleteFolderItems_redoingSinglePageDeleteDeletesPageAgain() throws {
        let page = self.modelController.createPage(in: self.modelController.rootFolder)
        self.undoManager.removeAllActions()

        self.modelController.delete([page])
        self.undoManager.undo()
        XCTAssertNotNil(self.modelController.pageCollection.objectWithID(page.id))
        self.undoManager.redo()
        XCTAssertNil(self.modelController.pageCollection.objectWithID(page.id))
        XCTAssertEqual(self.modelController.rootFolder.contents.count, 0)
    }

    func test_deleteFolderItems_redoingSingleFolderDeleteDeletesFolderAgain() throws {
        let folder = self.modelController.createFolder(in: self.modelController.rootFolder)
        self.undoManager.removeAllActions()

        self.modelController.delete([folder])
        self.undoManager.undo()
        XCTAssertNotNil(self.modelController.folderCollection.objectWithID(folder.id))
        self.undoManager.redo()
        XCTAssertNil(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertEqual(self.modelController.rootFolder.contents.count, 0)
    }

    func test_deleteFolderItems_redoingMultipleItemDeletionDeletsAllItemsAgain() throws {
        let page1 = self.modelController.createPage(in: self.modelController.rootFolder)
        let folder = self.modelController.createFolder(in: self.modelController.rootFolder)
        let subPage = self.modelController.createPage(in: folder)
        let page2 = self.modelController.createPage(in: self.modelController.rootFolder)
        self.undoManager.removeAllActions()

        self.modelController.delete([page1, folder, subPage])
        self.undoManager.undo()
        XCTAssertNotNil(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertNotNil(self.modelController.pageCollection.objectWithID(page1.id))
        XCTAssertNotNil(self.modelController.pageCollection.objectWithID(subPage.id))
        XCTAssertNotNil(self.modelController.pageCollection.objectWithID(page2.id))
        self.undoManager.redo()

        XCTAssertNil(self.modelController.folderCollection.objectWithID(folder.id))
        XCTAssertNil(self.modelController.pageCollection.objectWithID(page1.id))
        XCTAssertNil(self.modelController.pageCollection.objectWithID(subPage.id))

        XCTAssertNotNil(self.modelController.pageCollection.objectWithID(page2.id))
    }
}
