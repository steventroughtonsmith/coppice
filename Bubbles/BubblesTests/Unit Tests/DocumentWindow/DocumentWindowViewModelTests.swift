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

    var modelController: MockBubblesModelController!

    var folder: Folder!
    var canvas: Canvas!
    var canvasPage: CanvasPage!
    var page: Page!

    override func setUp() {
        super.setUp()
        self.modelController = MockBubblesModelController(undoManager: UndoManager())

        self.folder = self.modelController.createFolder(in: self.modelController.rootFolder)
        self.canvas = self.modelController.createCanvas()
        self.page = self.modelController.createPage(in: self.modelController.rootFolder)
        self.canvasPage = CanvasPage.create(in: self.modelController) {
            $0.page = self.page
            $0.canvas = self.canvas
        }
    }

    //MARK: - updateSelection(_:)


    //MARK: - Selection Observation
    func test_selection_creatingNewPageSelectsItInSidebarIfEditorWasNotCanvasEditor() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.page(self.page.id)])

        let page = self.modelController.createPage(in: self.modelController.rootFolder)
        XCTAssertEqual(viewModel.sidebarSelection, [.page(page.id)])
    }

    func test_selection_creatingNewPageDoesntSelectItInSidebarIfEditorWasCanvasEditor() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases])

        self.modelController.createPage(in: self.modelController.rootFolder)
        XCTAssertEqual(viewModel.sidebarSelection, [.canvases])
    }

    func test_selection_creatingNewFolderSelectsItInSidebarIfEditorWasNotCanvasEditor() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.folder(self.folder.id)])

        let folder = self.modelController.createFolder(in: self.modelController.rootFolder)
        XCTAssertEqual(viewModel.sidebarSelection, [.folder(folder.id)])
    }

    func test_selection_creatingNewFolderDoesntSelectItInSidebarIfEditorWasCanvaseditor() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases])

        self.modelController.createFolder(in: self.modelController.rootFolder)
        XCTAssertEqual(viewModel.sidebarSelection, [.canvases])
    }

    func test_selection_creatingNewCanvasSelectsCanvasesInSidebarAndSetsAsSelectedCanvasID() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.page(self.page.id)])

        let canvas = self.modelController.createCanvas()
        XCTAssertEqual(viewModel.sidebarSelection, [.canvases])
        XCTAssertEqual(viewModel.selectedCanvasID, canvas.id)
    }

    func test_selection_deletingPageRemovesFromSelectionIfItWasSelected() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.page(self.page.id), .folder(self.folder.id)])

        self.modelController.delete(self.page)

        XCTAssertEqual(viewModel.sidebarSelection, [.folder(self.folder.id)])
    }

    func test_selection_deletingFolderRemovesFromSelectionIfItWasSelected() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.page(self.page.id), .folder(self.folder.id)])

        self.modelController.delete(self.folder)

        XCTAssertEqual(viewModel.sidebarSelection, [.page(self.page.id)])
    }

    func test_selection_deletingMultipleItemsRemoveFromSelectionIfItWasSelected() throws {
        let testPage = self.modelController.createFolder(in: self.modelController.rootFolder)
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.page(self.page.id), .page(testPage.id), .folder(self.folder.id)])

        self.modelController.delete(self.folder)
        self.modelController.delete(self.page)

        XCTAssertEqual(viewModel.sidebarSelection, [.page(testPage.id)])
    }

    func test_selection_deletingCanvasSetsSelectedCanvasIDToNil() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases, .page(self.page.id)])
        viewModel.selectedCanvasID = self.canvas.id

        self.modelController.delete(self.canvas)
        XCTAssertEqual(viewModel.sidebarSelection, [.canvases, .page(self.page.id)])
        XCTAssertNil(viewModel.selectedCanvasID)
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
        XCTAssertEqual(viewModel.folderForNewPages, self.modelController.rootFolder)
    }

    func test_folderForNewPages_returnsRootFolderAndNilIfOnlyCanvasesSelected() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        viewModel.updateSelection([.canvases])
        XCTAssertEqual(viewModel.folderForNewPages, self.modelController.rootFolder)
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


    //MARK: - deleteItems(_: [FolderContainable]) - Single Page
    func test_deleteSidebarItems_singlePage_tellsModelControllerToDeletePageWithoutAlertIfNotOnAnyCanvases() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.createPage(in: self.modelController.rootFolder)
        viewModel.deleteItems([page])

        let (deletedPage) = try XCTUnwrap(self.modelController.deleteFolderItemsMock.arguments[safe: 0])
        XCTAssertEqual(deletedPage.count, 1)
        XCTAssertEqual(deletedPage.first as? Page, page)
    }

    func test_deleteSidebarItems_singlePage_showsAlertIfPageIsOnACanvas() {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        viewModel.deleteItems([self.page])

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deleteSidebarItems_singlePage_doesntTellModelControllerToDeletePageIfAlertReturnsCancel() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        viewModel.deleteItems([self.page])

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertFalse(self.modelController.deletePageMock.wasCalled)
    }

    func test_deleteSidebarItems_singlePage_tellsModelControllerToDeletePageIfAlertReturnsOK() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let canvas = self.modelController.collection(for: Canvas.self).newObject()
        canvas.addPages([self.page])

        viewModel.deleteItems([self.page])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        let (deletedPage) = try XCTUnwrap(self.modelController.deleteFolderItemsMock.arguments[safe: 0])
        XCTAssertEqual(deletedPage.count, 1)
        XCTAssertEqual(deletedPage.first as? Page, page)
    }


    //MARK: - delete(_: [SideBarItem]) - Single Folder
    func test_deleteSidebarItems_singleFolder_tellsModelControllerToDeleteFolderWithoutAlertIfEmpty() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let folder = self.modelController.createFolder(in: self.modelController.rootFolder)

        viewModel.deleteItems([folder])

        let (deletedFolder) = try XCTUnwrap(self.modelController.deleteFolderItemsMock.arguments[safe: 0])
        XCTAssertEqual(deletedFolder.count, 1)
        XCTAssertEqual(deletedFolder.first as? Folder, folder)
    }

    func test_deleteSidebarItems_singleFolder_showsAlertIfFolderIsNotEmpty() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])

        viewModel.deleteItems([folder])

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deleteSidebarItems_singleFolder_doesntTellModelControllerToDeleteFolderIfAlertReturnsCancel() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([self.page])

        viewModel.deleteItems([folder])

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertFalse(self.modelController.deleteFolderMock.wasCalled)
    }

    func test_deleteSidebarItems_singleFolder_tellsModelControllerToDeleteFolderIfAlertReturnsOK() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()
        folder.insert([page])

        viewModel.deleteItems([folder])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        let (deletedFolder) = try XCTUnwrap(self.modelController.deleteFolderItemsMock.arguments[safe: 0])
        XCTAssertEqual(deletedFolder.count, 1)
        XCTAssertEqual(deletedFolder.first as? Folder, folder)
    }


    //MARK: - delete(_: [SideBarItem]) - Multiple Items
    func test_deleteSidebarItems_multipleItems_showsSimpleAlert() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()

        viewModel.deleteItems([page, folder])

        XCTAssertNotNil(window.suppliedAlert)
    }

    func test_deleteSidebarItems_multipleItems_doesntDeleteItemsIfAlertReturnsCancel() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()

        viewModel.deleteItems([page, folder])

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertFalse(self.modelController.deletePageMock.wasCalled)
        XCTAssertFalse(self.modelController.deleteFolderMock.wasCalled)
    }

    func test_deleteSidebarItems_multipleItems_deletesItemsIfAlertReturnsOK() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let page = self.modelController.collection(for: Page.self).newObject()
        let folder = self.modelController.collection(for: Folder.self).newObject()

        viewModel.deleteItems([page, folder])

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        let (deletedItems) = try XCTUnwrap(self.modelController.deleteFolderItemsMock.arguments[safe: 0])
        XCTAssertEqual(deletedItems.count, 2)
        XCTAssertEqual(deletedItems[safe: 0] as? Page, page)
        XCTAssertEqual(deletedItems[safe: 1] as? Folder, folder)
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

        let canvas = self.modelController.canvasCollection.newObject()

        viewModel.delete(canvas)

        XCTAssertNil(window.suppliedAlert)
    }

    func test_deleteCanvas_tellsModelControllerToDeleteCanvasIfItDoesntHaveAnyPages() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        let canvas = self.modelController.canvasCollection.newObject()

        viewModel.delete(canvas)

        let (deletedCanvas) = try XCTUnwrap(self.modelController.deleteCanvasMock.arguments[safe: 0])
        XCTAssertEqual(deletedCanvas, canvas)
    }

    func test_deleteCanvas_doesntTellModelControllerDeleteCanvasIfItHasPagesButAlertReturnsCancel() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        viewModel.delete(self.canvas)

        let callback = try XCTUnwrap(window.callback)
        callback(1)

        XCTAssertFalse(self.modelController.deletePageMock.wasCalled)
    }

    func test_deleteCanvas_tellsModelControllerToDeleteCanvasIfItHasPagesAndAlertReturnsOK() throws {
        let viewModel = DocumentWindowViewModel(modelController: self.modelController)
        let window = MockWindow()
        viewModel.window = window

        viewModel.delete(self.canvas)

        let callback = try XCTUnwrap(window.callback)
        callback(0)

        let (deletedCanvas) = try XCTUnwrap(self.modelController.deleteCanvasMock.arguments[safe: 0])
        XCTAssertEqual(deletedCanvas, canvas)
    }
}
