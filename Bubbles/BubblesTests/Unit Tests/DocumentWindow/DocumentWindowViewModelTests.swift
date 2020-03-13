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


    //MARK: - .rootFolder
    func test_rootFolder_createsNewRootFolderIfNotInSettings() {
        let folderCollection = self.modelController.collection(for: Folder.self)
        XCTAssertEqual(folderCollection.all.count, 0)

        let rootFolder = self.viewModel.rootFolder

        XCTAssertNotNil(folderCollection.objectWithID(rootFolder.id))
    }

    func test_rootFolder_createsNewRootFolderIfIDInSettingsNotFoundInCollection() {
        let folderCollection = self.modelController.collection(for: Folder.self)
        XCTAssertEqual(folderCollection.all.count, 0)

        self.modelController.settings.set(Folder.modelID(with: UUID()), for: .rootFolder)

        let rootFolder = self.viewModel.rootFolder

        XCTAssertNotNil(folderCollection.objectWithID(rootFolder.id))
    }

    func test_rootFolder_returnsExistingRootFolderIfItExistsAndSetInSettings() {
        let folderCollection = self.modelController.collection(for: Folder.self)
        let expectedRootFolder = folderCollection.newObject()

        self.modelController.settings.set(expectedRootFolder.id, for: .rootFolder)

        let rootFolder = self.viewModel.rootFolder

        XCTAssertEqual(rootFolder, expectedRootFolder)
    }


    //MARK: - .canvasesForNewPages
    func test_canvasForNewPages_returnsNilIfNothingSelectedInSidebar() {
        XCTAssertNil(self.viewModel.canvasForNewPages)
    }

    func test_canvasForNewPages_returnsNilIfSidebarSelectionDoesntContainCanvases() {
        self.viewModel.updateSelection([.page(self.page.id)])
        self.viewModel.selectedCanvasID = self.canvas.id
        XCTAssertNil(self.viewModel.canvasForNewPages)
    }

    func test_canvasForNewPages_returnsNilIfCanvasesSelectedInSidebarNoCanvasSelected() {
        self.viewModel.updateSelection([.canvases])

        XCTAssertNil(self.viewModel.canvasForNewPages)
    }

    func test_canvasForNewPages_returnsCanvasIfSelectedInSidebarAndCanvasSelected() {
        self.viewModel.updateSelection([.canvases])
        self.viewModel.selectedCanvasID = self.canvas.id

        XCTAssertEqual(self.viewModel.canvasForNewPages, self.canvas)
    }


    //MARK: - .folderForNewPages
    func test_folderForNewPages_returnsRootFolderAndNilIfNothingSelectedInSidebar() {
        XCTAssertEqual(self.viewModel.folderForNewPages, self.viewModel.rootFolder)
    }

    func test_folderForNewPages_returnsRootFolderAndNilIfOnlyCanvasesSelected() {
        self.viewModel.updateSelection([.canvases])
        XCTAssertEqual(self.viewModel.folderForNewPages, self.viewModel.rootFolder)
    }

    func test_folderForNewPages_returnsFolderAndNilIfOnlyThatFolderIsSelected() {
        let folder = self.modelController.collection(for: Folder.self).newObject()
        self.viewModel.updateSelection([.folder(folder.id)])
        XCTAssertEqual(self.viewModel.folderForNewPages, folder)
    }

    func test_folderForNewPages_returnsFolderAndNilIfItIsTheLastsItemSelected() {
        let page2 = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        self.viewModel.updateSelection([.page(self.page.id), .page(page2.id), .folder(folder.id)])
        XCTAssertEqual(self.viewModel.folderForNewPages, folder)
    }

    func test_folderForNewPages_returnsFolderAndNilIfItIsTheLastsNonCanvasesItemSelected() {
        let page2 = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        self.viewModel.updateSelection([.page(self.page.id), .page(page2.id), .folder(folder.id), .canvases])
        XCTAssertEqual(self.viewModel.folderForNewPages, folder)
    }

    func test_folderForNewPages_returnsContainingFolderAndPageIfOnlyPageIsSelected() {
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])
        self.viewModel.updateSelection([.page(self.page.id)])
        XCTAssertEqual(self.viewModel.folderForNewPages, folder)
    }

    func test_folderForNewPages_returnsContainingFolderAndPageIfPageIsLastItemSelected() {
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])

        let page2 = self.modelController.collection(for: Page.self).newObject()
        self.viewModel.updateSelection([.page(page2.id), .page(self.page.id)])
        XCTAssertEqual(self.viewModel.folderForNewPages, folder)
    }

    func test_folderForNewPages_returnsContainingFolderAndPageIfPageIsLastNonCanvasesItemSelected() {
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])

        let page2 = self.modelController.collection(for: Page.self).newObject()
        self.viewModel.updateSelection([.page(page2.id), .page(self.page.id), .canvases])
        XCTAssertEqual(self.viewModel.folderForNewPages, folder)
    }


    //MARK: - .currentEditor
    func test_currentEditor_editorIsNoneIfSelectionIsEmpty() {
        XCTAssertEqual(self.viewModel.currentEditor, .none)
    }

    func test_currentEditor_editorIsCanvasIfCanvasesSelected() {
        self.viewModel.updateSelection([.canvases])
        XCTAssertEqual(self.viewModel.currentEditor, .canvas)
    }

    func test_currentEditor_editorIsPageIfPageSelected() {
        self.viewModel.updateSelection([.page(self.page.id)])
        XCTAssertEqual(self.viewModel.currentEditor, .page(self.page))
    }

    func test_currentEditor_editorReturnsToNoneIfSelectionRemoved() {
        self.viewModel.updateSelection([.page(self.page.id)])
        self.viewModel.updateSelection([])
        XCTAssertEqual(self.viewModel.currentEditor, .none)
    }

    func test_currentEditor_editorStaysOnCanvasIfSwitchFromCanvasToFolder() {
        let folder = self.modelController.collection(for: Folder.self).newObject()
        self.viewModel.updateSelection([.canvases])
        self.viewModel.updateSelection([.folder(folder.id)])
        XCTAssertEqual(self.viewModel.currentEditor, .canvas)
    }

    func test_currentEditor_editorStaysOnPageIfSwitchFromPageToFolder() {
        let folder = self.modelController.collection(for: Folder.self).newObject()
        self.viewModel.updateSelection([.page(self.page.id)])
        self.viewModel.updateSelection([.folder(folder.id)])
        XCTAssertEqual(self.viewModel.currentEditor, .page(self.page))
    }

    func test_currentEditor_editorStaysOnCanvasIfAnotherItemSelected() {
        self.viewModel.updateSelection([.canvases])
        self.viewModel.updateSelection([.canvases, .page(self.page.id)])
        XCTAssertEqual(self.viewModel.currentEditor, .canvas)
    }

    func test_currentEditor_editorStaysOnPageIfAnotherItemIsSelected() {
        self.viewModel.updateSelection([.page(self.page.id)])
        self.viewModel.updateSelection([.canvases, .page(self.page.id)])
        XCTAssertEqual(self.viewModel.currentEditor, .page(self.page))
    }

    func test_currentEditor_editorSwitchesToPageIfPageAddedToSelectionAndThenOtherPageDeselected() {
        let page = self.modelController.collection(for: Page.self).newObject()
        self.viewModel.updateSelection([.page(self.page.id)])
        self.viewModel.updateSelection([.page(page.id), .page(self.page.id)])
        self.viewModel.updateSelection([.page(page.id)])
        XCTAssertEqual(self.viewModel.currentEditor, .page(page))
    }

    func test_currentEditor_editorSwitchesToPageIfPageAddedToSelectionAndThenCanvasesDeselected() {
        self.viewModel.updateSelection([.canvases])
        self.viewModel.updateSelection([.canvases, .page(self.page.id)])
        self.viewModel.updateSelection([.page(self.page.id)])
        XCTAssertEqual(self.viewModel.currentEditor, .page(self.page))
    }

    func test_currentEditor_editorSwitchesToPageIfPageAddedToSelectionAndThenFolderDeselected() {
        let folder = self.modelController.collection(for: Folder.self).newObject()
        self.viewModel.updateSelection([.folder(folder.id)])
        self.viewModel.updateSelection([.folder(folder.id), .page(self.page.id)])
        self.viewModel.updateSelection([.page(self.page.id)])
        XCTAssertEqual(self.viewModel.currentEditor, .page(self.page))
    }


    //MARK: - createPage()
    func test_createPage_addsANewPageToCollection() {
        let page = self.viewModel.createPage()
        XCTAssertTrue(self.viewModel.pageCollection.all.contains(page))
    }

    func test_createPage_ifSidebarSelectionIsEmptySetsToNewPage() {
        let page = self.viewModel.createPage()

        XCTAssertEqual(self.viewModel.sidebarSelection.first, .page(page.id))
    }

    func test_createPage_ifSidebarSelectionContainsOnlyPageSetsToNewPage() {
        self.viewModel.updateSelection([.page(self.page.id)])
        let page = self.viewModel.createPage()
        XCTAssertEqual(self.viewModel.sidebarSelection.first, .page(page.id))
    }

    func test_createPage_ifSidebarSelectionContainsCanvasesDoesntChangeSidebar() {
        self.viewModel.updateSelection([.canvases, .page(self.page.id)])
        self.viewModel.createPage()
        XCTAssertEqual(self.viewModel.sidebarSelection.first, .canvases)
    }

    func test_createPage_ifSidebarSelectionContainsCanvasesAndCanvasSelectedThenAddsPageToCanvas() {
        self.viewModel.updateSelection([.canvases])
        self.viewModel.selectedCanvasID = self.canvas.id
        let page = self.viewModel.createPage()
        XCTAssertEqual(page.canvases.first?.canvas, self.canvas)
    }

    func test_createPage_ifSuppliedFolderIsNilThenAddsToFolderForNewPages() {
        let folder = self.modelController.collection(for: Folder.self).newObject()
        let page = self.modelController.collection(for: Page.self).newObject()
        folder.insert([page])

        self.viewModel.updateSelection([.page(page.id)])

        let newPage = self.viewModel.createPage()
        XCTAssertEqual(newPage.containingFolder, folder)
        XCTAssertTrue(folder.contents.contains(where: { $0.id == newPage.id }))
    }

    func test_createPage_ifSuppliedFolderIsSetThenAddsToThatFolderRatherThanFolderForNewPages() {
        let folder = self.modelController.collection(for: Folder.self).newObject()
        let page = self.modelController.collection(for: Page.self).newObject()
        self.viewModel.rootFolder.insert([page])

        self.viewModel.updateSelection([.page(self.page.id)])

        let newPage = self.viewModel.createPage(in: folder)
        XCTAssertEqual(newPage.containingFolder, folder)
        XCTAssertTrue(folder.contents.contains(where: { $0.id == newPage.id }))
    }

    func test_createPage_undoingRemovesPageFromCollection() {
        let page = self.viewModel.createPage()
        self.modelController.undoManager.undo()
        XCTAssertNil(self.viewModel.pageCollection.objectWithID(page.id))
    }

    func test_createPage_undoingRevertsSidebarToNilIfNoSelection() {
        self.viewModel.createPage()
        self.modelController.undoManager.undo()
        XCTAssertEqual(self.viewModel.selectedSidebarObjectIDs.count, 0)
    }

    func test_createPage_undoingRevertsSidebarToPreviouslySelectedPage() {
        self.viewModel.selectedSidebarObjectIDs = Set([self.page.id])
        self.viewModel.createPage()
        self.modelController.undoManager.undo()
        XCTAssertEqual(self.viewModel.selectedSidebarObjectIDs.first, self.page.id)
    }

    func test_createPage_removesPageFromCanvasIfOneWasSelected() {
        self.viewModel.selectedSidebarObjectIDs = Set([self.canvas.id])
        let page = self.viewModel.createPage()

        self.modelController.undoManager.undo()
        XCTAssertNil(self.canvas.pages.first(where: { $0.page?.id == page.id }))
    }

    func test_createPage_redoRecreatesPageWithSameIDAndProperties() throws {
        let page = self.viewModel.createPage()

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        let redonePage = try XCTUnwrap(self.viewModel.pageCollection.objectWithID(page.id))

        XCTAssertEqual(redonePage.title, page.title)
        XCTAssertEqual(redonePage.dateCreated, page.dateCreated)
        XCTAssertEqual(redonePage.dateModified, page.dateModified)
        XCTAssertEqual(redonePage.content.contentType, page.content.contentType)
        XCTAssertEqual(redonePage.content.page, redonePage)
    }

    func test_createPage_redoRecreatesPageOnCanvasIfOneWasSelected() throws {
        self.viewModel.updateSelection([.canvases])
        self.viewModel.selectedCanvasID = self.canvas.id
        let page = self.viewModel.createPage()

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        let redonePage = try XCTUnwrap(self.viewModel.pageCollection.objectWithID(page.id))
        XCTAssertNotNil(self.canvas.pages.first(where: { $0.page?.id == redonePage.id}))
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

    func test_createPagesFromFilesAtURLs_ifFolderIsNilThenAddsPagesToFolderForNewPages() {
        let folder = self.modelController.collection(for: Folder.self).newObject()
        let page = self.modelController.collection(for: Page.self).newObject()
        folder.insert([page])

        self.viewModel.updateSelection([.page(page.id)])

        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.viewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: self.canvas)
        XCTAssertEqual(pages.first?.containingFolder, folder)
        XCTAssertEqual(pages.last?.containingFolder, folder)

        XCTAssertTrue(folder.contents.contains(where: { $0.id == pages[0].id }))
        XCTAssertTrue(folder.contents.contains(where: { $0.id == pages[1].id }))
    }

    func test_createPagesFromFilesAtURLs_ifFolderIsSetThenAddsPagesToSuppliedFolder() {
        let folder = self.modelController.collection(for: Folder.self).newObject()
        let page = self.modelController.collection(for: Page.self).newObject()
        self.viewModel.rootFolder.insert([page])

        self.viewModel.updateSelection([.page(page.id)])

        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.viewModel.createPages(fromFilesAtURLs: fileURLs, in: folder, addingTo: self.canvas)
        XCTAssertEqual(pages.first?.containingFolder, folder)
        XCTAssertEqual(pages.last?.containingFolder, folder)

        XCTAssertTrue(folder.contents.contains(where: { $0.id == pages[0].id }))
        XCTAssertTrue(folder.contents.contains(where: { $0.id == pages[1].id }))
    }

    func test_createPagesFromFilesAtURLs_undoingRemovesPagesFromCollection() throws {
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.viewModel.createPages(fromFilesAtURLs: fileURLs)
        let imagePage = try XCTUnwrap(pages.first)
        let textPage = try XCTUnwrap(pages.last)

        self.modelController.undoManager.undo()

        XCTAssertNil(self.viewModel.pageCollection.objectWithID(imagePage.id))
        XCTAssertNil(self.viewModel.pageCollection.objectWithID(textPage.id))
    }

    func test_createPagesFromFilesAtURLs_undoingRemovesPagesFromCanvasIfOneWasSupplied() throws{
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.viewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: self.canvas)
        let imagePage = try XCTUnwrap(pages.first)
        let textPage = try XCTUnwrap(pages.last)

        self.modelController.undoManager.undo()

        XCTAssertNil(self.canvas.pages.first(where: { $0.page?.id == imagePage.id }))
        XCTAssertNil(self.canvas.pages.first(where: { $0.page?.id == textPage.id }))
    }

    func test_createPagesFromFilesAtURLs_redoingRecreatesPagesWithSameIDsAndContent() throws {
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.viewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: self.canvas)
        let imagePage = try XCTUnwrap(pages.first)
        let textPage = try XCTUnwrap(pages.last)

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        let redoneImagePage = try XCTUnwrap(self.viewModel.pageCollection.objectWithID(imagePage.id))
        XCTAssertEqual(redoneImagePage.title, imagePage.title)
        XCTAssertEqual(redoneImagePage.dateCreated, imagePage.dateCreated)
        XCTAssertEqual(redoneImagePage.dateModified, imagePage.dateModified)
        XCTAssertEqual(redoneImagePage.content.contentType, imagePage.content.contentType)
        XCTAssertEqual((redoneImagePage.content as? ImagePageContent)?.image, (imagePage.content as? ImagePageContent)?.image)

        let redoneTextPage = try XCTUnwrap(self.viewModel.pageCollection.objectWithID(textPage.id))
        XCTAssertEqual(redoneTextPage.title, textPage.title)
        XCTAssertEqual(redoneTextPage.dateCreated, textPage.dateCreated)
        XCTAssertEqual(redoneTextPage.dateModified, textPage.dateModified)
        XCTAssertEqual(redoneTextPage.content.contentType, textPage.content.contentType)
        XCTAssertEqual((redoneTextPage.content as? TextPageContent)?.text, (textPage.content as? TextPageContent)?.text)
    }

    func test_createPagesFromFilesAtURLs_redoingAddsPagesBackToCanvas() throws {
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = self.viewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: self.canvas)
        let imagePage = try XCTUnwrap(pages.first)
        let textPage = try XCTUnwrap(pages.last)

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNotNil(self.canvas.pages.first(where: { $0.page?.id == imagePage.id }))
        XCTAssertNotNil(self.canvas.pages.first(where: { $0.page?.id == textPage.id }))
    }


    //MARK: - delete(_: [SideBarItem]) - Single Page
    func test_deleteSidebarItems_singlePage_deletesThatPageIfNotOnCanvas() {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        self.viewModel.delete([.page(page.id)])

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
    }

    func test_deleteSidebarItems_singlePage_showsAlertIfThatPageOnACanvas() {
        let window = MockWindow()
        self.viewModel.window = window

        self.viewModel.delete([.page(self.page.id)])

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deleteSidebarItems_singlePage_doesntDeletePageIfAlertReturnsCancel() throws {
        let window = MockWindow()
        self.viewModel.window = window

        self.viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertNotNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
    }

    func test_deleteSidebarItems_singlePage_deletesPageAndRemovesFromCanvasesIfAlertReturnsOK() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let canvas = self.modelController.collection(for: Canvas.self).newObject()
        let canvasPage = canvas.addPages([self.page])[0]

        self.viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertNil(self.modelController.collection(for: CanvasPage.self).objectWithID(canvasPage.id))
        XCTAssertNil(self.modelController.collection(for: CanvasPage.self).objectWithID(self.canvasPage.id))
    }

    func test_deleteSidebarItems_singlePage_removesPageFromSidebarSelectionIfItsThere() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        self.viewModel.updateSelection([.page(page.id), .page(self.page.id)])

        self.viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertEqual(self.viewModel.sidebarSelection, [.page(page.id)])
    }

    func test_deleteSidebarItems_singlePage_doesntChangeSidebarSelectionIfDeletedPageIsntInSelection() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        self.viewModel.updateSelection([.page(page.id), .canvases])

        let previousSelection = self.viewModel.sidebarSelection

        self.viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertEqual(self.viewModel.sidebarSelection, previousSelection)
    }

    func test_deleteSidebarItems_singlePage_removesPageFromContainingFolder() {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])

        self.viewModel.delete([.page(page.id)])

        XCTAssertFalse(folder.contents.contains(where: { $0.id == page.id }))
    }

    func test_deleteSidebarItems_singlePage_undoRecreatesPageWithSameIDAndAnyAttribtues() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject() {
            $0.title = "Test Page"
            $0.dateModified = $0.dateCreated.addingTimeInterval(200)
            $0.content = ImagePageContent()
        }
        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.page(page.id)])

        self.modelController.undoManager.undo()

        let undonePage = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertEqual(undonePage.title, page.title)
        XCTAssertEqual(undonePage.dateModified, page.dateModified)
        XCTAssertEqual(undonePage.dateCreated, page.dateCreated)
        XCTAssertEqual(undonePage.content.contentType, page.content.contentType)
        XCTAssertEqual(undonePage.content.page, undonePage)
    }

    func test_deleteSidebarItem_singlePage_undoAddsPagesAndReLinksPagesBackToAnyCanvases() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let childPage = self.modelController.collection(for: Page.self).newObject()
        let childCanvasPage = self.canvas.add(childPage, linkedFrom: self.canvasPage)
        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(self.page.id))
        XCTAssertNotNil(self.modelController.collection(for: Page.self).objectWithID(childPage.id))

        self.modelController.undoManager.undo()

        let undoneCanvasPage = try XCTUnwrap(self.modelController.collection(for: CanvasPage.self).objectWithID(self.canvasPage.id))
        XCTAssertEqual(childCanvasPage.parent, undoneCanvasPage)
    }

    func test_deleteSidebarItem_singlePage_undoAddsPageBackToPreviousFolder() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])
        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.page(page.id)])

        self.modelController.undoManager.undo()

        let undonePage = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertEqual(undonePage.containingFolder, folder)
        XCTAssertTrue(folder.contents.contains(where: { $0.id == page.id }))
    }

    func test_deleteSidebarItem_singlePage_redoDeletesPageAgain() {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()

        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.page(page.id)])

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
    }

    func test_deleteSidebarItem_singlePage_redoDeletesPageAgainWithoutShowingAlert() throws {
        let window = MockWindow()
        self.viewModel.window = window

        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        window.callback = nil

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(self.page.id))
    }

    func test_deleteSidebarItem_singlePage_redoRemovesPageFromAnyCanvasesAgain() throws {
        let window = MockWindow()
        self.viewModel.window = window

        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        window.callback = nil

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(self.modelController.collection(for: CanvasPage.self).objectWithID(self.canvasPage.id))
    }

    func test_deleteSidebarItem_singlePage_redoRemovesPageFromItsContainingFolderAgain() {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])

        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.page(page.id)])

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertFalse(folder.contents.contains(where: { $0.id == page.id }))
    }


    //MARK: - delete(_: [SideBarItem]) - Single Folder
    func test_deleteSidebarItems_singleFolder_deletesThatFolderIfEmpty() {
        let window = MockWindow()
        self.viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()

        self.viewModel.delete([.folder(folder.id)])

        XCTAssertNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
    }

    func test_deleteSidebarItems_singleFolder_showsAlertIfFolderContainsItems() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])

        self.viewModel.delete([.folder(folder.id)])

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deleteSidebarItems_singleFolder_doesntDeleteFolderIfAlertReturnsCancel() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])

        self.viewModel.delete([.folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertNotNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
    }

    func test_deleteSidebarItems_singleFolder_deletesFolderAndContentsIfAlertReturnsOK() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])

        self.viewModel.delete([.folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
    }

    func test_deleteSidebarItems_singleFolder_removesFolderFromSidebarSelection() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])

        self.viewModel.updateSelection([.page(self.page.id), .folder(folder.id)])

        self.viewModel.delete([.folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertEqual(self.viewModel.sidebarSelection, [.page(self.page.id)])
    }

    func test_deleteSidebarItems_singleFolder_removesContainedItemsFromSidebarSelection() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])

        self.viewModel.updateSelection([.page(page.id), .page(self.page.id)])

        self.viewModel.delete([.folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertEqual(self.viewModel.sidebarSelection, [.page(self.page.id)])
    }

    func test_deleteSidebarItems_singleFolder_removesFolderFromContainingFolder() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()
        self.viewModel.rootFolder.insert([folder])

        self.viewModel.delete([.folder(folder.id)])

        XCTAssertFalse(self.viewModel.rootFolder.contents.contains(where: { $0.id == folder.id }))
    }

    func test_deleteSidebarItems_singleFolder_doesntDoAnythingIfAttemptingToDeleteRootFolder() {
        let window = MockWindow()
        self.viewModel.window = window

        let rootFolder = self.viewModel.rootFolder
        self.viewModel.delete([.folder(rootFolder.id)])

        XCTAssertNil(window.suppliedAlert)
        XCTAssertNil(window.callback)

        XCTAssertEqual(self.viewModel.rootFolder, rootFolder)
    }

    func test_deleteSidebarItems_singleFolder_undoRecreatesFolderWithSameIDAndAttributes() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject() {
            $0.title = "My Great Folder"
        }

        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.folder(folder.id)])

        self.modelController.undoManager.undo()

        let undoneFolder = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertEqual(undoneFolder.title, folder.title)
    }

    func test_deleteSidebarItem_singleFolder_undoRecreatesFolderContents() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let page2 = self.modelController.collection(for: Page.self).newObject()
        let childFolder = self.modelController.collection(for: Folder.self).newObject()
        let childPage = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page, page2, childFolder])
        childFolder.insert([childPage])

        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()

        XCTAssertNotNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertNotNil(self.modelController.collection(for: Page.self).objectWithID(page2.id))
        XCTAssertNotNil(self.modelController.collection(for: Folder.self).objectWithID(childFolder.id))
        XCTAssertNotNil(self.modelController.collection(for: Page.self).objectWithID(childPage.id))

        let undoneFolder = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertEqual(undoneFolder.contents[0].id, page.id)
        XCTAssertEqual(undoneFolder.contents[1].id, page2.id)
        XCTAssertEqual(undoneFolder.contents[2].id, childFolder.id)
    }

    func test_deleteSidebarItem_singleFolder_undoAddsFolderBackToPreviousFolder() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()
        self.viewModel.rootFolder.insert([folder])

        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.folder(folder.id)])

        self.modelController.undoManager.undo()

        let undoneFolder = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertTrue(self.viewModel.rootFolder.contents.contains(where: { $0.id == undoneFolder.id }))
        XCTAssertEqual(undoneFolder.containingFolder, self.viewModel.rootFolder)
    }

    func test_deleteSidebarItem_singleFolder_redoDeletesFolderAndContentsAgainWithoutDisplayingAlert() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let page2 = self.modelController.collection(for: Page.self).newObject()
        let childFolder = self.modelController.collection(for: Folder.self).newObject()
        let childPage = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page, page2, childFolder])
        childFolder.insert([childPage])

        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page2.id))
        XCTAssertNil(self.modelController.collection(for: Folder.self).objectWithID(childFolder.id))
        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(childPage.id))
    }


    //MARK: - delete(_: [SideBarItem]) - Multiple Items
    func test_deleteSidebarItems_multipleItems_showsSimpleAlert() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()

        self.viewModel.delete([.page(page.id), .folder(folder.id)])

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deleteSidebarItems_multipleItems_doesntDeleteItemsIfAlertReturnsCancel() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()

        self.viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertNotNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertNotNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
    }

    func test_deleteSidebarItems_multipleItems_deletesItemsIfAlertReturnsOK() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()

        self.viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
    }

    func test_deleteSidebarItems_multipleItems_removesItemsFromSidebarSelection() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()

        self.viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])

        self.viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertEqual(self.viewModel.sidebarSelection, [.page(self.page.id), .canvases])
    }

    func test_deleteSidebarItems_multipleItems_removesItemsEvenIfSuppliedItemIsContainedInASuppliedFolder() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let childPage = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([childPage])

        self.viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])

        self.viewModel.delete([.page(childPage.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(childPage.id))
        XCTAssertNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
    }

    func test_deleteSidebarItems_multipleItems_removesItemsFromContainingFolder() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        self.viewModel.rootFolder.insert([page, folder])

        self.viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])

        self.viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertFalse(self.viewModel.rootFolder.contents.contains(where: { $0.id == page.id }))
        XCTAssertFalse(self.viewModel.rootFolder.contents.contains(where: { $0.id == folder.id }))
    }

    func test_deleteSidebarItems_multipleItems_undoRecreatesItemsWithSameIDAndAnyAttributes() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject() {
            $0.title = "Foobar"
            $0.dateModified = $0.dateCreated.addingTimeInterval(360)
        }
        let folder = self.modelController.collection(for: Folder.self).newObject() {
            $0.title = "Test Folder"
        }

        self.viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])
        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()

        let undonePage = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertEqual(undonePage.title, page.title)
        XCTAssertEqual(undonePage.dateCreated, page.dateCreated)
        XCTAssertEqual(undonePage.dateModified, page.dateModified)

        let undoneFolder = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertEqual(undoneFolder.title, folder.title)
    }

    func test_deleteSidebarItem_multipleItems_undoAddsItemsBackToPreviousFolders() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        self.viewModel.rootFolder.insert([page, folder])

        self.viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])
        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()

        XCTAssertEqual(self.viewModel.rootFolder.contents.first?.id, page.id)
        XCTAssertEqual(self.viewModel.rootFolder.contents.last?.id, folder.id)
    }

    func test_deleteSidebarItem_multipleItems_undoAddsContentsBackToAnyFolders() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let childPage = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([childPage])

        self.viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])
        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()

        let undoneFolder = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertEqual(undoneFolder.contents.first?.id, childPage.id)
    }

    func test_deleteSidebarItem_multipleItems_redoDeletesItemsAgainWithoutShowingAlert() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let childPage = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([childPage])

        self.viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])
        self.modelController.undoManager.removeAllActions()
        self.viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(childPage.id))
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

    func test_addPage_undoingRemovesPageFromCanvas() {
        let page = self.viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id)
        self.viewModel.addPage(at: link, to: self.canvas)

        self.modelController.undoManager.undo()

        XCTAssertFalse(self.canvas.pages.map { $0.page }.contains(page))
    }

    func test_addPage_undoingDeletesCanvasPage() throws {
        let page = self.viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id)
        let canvasPage = try XCTUnwrap(self.viewModel.addPage(at: link, to: self.canvas))

        self.modelController.undoManager.undo()

        XCTAssertNil(self.viewModel.canvasPageCollection.objectWithID(canvasPage.id))
    }

    func test_addPage_undoingRemovesPageFromSourcePagesChildren() throws {
        let page = self.viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id, source: self.canvasPage.id)
        self.viewModel.addPage(at: link, to: self.canvas)

        self.modelController.undoManager.undo()

        XCTAssertEqual(self.canvasPage.children.count, 0)
    }

    func test_addPage_redoingAddsBackThePageWithSameIDAndProperties() throws {
        let page = self.viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id, source: self.canvasPage.id)
        let canvasPage = try XCTUnwrap(self.viewModel.addPage(at: link, to: self.canvas))

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        let undoneCanvasPage = try XCTUnwrap(self.viewModel.canvasPageCollection.objectWithID(canvasPage.id))
        XCTAssertEqual(undoneCanvasPage.parent, self.canvasPage)
        XCTAssertEqual(undoneCanvasPage.frame, canvasPage.frame)
    }


    //MARK: - createCanvas()
    func test_createCanvas_createsNewCanvas() {
        let canvas = self.viewModel.createCanvas()
        XCTAssert(self.viewModel.canvasCollection.all.contains(canvas))
    }

    func test_createCanvas_undoingCanvasCreationRemovesCanvas() {
        let canvas = self.viewModel.createCanvas()
        self.modelController.undoManager.undo()
        XCTAssertNil(self.viewModel.canvasCollection.objectWithID(canvas.id))
    }

    func test_createCanvas_redoingRecreatesCanvasWithSameIDAndProperties() throws {
        let canvas = self.viewModel.createCanvas()
        canvas.title = "Foo Bar Baz"
        canvas.sortIndex = 3
        canvas.viewPort = CGRect(x: 3, y: 90, width: 100, height: 240)
        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        let redoneCanvas = try XCTUnwrap(self.viewModel.canvasCollection.objectWithID(canvas.id))
        XCTAssertEqual(redoneCanvas.title, canvas.title)
        XCTAssertEqual(redoneCanvas.dateCreated, canvas.dateCreated)
        XCTAssertEqual(redoneCanvas.dateModified, canvas.dateModified)
        XCTAssertEqual(redoneCanvas.sortIndex, canvas.sortIndex)
        XCTAssertEqual(redoneCanvas.viewPort, canvas.viewPort)
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
        self.viewModel.selectedSidebarObjectIDs = Set([canvas.id])

        self.viewModel.delete(canvas)

        XCTAssertEqual(self.viewModel.selectedSidebarObjectIDs.count, 0)
    }

    func test_deleteCanvas_undoRecreatesCanvasWithSameIDAndAttributes() throws {
        let canvas = self.viewModel.canvasCollection.newObject()
        canvas.title = "Hello World"
        canvas.viewPort = CGRect(x: 30, y: 40, width: 50, height: 60)

        self.modelController.undoManager.removeAllActions()

        self.viewModel.delete(canvas)
        self.modelController.undoManager.undo()

        let undoneCanvas = try XCTUnwrap(self.viewModel.canvasCollection.objectWithID(canvas.id))
        XCTAssertEqual(undoneCanvas.title, canvas.title)
        XCTAssertEqual(undoneCanvas.dateCreated, canvas.dateCreated)
        XCTAssertEqual(undoneCanvas.dateModified, canvas.dateModified)
        XCTAssertEqual(undoneCanvas.viewPort, canvas.viewPort)
    }

    func test_deleteCanvas_undoAddsAnyPagesBackToCanvasWithSameFrames() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let canvas = self.viewModel.canvasCollection.newObject()
        let secondPage = self.viewModel.pageCollection.newObject()
        let canvasPage1 = try XCTUnwrap(canvas.addPages([self.page], centredOn: CGPoint(x: -40, y: -30)).first)
        let canvasPage2 = canvas.add(secondPage, linkedFrom: canvasPage1)
        self.modelController.undoManager.removeAllActions()

        self.viewModel.delete(canvas)
        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()

        let undoneCanvasPage1 = try XCTUnwrap(self.viewModel.canvasPageCollection.objectWithID(canvasPage1.id))
        let undoneCanvasPage2 = try XCTUnwrap(self.viewModel.canvasPageCollection.objectWithID(canvasPage2.id))

        XCTAssertEqual(undoneCanvasPage1.canvas, canvas)
        XCTAssertEqual(undoneCanvasPage1.frame, canvasPage1.frame)
        XCTAssertEqual(undoneCanvasPage1.page, self.page)

        XCTAssertEqual(undoneCanvasPage2.canvas, canvas)
        XCTAssertEqual(undoneCanvasPage2.frame, canvasPage2.frame)
        XCTAssertEqual(undoneCanvasPage2.page, secondPage)
        XCTAssertEqual(undoneCanvasPage2.parent, undoneCanvasPage1)
    }

    func test_deleteCanvas_undoSetsSidebarSelectionBackToCanavsIfItWasSelected() throws {
        let canvas = self.viewModel.canvasCollection.newObject()
        self.viewModel.selectedSidebarObjectIDs = Set([canvas.id])
        self.modelController.undoManager.removeAllActions()

        self.viewModel.delete(canvas)
        self.modelController.undoManager.undo()

        XCTAssertEqual(self.viewModel.selectedSidebarObjectIDs.first, canvas.id)
    }

    func test_deleteCanvas_redoingDeletesCanvasAgainButWithoutAnyAlert() {
        let window = MockWindow()
        self.viewModel.window = window

        let canvas = self.viewModel.canvasCollection.newObject()
        self.modelController.undoManager.removeAllActions()

        self.viewModel.delete(canvas)
        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(window.suppliedAlert)
        XCTAssertNil(self.viewModel.canvasCollection.objectWithID(canvas.id))
    }

    func test_deleteCanvas_redoingRemovesPagesFromCanvasAgainButWithoutAnyAlert() throws {
        let window = MockWindow()
        self.viewModel.window = window

        let canvas = self.viewModel.canvasCollection.newObject()
        let secondPage = self.viewModel.pageCollection.newObject()
        let canvasPage1 = try XCTUnwrap(canvas.addPages([self.page], centredOn: CGPoint(x: -40, y: -30)).first)
        let canvasPage2 = canvas.add(secondPage, linkedFrom: canvasPage1)
        self.modelController.undoManager.removeAllActions()

        self.viewModel.delete(canvas)
        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(self.viewModel.canvasCollection.objectWithID(canvas.id))
        XCTAssertNil(self.viewModel.canvasPageCollection.objectWithID(canvasPage1.id))
        XCTAssertNil(self.viewModel.canvasPageCollection.objectWithID(canvasPage2.id))
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

    func test_removeCanvasPage_undoingRecreatesCanvasPageWithSameIDAndProperties() throws {
        self.modelController.undoManager.removeAllActions()
        self.viewModel.remove(self.canvasPage)

        //Sanity check
        XCTAssertFalse(self.viewModel.canvasPageCollection.all.contains(self.canvasPage))

        self.modelController.undoManager.undo()

        let undonePage = try XCTUnwrap(self.viewModel.canvasPageCollection.objectWithID(self.canvasPage.id))
        XCTAssertEqual(undonePage.frame, self.canvasPage.frame)
    }

    func test_removeCanvasPage_undoingAddsCanvasPageBackToCanvas() throws {
        self.modelController.undoManager.removeAllActions()
        self.viewModel.remove(self.canvasPage)

        //Sanity Check
        XCTAssertFalse(self.canvas.pages.contains(self.canvasPage))

        self.modelController.undoManager.undo()

        let undonePage = try XCTUnwrap(self.viewModel.canvasPageCollection.objectWithID(self.canvasPage.id))
        XCTAssertEqual(undonePage.canvas, self.canvas)
    }

    func test_removeCanvasPage_undoingRecreatesAllChildPagesWithSameIDsAndProperties() throws {
        let canvasPageCollection = self.viewModel.canvasPageCollection
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
            $0.frame = CGRect(x: 5, y: 4, width: 3, height: 2)
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
            $0.frame = CGRect(x: 99, y: 100, width: 101, height: 102)
        }
        self.modelController.undoManager.removeAllActions()

        self.viewModel.remove(self.canvasPage)

        self.modelController.undoManager.undo()

        let undoneChild1 = try XCTUnwrap(self.viewModel.canvasPageCollection.objectWithID(child1.id))
        XCTAssertEqual(undoneChild1.frame, child1.frame)
        let undoneChild2 = try XCTUnwrap(self.viewModel.canvasPageCollection.objectWithID(child2.id))
        XCTAssertEqual(undoneChild2.frame, child2.frame)
    }

    func test_removeCanvasPage_undoingAddsAllChildPagesBacktoCanvas() throws {
        let canvasPageCollection = self.viewModel.canvasPageCollection
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        self.modelController.undoManager.removeAllActions()

        self.viewModel.remove(self.canvasPage)

        self.modelController.undoManager.undo()

        let undoneChild1 = try XCTUnwrap(canvasPageCollection.objectWithID(child1.id))
        XCTAssertEqual(undoneChild1.canvas, self.canvas)
        let undoneChild2 = try XCTUnwrap(canvasPageCollection.objectWithID(child2.id))
        XCTAssertEqual(undoneChild2.canvas, self.canvas)
    }

    func test_removeCanvasPage_undoingCorrectlyConnectsAllParentChildRelationships() throws {
        let canvasPageCollection = self.viewModel.canvasPageCollection
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        self.modelController.undoManager.removeAllActions()

        self.viewModel.remove(self.canvasPage)

        self.modelController.undoManager.undo()

        let undonePage = try XCTUnwrap(canvasPageCollection.objectWithID(self.canvasPage.id))
        let undoneChild1 = try XCTUnwrap(canvasPageCollection.objectWithID(child1.id))
        XCTAssertEqual(undoneChild1.parent, undonePage)
        let undoneChild2 = try XCTUnwrap(canvasPageCollection.objectWithID(child2.id))
        XCTAssertEqual(undoneChild2.parent, undonePage)
    }

    func test_removeCanvasPage_redoingRemovesAndDeletesAllCanvasPagesAgain() {
        let canvasPageCollection = self.viewModel.canvasPageCollection
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        self.modelController.undoManager.removeAllActions()

        self.viewModel.remove(self.canvasPage)

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(canvasPageCollection.objectWithID(self.canvasPage.id))
        XCTAssertNil(canvasPageCollection.objectWithID(child1.id))
        XCTAssertNil(canvasPageCollection.objectWithID(child2.id))
    }
}
