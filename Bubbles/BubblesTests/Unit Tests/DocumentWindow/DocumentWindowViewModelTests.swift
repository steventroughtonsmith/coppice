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
    }


    //MARK: - .rootFolder
    func test_rootFolder_createsNewRootFolderIfNotInSettings() {
        let folderCollection = self.modelController.collection(for: Folder.self)
        XCTAssertEqual(folderCollection.all.count, 0)

        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let rootFolder = viewModel.rootFolder

        XCTAssertNotNil(folderCollection.objectWithID(rootFolder.id))
    }

    func test_rootFolder_createsNewRootFolderIfIDInSettingsNotFoundInCollection() {
        let folderCollection = self.modelController.collection(for: Folder.self)
        XCTAssertEqual(folderCollection.all.count, 0)

        self.modelController.settings.set(Folder.modelID(with: UUID()), for: .rootFolder)

        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let rootFolder = viewModel.rootFolder

        XCTAssertNotNil(folderCollection.objectWithID(rootFolder.id))
    }

    func test_rootFolder_returnsExistingRootFolderIfItExistsAndSetInSettings() {
        let folderCollection = self.modelController.collection(for: Folder.self)
        let expectedRootFolder = folderCollection.newObject()

        self.modelController.settings.set(expectedRootFolder.id, for: .rootFolder)

        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let rootFolder = viewModel.rootFolder

        XCTAssertEqual(rootFolder, expectedRootFolder)
    }


    //MARK: - .canvasesForNewPages
    func test_canvasForNewPages_returnsNilIfNothingSelectedInSidebar() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        XCTAssertNil(viewModel.canvasForNewPages)
    }

    func test_canvasForNewPages_returnsNilIfSidebarSelectionDoesntContainCanvases() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.page(self.page.id)])
        viewModel.selectedCanvasID = self.canvas.id
        XCTAssertNil(viewModel.canvasForNewPages)
    }

    func test_canvasForNewPages_returnsNilIfCanvasesSelectedInSidebarNoCanvasSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases])

        XCTAssertNil(viewModel.canvasForNewPages)
    }

    func test_canvasForNewPages_returnsCanvasIfSelectedInSidebarAndCanvasSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases])
        viewModel.selectedCanvasID = self.canvas.id

        XCTAssertEqual(viewModel.canvasForNewPages, self.canvas)
    }


    //MARK: - .folderForNewPages
    func test_folderForNewPages_returnsRootFolderAndNilIfNothingSelectedInSidebar() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        XCTAssertEqual(viewModel.folderForNewPages, viewModel.rootFolder)
    }

    func test_folderForNewPages_returnsRootFolderAndNilIfOnlyCanvasesSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases])
        XCTAssertEqual(viewModel.folderForNewPages, viewModel.rootFolder)
    }

    func test_folderForNewPages_returnsFolderAndNilIfOnlyThatFolderIsSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let folder = self.modelController.collection(for: Folder.self).newObject()
        viewModel.updateSelection([.folder(folder.id)])
        XCTAssertEqual(viewModel.folderForNewPages, folder)
    }

    func test_folderForNewPages_returnsFolderAndNilIfItIsTheLastsItemSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page2 = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        viewModel.updateSelection([.page(self.page.id), .page(page2.id), .folder(folder.id)])
        XCTAssertEqual(viewModel.folderForNewPages, folder)
    }

    func test_folderForNewPages_returnsFolderAndNilIfItIsTheLastsNonCanvasesItemSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page2 = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        viewModel.updateSelection([.page(self.page.id), .page(page2.id), .folder(folder.id), .canvases])
        XCTAssertEqual(viewModel.folderForNewPages, folder)
    }

    func test_folderForNewPages_returnsContainingFolderAndPageIfOnlyPageIsSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])
        viewModel.updateSelection([.page(self.page.id)])
        XCTAssertEqual(viewModel.folderForNewPages, folder)
    }

    func test_folderForNewPages_returnsContainingFolderAndPageIfPageIsLastItemSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])

        let page2 = self.modelController.collection(for: Page.self).newObject()
        viewModel.updateSelection([.page(page2.id), .page(self.page.id)])
        XCTAssertEqual(viewModel.folderForNewPages, folder)
    }

    func test_folderForNewPages_returnsContainingFolderAndPageIfPageIsLastNonCanvasesItemSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])

        let page2 = self.modelController.collection(for: Page.self).newObject()
        viewModel.updateSelection([.page(page2.id), .page(self.page.id), .canvases])
        XCTAssertEqual(viewModel.folderForNewPages, folder)
    }


    //MARK: - .currentEditor
    func test_currentEditor_editorIsNoneIfSelectionIsEmpty() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        XCTAssertEqual(viewModel.currentEditor, .none)
    }

    func test_currentEditor_editorIsCanvasIfCanvasesSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases])
        XCTAssertEqual(viewModel.currentEditor, .canvas)
    }

    func test_currentEditor_editorIsPageIfPageSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.page(self.page.id)])
        XCTAssertEqual(viewModel.currentEditor, .page(self.page))
    }

    func test_currentEditor_editorReturnsToNoneIfSelectionRemoved() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.page(self.page.id)])
        viewModel.updateSelection([])
        XCTAssertEqual(viewModel.currentEditor, .none)
    }

    func test_currentEditor_editorStaysOnCanvasIfSwitchFromCanvasToFolder() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let folder = self.modelController.collection(for: Folder.self).newObject()
        viewModel.updateSelection([.canvases])
        viewModel.updateSelection([.folder(folder.id)])
        XCTAssertEqual(viewModel.currentEditor, .canvas)
    }

    func test_currentEditor_editorStaysOnPageIfSwitchFromPageToFolder() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let folder = self.modelController.collection(for: Folder.self).newObject()
        viewModel.updateSelection([.page(self.page.id)])
        viewModel.updateSelection([.folder(folder.id)])
        XCTAssertEqual(viewModel.currentEditor, .page(self.page))
    }

    func test_currentEditor_editorStaysOnCanvasIfAnotherItemSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases])
        viewModel.updateSelection([.canvases, .page(self.page.id)])
        XCTAssertEqual(viewModel.currentEditor, .canvas)
    }

    func test_currentEditor_editorStaysOnPageIfAnotherItemIsSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.page(self.page.id)])
        viewModel.updateSelection([.canvases, .page(self.page.id)])
        XCTAssertEqual(viewModel.currentEditor, .page(self.page))
    }

    func test_currentEditor_editorSwitchesToPageIfPageAddedToSelectionAndThenOtherPageDeselected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = self.modelController.collection(for: Page.self).newObject()
        viewModel.updateSelection([.page(self.page.id)])
        viewModel.updateSelection([.page(page.id), .page(self.page.id)])
        viewModel.updateSelection([.page(page.id)])
        XCTAssertEqual(viewModel.currentEditor, .page(page))
    }

    func test_currentEditor_editorSwitchesToPageIfPageAddedToSelectionAndThenCanvasesDeselected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases])
        viewModel.updateSelection([.canvases, .page(self.page.id)])
        viewModel.updateSelection([.page(self.page.id)])
        XCTAssertEqual(viewModel.currentEditor, .page(self.page))
    }

    func test_currentEditor_editorSwitchesToPageIfPageAddedToSelectionAndThenFolderDeselected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let folder = self.modelController.collection(for: Folder.self).newObject()
        viewModel.updateSelection([.folder(folder.id)])
        viewModel.updateSelection([.folder(folder.id), .page(self.page.id)])
        viewModel.updateSelection([.page(self.page.id)])
        XCTAssertEqual(viewModel.currentEditor, .page(self.page))
    }


    //MARK: - createPage()
    func test_createPage_addsANewPageToCollection() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = viewModel.createPage()
        XCTAssertTrue(viewModel.pageCollection.all.contains(page))
    }

    func test_createPage_ifSidebarSelectionIsEmptySetsToNewPage() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = viewModel.createPage()

        XCTAssertEqual(viewModel.sidebarSelection.first, .page(page.id))
    }

    func test_createPage_ifSidebarSelectionContainsOnlyPageSetsToNewPage() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.page(self.page.id)])
        let page = viewModel.createPage()
        XCTAssertEqual(viewModel.sidebarSelection.first, .page(page.id))
    }

    func test_createPage_ifSidebarSelectionContainsCanvasesDoesntChangeSidebar() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases, .page(self.page.id)])
        viewModel.createPage()
        XCTAssertEqual(viewModel.sidebarSelection.first, .canvases)
    }

    func test_createPage_ifSidebarSelectionContainsCanvasesAndCanvasSelectedThenAddsPageToCanvas() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases])
        viewModel.selectedCanvasID = self.canvas.id
        let page = viewModel.createPage()
        XCTAssertEqual(page.canvases.first?.canvas, self.canvas)
    }

    func test_createPage_ifSuppliedFolderIsNilThenAddsToFolderForNewPages() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let folder = self.modelController.collection(for: Folder.self).newObject()
        let page = self.modelController.collection(for: Page.self).newObject()
        folder.insert([page])

        viewModel.updateSelection([.page(page.id)])

        let newPage = viewModel.createPage()
        XCTAssertEqual(newPage.containingFolder, folder)
        XCTAssertTrue(folder.contents.contains(where: { $0.id == newPage.id }))
    }

    func test_createPage_ifSuppliedFolderIsSetThenAddsToThatFolderRatherThanFolderForNewPages() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let folder = self.modelController.collection(for: Folder.self).newObject()
        let page = self.modelController.collection(for: Page.self).newObject()
        viewModel.rootFolder.insert([page])

        viewModel.updateSelection([.page(self.page.id)])

        let newPage = viewModel.createPage(in: folder)
        XCTAssertEqual(newPage.containingFolder, folder)
        XCTAssertTrue(folder.contents.contains(where: { $0.id == newPage.id }))
    }

    func test_createPage_undoingRemovesPageFromCollection() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = viewModel.createPage()
        self.modelController.undoManager.undo()
        XCTAssertNil(viewModel.pageCollection.objectWithID(page.id))
    }

    func test_createPage_undoingRevertsSidebarToNilIfNoSelection() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.createPage()
        self.modelController.undoManager.undo()
        XCTAssertEqual(viewModel.selectedSidebarObjectIDs.count, 0)
    }

    func test_createPage_undoingRevertsSidebarToPreviouslySelectedPage() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.selectedSidebarObjectIDs = Set([self.page.id])
        viewModel.createPage()
        self.modelController.undoManager.undo()
        XCTAssertEqual(viewModel.selectedSidebarObjectIDs.first, self.page.id)
    }

    func test_createPage_removesPageFromCanvasIfOneWasSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.selectedSidebarObjectIDs = Set([self.canvas.id])
        let page = viewModel.createPage()

        self.modelController.undoManager.undo()
        XCTAssertNil(self.canvas.pages.first(where: { $0.page?.id == page.id }))
    }

    func test_createPage_redoRecreatesPageWithSameIDAndProperties() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = viewModel.createPage()

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        let redonePage = try XCTUnwrap(viewModel.pageCollection.objectWithID(page.id))

        XCTAssertEqual(redonePage.title, page.title)
        XCTAssertEqual(redonePage.dateCreated, page.dateCreated)
        XCTAssertEqual(redonePage.dateModified, page.dateModified)
        XCTAssertEqual(redonePage.content.contentType, page.content.contentType)
        XCTAssertEqual(redonePage.content.page, redonePage)
    }

    func test_createPage_redoRecreatesPageOnCanvasIfOneWasSelected() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases])
        viewModel.selectedCanvasID = self.canvas.id
        let page = viewModel.createPage()

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        let redonePage = try XCTUnwrap(viewModel.pageCollection.objectWithID(page.id))
        XCTAssertNotNil(self.canvas.pages.first(where: { $0.page?.id == redonePage.id}))
    }


    //MARK: - createPages(fromFilesAtURLs:addingTo:centredOn:)
    func test_createPagesFromFilesAtURLs_createsNewPagesForSuppliedFileURLs() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = viewModel.createPages(fromFilesAtURLs: fileURLs)
        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages.first?.content.contentType, .image)
        XCTAssertEqual(pages.last?.content.contentType, .text)
    }

    func test_createPagesFromFilesAtURLs_doesntAddPagesToCanvasIfNoneSupplied() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = viewModel.createPages(fromFilesAtURLs: fileURLs)
        XCTAssertEqual(pages.first?.canvases.count, 0)
        XCTAssertEqual(pages.last?.canvases.count, 0)
    }

    func test_createPagesFromFilesAtURLs_addsPagesToCanvasIfOneSupplied() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = viewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: self.canvas)
        XCTAssertEqual(pages.first?.canvases.first?.canvas, self.canvas)
        XCTAssertEqual(pages.last?.canvases.first?.canvas, self.canvas)
    }

    func test_createPagesFromFilesAtURLs_ifFolderIsNilThenAddsPagesToFolderForNewPages() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let folder = self.modelController.collection(for: Folder.self).newObject()
        let page = self.modelController.collection(for: Page.self).newObject()
        folder.insert([page])

        viewModel.updateSelection([.page(page.id)])

        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = viewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: self.canvas)
        XCTAssertEqual(pages.first?.containingFolder, folder)
        XCTAssertEqual(pages.last?.containingFolder, folder)

        XCTAssertTrue(folder.contents.contains(where: { $0.id == pages[0].id }))
        XCTAssertTrue(folder.contents.contains(where: { $0.id == pages[1].id }))
    }

    func test_createPagesFromFilesAtURLs_ifFolderIsSetThenAddsPagesToSuppliedFolder() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let folder = self.modelController.collection(for: Folder.self).newObject()
        let page = self.modelController.collection(for: Page.self).newObject()
        viewModel.rootFolder.insert([page])

        viewModel.updateSelection([.page(page.id)])

        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = viewModel.createPages(fromFilesAtURLs: fileURLs, in: folder, addingTo: self.canvas)
        XCTAssertEqual(pages.first?.containingFolder, folder)
        XCTAssertEqual(pages.last?.containingFolder, folder)

        XCTAssertTrue(folder.contents.contains(where: { $0.id == pages[0].id }))
        XCTAssertTrue(folder.contents.contains(where: { $0.id == pages[1].id }))
    }

    func test_createPagesFromFilesAtURLs_undoingRemovesPagesFromCollection() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = viewModel.createPages(fromFilesAtURLs: fileURLs)
        let imagePage = try XCTUnwrap(pages.first)
        let textPage = try XCTUnwrap(pages.last)

        self.modelController.undoManager.undo()

        XCTAssertNil(viewModel.pageCollection.objectWithID(imagePage.id))
        XCTAssertNil(viewModel.pageCollection.objectWithID(textPage.id))
    }

    func test_createPagesFromFilesAtURLs_undoingRemovesPagesFromCanvasIfOneWasSupplied() throws{
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = viewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: self.canvas)
        let imagePage = try XCTUnwrap(pages.first)
        let textPage = try XCTUnwrap(pages.last)

        self.modelController.undoManager.undo()

        XCTAssertNil(self.canvas.pages.first(where: { $0.page?.id == imagePage.id }))
        XCTAssertNil(self.canvas.pages.first(where: { $0.page?.id == textPage.id }))
    }

    func test_createPagesFromFilesAtURLs_redoingRecreatesPagesWithSameIDsAndContent() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = viewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: self.canvas)
        let imagePage = try XCTUnwrap(pages.first)
        let textPage = try XCTUnwrap(pages.last)

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        let redoneImagePage = try XCTUnwrap(viewModel.pageCollection.objectWithID(imagePage.id))
        XCTAssertEqual(redoneImagePage.title, imagePage.title)
        XCTAssertEqual(redoneImagePage.dateCreated, imagePage.dateCreated)
        XCTAssertEqual(redoneImagePage.dateModified, imagePage.dateModified)
        XCTAssertEqual(redoneImagePage.content.contentType, imagePage.content.contentType)
        XCTAssertEqual((redoneImagePage.content as? ImagePageContent)?.image, (imagePage.content as? ImagePageContent)?.image)

        let redoneTextPage = try XCTUnwrap(viewModel.pageCollection.objectWithID(textPage.id))
        XCTAssertEqual(redoneTextPage.title, textPage.title)
        XCTAssertEqual(redoneTextPage.dateCreated, textPage.dateCreated)
        XCTAssertEqual(redoneTextPage.dateModified, textPage.dateModified)
        XCTAssertEqual(redoneTextPage.content.contentType, textPage.content.contentType)
        XCTAssertEqual((redoneTextPage.content as? TextPageContent)?.text, (textPage.content as? TextPageContent)?.text)
    }

    func test_createPagesFromFilesAtURLs_redoingAddsPagesBackToCanvas() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let bundle = Bundle(for: type(of: self))
        let fileURLs = [
            bundle.url(forResource: "test-image", withExtension: "png")!,
            bundle.url(forResource: "test-rtf", withExtension: "rtf")!
        ]

        let pages = viewModel.createPages(fromFilesAtURLs: fileURLs, addingTo: self.canvas)
        let imagePage = try XCTUnwrap(pages.first)
        let textPage = try XCTUnwrap(pages.last)

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNotNil(self.canvas.pages.first(where: { $0.page?.id == imagePage.id }))
        XCTAssertNotNil(self.canvas.pages.first(where: { $0.page?.id == textPage.id }))
    }


    //MARK: - delete(_: [SideBarItem]) - Single Page
    func test_deleteSidebarItems_singlePage_deletesThatPageIfNotOnCanvas() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        viewModel.delete([.page(page.id)])

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
    }

    func test_deleteSidebarItems_singlePage_showsAlertIfThatPageOnACanvas() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        viewModel.delete([.page(self.page.id)])

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deleteSidebarItems_singlePage_doesntDeletePageIfAlertReturnsCancel() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertNotNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
    }

    func test_deleteSidebarItems_singlePage_deletesPageAndRemovesFromCanvasesIfAlertReturnsOK() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let canvas = self.modelController.collection(for: Canvas.self).newObject()
        let canvasPage = canvas.addPages([self.page])[0]

        viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertNil(self.modelController.collection(for: CanvasPage.self).objectWithID(canvasPage.id))
        XCTAssertNil(self.modelController.collection(for: CanvasPage.self).objectWithID(self.canvasPage.id))
    }

    func test_deleteSidebarItems_singlePage_removesPageFromSidebarSelectionIfItsThere() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        viewModel.updateSelection([.page(page.id), .page(self.page.id)])

        viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertEqual(viewModel.sidebarSelection, [.page(page.id)])
    }

    func test_deleteSidebarItems_singlePage_doesntChangeSidebarSelectionIfDeletedPageIsntInSelection() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        viewModel.updateSelection([.page(page.id), .canvases])

        let previousSelection = viewModel.sidebarSelection

        viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertEqual(viewModel.sidebarSelection, previousSelection)
    }

    func test_deleteSidebarItems_singlePage_removesPageFromContainingFolder() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])

        viewModel.delete([.page(page.id)])

        XCTAssertFalse(folder.contents.contains(where: { $0.id == page.id }))
    }

    func test_deleteSidebarItems_singlePage_undoRecreatesPageWithSameIDAndAnyAttribtues() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject() {
            $0.title = "Test Page"
            $0.dateModified = $0.dateCreated.addingTimeInterval(200)
            $0.content = ImagePageContent()
        }
        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.page(page.id)])

        self.modelController.undoManager.undo()

        let undonePage = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertEqual(undonePage.title, page.title)
        XCTAssertEqual(undonePage.dateModified, page.dateModified)
        XCTAssertEqual(undonePage.dateCreated, page.dateCreated)
        XCTAssertEqual(undonePage.content.contentType, page.content.contentType)
        XCTAssertEqual(undonePage.content.page, undonePage)
    }

    func test_deleteSidebarItem_singlePage_undoAddsPagesAndReLinksPagesBackToAnyCanvases() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let childPage = self.modelController.collection(for: Page.self).newObject()
        let childCanvasPage = self.canvas.add(childPage, linkedFrom: self.canvasPage)
        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(self.page.id))
        XCTAssertNotNil(self.modelController.collection(for: Page.self).objectWithID(childPage.id))

        self.modelController.undoManager.undo()

        let undoneCanvasPage = try XCTUnwrap(self.modelController.collection(for: CanvasPage.self).objectWithID(self.canvasPage.id))
        XCTAssertEqual(childCanvasPage.parent, undoneCanvasPage)
    }

    func test_deleteSidebarItem_singlePage_undoAddsPageBackToPreviousFolder() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])
        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.page(page.id)])

        self.modelController.undoManager.undo()

        let undonePage = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertEqual(undonePage.containingFolder, folder)
        XCTAssertTrue(folder.contents.contains(where: { $0.id == page.id }))
    }

    func test_deleteSidebarItem_singlePage_redoDeletesPageAgain() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()

        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.page(page.id)])

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
    }

    func test_deleteSidebarItem_singlePage_redoDeletesPageAgainWithoutShowingAlert() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        window.callback = nil

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(self.page.id))
    }

    func test_deleteSidebarItem_singlePage_redoRemovesPageFromAnyCanvasesAgain() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.page(self.page.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        window.callback = nil

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(self.modelController.collection(for: CanvasPage.self).objectWithID(self.canvasPage.id))
    }

    func test_deleteSidebarItem_singlePage_redoRemovesPageFromItsContainingFolderAgain() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])

        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.page(page.id)])

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertFalse(folder.contents.contains(where: { $0.id == page.id }))
    }


    //MARK: - delete(_: [SideBarItem]) - Single Folder
    func test_deleteSidebarItems_singleFolder_deletesThatFolderIfEmpty() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()

        viewModel.delete([.folder(folder.id)])

        XCTAssertNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
    }

    func test_deleteSidebarItems_singleFolder_showsAlertIfFolderContainsItems() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])

        viewModel.delete([.folder(folder.id)])

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deleteSidebarItems_singleFolder_doesntDeleteFolderIfAlertReturnsCancel() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])

        viewModel.delete([.folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertNotNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
    }

    func test_deleteSidebarItems_singleFolder_deletesFolderAndContentsIfAlertReturnsOK() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])

        viewModel.delete([.folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
    }

    func test_deleteSidebarItems_singleFolder_removesFolderFromSidebarSelection() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])

        viewModel.updateSelection([.page(self.page.id), .folder(folder.id)])

        viewModel.delete([.folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertEqual(viewModel.sidebarSelection, [.page(self.page.id)])
    }

    func test_deleteSidebarItems_singleFolder_removesContainedItemsFromSidebarSelection() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])

        viewModel.updateSelection([.page(page.id), .page(self.page.id)])

        viewModel.delete([.folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertEqual(viewModel.sidebarSelection, [.page(self.page.id)])
    }

    func test_deleteSidebarItems_singleFolder_removesFolderFromContainingFolder() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()
        viewModel.rootFolder.insert([folder])

        viewModel.delete([.folder(folder.id)])

        XCTAssertFalse(viewModel.rootFolder.contents.contains(where: { $0.id == folder.id }))
    }

    func test_deleteSidebarItems_singleFolder_doesntDoAnythingIfAttemptingToDeleteRootFolder() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let rootFolder = viewModel.rootFolder
        viewModel.delete([.folder(rootFolder.id)])

        XCTAssertNil(window.suppliedAlert)
        XCTAssertNil(window.callback)

        XCTAssertEqual(viewModel.rootFolder, rootFolder)
    }

    func test_deleteSidebarItems_singleFolder_undoRecreatesFolderWithSameIDAndAttributes() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject() {
            $0.title = "My Great Folder"
        }

        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.folder(folder.id)])

        self.modelController.undoManager.undo()

        let undoneFolder = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertEqual(undoneFolder.title, folder.title)
    }

    func test_deleteSidebarItem_singleFolder_undoRecreatesFolderContents() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let page2 = self.modelController.collection(for: Page.self).newObject()
        let childFolder = self.modelController.collection(for: Folder.self).newObject()
        let childPage = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page, page2, childFolder])
        childFolder.insert([childPage])

        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.folder(folder.id)])

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
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()
        viewModel.rootFolder.insert([folder])

        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.folder(folder.id)])

        self.modelController.undoManager.undo()

        let undoneFolder = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertTrue(viewModel.rootFolder.contents.contains(where: { $0.id == undoneFolder.id }))
        XCTAssertEqual(undoneFolder.containingFolder, viewModel.rootFolder)
    }

    func test_deleteSidebarItem_singleFolder_redoDeletesFolderAndContentsAgainWithoutDisplayingAlert() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let page2 = self.modelController.collection(for: Page.self).newObject()
        let childFolder = self.modelController.collection(for: Folder.self).newObject()
        let childPage = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page, page2, childFolder])
        childFolder.insert([childPage])

        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.folder(folder.id)])

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
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()

        viewModel.delete([.page(page.id), .folder(folder.id)])

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deleteSidebarItems_multipleItems_doesntDeleteItemsIfAlertReturnsCancel() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()

        viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertNotNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertNotNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
    }

    func test_deleteSidebarItems_multipleItems_deletesItemsIfAlertReturnsOK() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()

        viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(page.id))
        XCTAssertNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
    }

    func test_deleteSidebarItems_multipleItems_removesItemsFromSidebarSelection() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()

        viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])

        viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertEqual(viewModel.sidebarSelection, [.page(self.page.id), .canvases])
    }

    func test_deleteSidebarItems_multipleItems_removesItemsEvenIfSuppliedItemIsContainedInASuppliedFolder() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let childPage = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([childPage])

        viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])

        viewModel.delete([.page(childPage.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertNil(self.modelController.collection(for: Page.self).objectWithID(childPage.id))
        XCTAssertNil(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
    }

    func test_deleteSidebarItems_multipleItems_removesItemsFromContainingFolder() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        viewModel.rootFolder.insert([page, folder])

        viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])

        viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertFalse(viewModel.rootFolder.contents.contains(where: { $0.id == page.id }))
        XCTAssertFalse(viewModel.rootFolder.contents.contains(where: { $0.id == folder.id }))
    }

    func test_deleteSidebarItems_multipleItems_undoRecreatesItemsWithSameIDAndAnyAttributes() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject() {
            $0.title = "Foobar"
            $0.dateModified = $0.dateCreated.addingTimeInterval(360)
        }
        let folder = self.modelController.collection(for: Folder.self).newObject() {
            $0.title = "Test Folder"
        }

        viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])
        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.page(page.id), .folder(folder.id)])

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
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        viewModel.rootFolder.insert([page, folder])

        viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])
        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()

        XCTAssertEqual(viewModel.rootFolder.contents.first?.id, page.id)
        XCTAssertEqual(viewModel.rootFolder.contents.last?.id, folder.id)
    }

    func test_deleteSidebarItem_multipleItems_undoAddsContentsBackToAnyFolders() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let childPage = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([childPage])

        viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])
        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.page(page.id), .folder(folder.id)])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()

        let undoneFolder = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(folder.id))
        XCTAssertEqual(undoneFolder.contents.first?.id, childPage.id)
    }

    func test_deleteSidebarItem_multipleItems_redoDeletesItemsAgainWithoutShowingAlert() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let childPage = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([childPage])

        viewModel.updateSelection([.page(self.page.id), .folder(folder.id), .canvases, .page(page.id)])
        self.modelController.undoManager.removeAllActions()
        viewModel.delete([.page(page.id), .folder(folder.id)])

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
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id)
        viewModel.addPage(at: link, to: self.canvas)

        XCTAssertEqual(self.canvas.pages.count, 2)
        XCTAssertTrue(self.canvas.pages.map { $0.page }.contains(page))
    }

    func test_addPage_addedPageDoesntHaveParentIfLinkDoesntHaveSource() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id)
        viewModel.addPage(at: link, to: self.canvas)

        let canvasPage = self.canvas.pages.first(where: { $0.page == page })
        XCTAssertNil(canvasPage?.parent)
    }

    func test_addPage_addingPageSetsSourcePageAsParent() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id, source: self.canvasPage.id)
        viewModel.addPage(at: link, to: self.canvas)

        let canvasPage = self.canvas.pages.first(where: { $0.page == page })
        XCTAssertEqual(canvasPage?.parent, self.canvasPage)
    }

    func test_addPage_undoingRemovesPageFromCanvas() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id)
        viewModel.addPage(at: link, to: self.canvas)

        self.modelController.undoManager.undo()

        XCTAssertFalse(self.canvas.pages.map { $0.page }.contains(page))
    }

    func test_addPage_undoingDeletesCanvasPage() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id)
        let canvasPage = try XCTUnwrap(viewModel.addPage(at: link, to: self.canvas))

        self.modelController.undoManager.undo()

        XCTAssertNil(viewModel.canvasPageCollection.objectWithID(canvasPage.id))
    }

    func test_addPage_undoingRemovesPageFromSourcePagesChildren() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id, source: self.canvasPage.id)
        viewModel.addPage(at: link, to: self.canvas)

        self.modelController.undoManager.undo()

        XCTAssertEqual(self.canvasPage.children.count, 0)
    }

    func test_addPage_redoingAddsBackThePageWithSameIDAndProperties() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let page = viewModel.pageCollection.newObject()
        let link = PageLink(destination: page.id, source: self.canvasPage.id)
        let canvasPage = try XCTUnwrap(viewModel.addPage(at: link, to: self.canvas))

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        let undoneCanvasPage = try XCTUnwrap(viewModel.canvasPageCollection.objectWithID(canvasPage.id))
        XCTAssertEqual(undoneCanvasPage.parent, self.canvasPage)
        XCTAssertEqual(undoneCanvasPage.frame, canvasPage.frame)
    }


    //MARK: - createCanvas()
    func test_createCanvas_createsNewCanvas() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvas = viewModel.createCanvas()
        XCTAssert(viewModel.canvasCollection.all.contains(canvas))
    }

    func test_createCanvas_undoingCanvasCreationRemovesCanvas() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvas = viewModel.createCanvas()
        self.modelController.undoManager.undo()
        XCTAssertNil(viewModel.canvasCollection.objectWithID(canvas.id))
    }

    func test_createCanvas_redoingRecreatesCanvasWithSameIDAndProperties() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvas = viewModel.createCanvas()
        canvas.title = "Foo Bar Baz"
        canvas.sortIndex = 3
        canvas.viewPort = CGRect(x: 3, y: 90, width: 100, height: 240)
        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        let redoneCanvas = try XCTUnwrap(viewModel.canvasCollection.objectWithID(canvas.id))
        XCTAssertEqual(redoneCanvas.title, canvas.title)
        XCTAssertEqual(redoneCanvas.dateCreated, canvas.dateCreated)
        XCTAssertEqual(redoneCanvas.dateModified, canvas.dateModified)
        XCTAssertEqual(redoneCanvas.sortIndex, canvas.sortIndex)
        XCTAssertEqual(redoneCanvas.viewPort, canvas.viewPort)
    }


    //MARK: - delete(_:Canvas)
    func test_deleteCanvas_showsAlertIfCanvasHasPages() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        viewModel.delete(self.canvas)

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deleteCanvas_doesntShowAlertIfCanvasDoesntHaveAnyPages() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let canvas = viewModel.canvasCollection.newObject()

        viewModel.delete(canvas)

        XCTAssertNil(window.suppliedAlert)
    }

    func test_deleteCanvas_deletesCanvasIfItDoesntHaveAnyPages() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let canvas = viewModel.canvasCollection.newObject()

        viewModel.delete(canvas)

        XCTAssertFalse(viewModel.canvasCollection.all.contains(canvas))
    }

    func test_deleteCanvas_doesntDeleteCanvasIfItHasPagesButAlertReturnsCancel() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        viewModel.delete(self.canvas)

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertTrue(viewModel.canvasCollection.all.contains(self.canvas))
        XCTAssertTrue(viewModel.canvasPageCollection.all.contains(self.canvasPage))
    }

    func test_deleteCanvas_deletesCanvasIfItHasPagesAndAlertReturnsOK() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        viewModel.delete(self.canvas)

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertFalse(viewModel.canvasCollection.all.contains(self.canvas))
    }

    func test_deleteCanvas_deletingCanvasRemovesAllCanvasPages() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page2 = viewModel.pageCollection.newObject()
        let canvasPage2 = viewModel.canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.page = page2
        }

        viewModel.delete(self.canvas)

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        XCTAssertFalse(viewModel.canvasCollection.all.contains(self.canvas))
        XCTAssertFalse(viewModel.canvasPageCollection.all.contains(self.canvasPage))
        XCTAssertFalse(viewModel.canvasPageCollection.all.contains(canvasPage2))
    }

    func test_deleteCanvas_setsSelectedSidebarObjectIDToNilIfCanvasWasSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvas = viewModel.canvasCollection.newObject()
        viewModel.selectedSidebarObjectIDs = Set([canvas.id])

        viewModel.delete(canvas)

        XCTAssertEqual(viewModel.selectedSidebarObjectIDs.count, 0)
    }

    func test_deleteCanvas_undoRecreatesCanvasWithSameIDAndAttributes() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvas = viewModel.canvasCollection.newObject()
        canvas.title = "Hello World"
        canvas.viewPort = CGRect(x: 30, y: 40, width: 50, height: 60)

        self.modelController.undoManager.removeAllActions()

        viewModel.delete(canvas)
        self.modelController.undoManager.undo()

        let undoneCanvas = try XCTUnwrap(viewModel.canvasCollection.objectWithID(canvas.id))
        XCTAssertEqual(undoneCanvas.title, canvas.title)
        XCTAssertEqual(undoneCanvas.dateCreated, canvas.dateCreated)
        XCTAssertEqual(undoneCanvas.dateModified, canvas.dateModified)
        XCTAssertEqual(undoneCanvas.viewPort, canvas.viewPort)
    }

    func test_deleteCanvas_undoAddsAnyPagesBackToCanvasWithSameFrames() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let canvas = viewModel.canvasCollection.newObject()
        let secondPage = viewModel.pageCollection.newObject()
        let canvasPage1 = try XCTUnwrap(canvas.addPages([self.page], centredOn: CGPoint(x: -40, y: -30)).first)
        let canvasPage2 = canvas.add(secondPage, linkedFrom: canvasPage1)
        self.modelController.undoManager.removeAllActions()

        viewModel.delete(canvas)
        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()

        let undoneCanvasPage1 = try XCTUnwrap(viewModel.canvasPageCollection.objectWithID(canvasPage1.id))
        let undoneCanvasPage2 = try XCTUnwrap(viewModel.canvasPageCollection.objectWithID(canvasPage2.id))

        XCTAssertEqual(undoneCanvasPage1.canvas, canvas)
        XCTAssertEqual(undoneCanvasPage1.frame, canvasPage1.frame)
        XCTAssertEqual(undoneCanvasPage1.page, self.page)

        XCTAssertEqual(undoneCanvasPage2.canvas, canvas)
        XCTAssertEqual(undoneCanvasPage2.frame, canvasPage2.frame)
        XCTAssertEqual(undoneCanvasPage2.page, secondPage)
        XCTAssertEqual(undoneCanvasPage2.parent, undoneCanvasPage1)
    }

    func test_deleteCanvas_undoSetsSidebarSelectionBackToCanavsIfItWasSelected() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvas = viewModel.canvasCollection.newObject()
        viewModel.selectedSidebarObjectIDs = Set([canvas.id])
        self.modelController.undoManager.removeAllActions()

        viewModel.delete(canvas)
        self.modelController.undoManager.undo()

        XCTAssertEqual(viewModel.selectedSidebarObjectIDs.first, canvas.id)
    }

    func test_deleteCanvas_redoingDeletesCanvasAgainButWithoutAnyAlert() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let canvas = viewModel.canvasCollection.newObject()
        self.modelController.undoManager.removeAllActions()

        viewModel.delete(canvas)
        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(window.suppliedAlert)
        XCTAssertNil(viewModel.canvasCollection.objectWithID(canvas.id))
    }

    func test_deleteCanvas_redoingRemovesPagesFromCanvasAgainButWithoutAnyAlert() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let canvas = viewModel.canvasCollection.newObject()
        let secondPage = viewModel.pageCollection.newObject()
        let canvasPage1 = try XCTUnwrap(canvas.addPages([self.page], centredOn: CGPoint(x: -40, y: -30)).first)
        let canvasPage2 = canvas.add(secondPage, linkedFrom: canvasPage1)
        self.modelController.undoManager.removeAllActions()

        viewModel.delete(canvas)
        let callback = try XCTUnwrap(window.callback)
        callback(0)

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(viewModel.canvasCollection.objectWithID(canvas.id))
        XCTAssertNil(viewModel.canvasPageCollection.objectWithID(canvasPage1.id))
        XCTAssertNil(viewModel.canvasPageCollection.objectWithID(canvasPage2.id))
    }


    //MARK: - remove(_: CanvasPage)
    func test_removeCanvasPage_removesCanvasPageFromCanvas() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.remove(self.canvasPage)
        XCTAssertNil(self.canvasPage.canvas)
        XCTAssertFalse(self.canvas.pages.contains(self.canvasPage))
    }

    func test_removeCanvasPage_deletesCanvasPage() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.remove(self.canvasPage)
        XCTAssertNil(viewModel.canvasPageCollection.objectWithID(self.canvasPage.id))
    }

    func test_removeCanvasPage_removesAllChildPagesFromCanvas() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvasPageCollection = viewModel.canvasPageCollection
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }

        viewModel.remove(self.canvasPage)
        XCTAssertNil(child1.canvas)
        XCTAssertFalse(self.canvas.pages.contains(child1))
        XCTAssertNil(child2.canvas)
        XCTAssertFalse(self.canvas.pages.contains(child2))
    }

    func test_removeCanvasPage_deletesChildCanvasPages() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvasPageCollection = viewModel.canvasPageCollection
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }

        viewModel.remove(self.canvasPage)
        XCTAssertNil(canvasPageCollection.objectWithID(child1.id))
        XCTAssertNil(canvasPageCollection.objectWithID(child2.id))
    }

    func test_removeCanvasPage_undoingRecreatesCanvasPageWithSameIDAndProperties() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        self.modelController.undoManager.removeAllActions()
        viewModel.remove(self.canvasPage)

        //Sanity check
        XCTAssertFalse(viewModel.canvasPageCollection.all.contains(self.canvasPage))

        self.modelController.undoManager.undo()

        let undonePage = try XCTUnwrap(viewModel.canvasPageCollection.objectWithID(self.canvasPage.id))
        XCTAssertEqual(undonePage.frame, self.canvasPage.frame)
    }

    func test_removeCanvasPage_undoingAddsCanvasPageBackToCanvas() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        self.modelController.undoManager.removeAllActions()
        viewModel.remove(self.canvasPage)

        //Sanity Check
        XCTAssertFalse(self.canvas.pages.contains(self.canvasPage))

        self.modelController.undoManager.undo()

        let undonePage = try XCTUnwrap(viewModel.canvasPageCollection.objectWithID(self.canvasPage.id))
        XCTAssertEqual(undonePage.canvas, self.canvas)
    }

    func test_removeCanvasPage_undoingRecreatesAllChildPagesWithSameIDsAndProperties() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvasPageCollection = viewModel.canvasPageCollection
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

        viewModel.remove(self.canvasPage)

        self.modelController.undoManager.undo()

        let undoneChild1 = try XCTUnwrap(viewModel.canvasPageCollection.objectWithID(child1.id))
        XCTAssertEqual(undoneChild1.frame, child1.frame)
        let undoneChild2 = try XCTUnwrap(viewModel.canvasPageCollection.objectWithID(child2.id))
        XCTAssertEqual(undoneChild2.frame, child2.frame)
    }

    func test_removeCanvasPage_undoingAddsAllChildPagesBacktoCanvas() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvasPageCollection = viewModel.canvasPageCollection
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        self.modelController.undoManager.removeAllActions()

        viewModel.remove(self.canvasPage)

        self.modelController.undoManager.undo()

        let undoneChild1 = try XCTUnwrap(canvasPageCollection.objectWithID(child1.id))
        XCTAssertEqual(undoneChild1.canvas, self.canvas)
        let undoneChild2 = try XCTUnwrap(canvasPageCollection.objectWithID(child2.id))
        XCTAssertEqual(undoneChild2.canvas, self.canvas)
    }

    func test_removeCanvasPage_undoingCorrectlyConnectsAllParentChildRelationships() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvasPageCollection = viewModel.canvasPageCollection
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        self.modelController.undoManager.removeAllActions()

        viewModel.remove(self.canvasPage)

        self.modelController.undoManager.undo()

        let undonePage = try XCTUnwrap(canvasPageCollection.objectWithID(self.canvasPage.id))
        let undoneChild1 = try XCTUnwrap(canvasPageCollection.objectWithID(child1.id))
        XCTAssertEqual(undoneChild1.parent, undonePage)
        let undoneChild2 = try XCTUnwrap(canvasPageCollection.objectWithID(child2.id))
        XCTAssertEqual(undoneChild2.parent, undonePage)
    }

    func test_removeCanvasPage_redoingRemovesAndDeletesAllCanvasPagesAgain() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let canvasPageCollection = viewModel.canvasPageCollection
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage
        }
        self.modelController.undoManager.removeAllActions()

        viewModel.remove(self.canvasPage)

        self.modelController.undoManager.undo()
        self.modelController.undoManager.redo()

        XCTAssertNil(canvasPageCollection.objectWithID(self.canvasPage.id))
        XCTAssertNil(canvasPageCollection.objectWithID(child1.id))
        XCTAssertNil(canvasPageCollection.objectWithID(child2.id))
    }
}
