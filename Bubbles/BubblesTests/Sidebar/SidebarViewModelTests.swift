//
//  SidebarViewModelTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 05/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles


class SidebarViewModelTests: XCTestCase {

    var canvasCollection: ModelCollection<Canvas>!
    var pageCollection: ModelCollection<Page>!
    var undoManager: UndoManager!
    var notificationCenter: NotificationCenter!

    var modelController: TestModelController!

    override func setUp() {
        super.setUp()

        self.canvasCollection = ModelCollection<Canvas>() { _ in Canvas() }
        self.pageCollection = ModelCollection<Page>() { _ in Page(content: TextPageContent()) }
        self.undoManager = UndoManager()
        self.notificationCenter = NotificationCenter()

        self.modelController = TestModelController()
        self.modelController.undoManager = self.undoManager

        self.canvasCollection.modelController = self.modelController
        self.pageCollection.modelController = self.modelController
    }

    override func tearDown() {
        super.tearDown()

        self.canvasCollection = nil
        self.pageCollection = nil
        self.undoManager = nil
        self.notificationCenter = nil
    }

    private func createViewModel() -> SidebarViewModel {
        return  SidebarViewModel(canvases: self.canvasCollection,
                                 pages: self.pageCollection,
                                 undoManager: self.undoManager,
                                 notificationCenter: self.notificationCenter)
    }

    private func createCanvasObjects() -> (Canvas, Canvas, Canvas, Canvas, Canvas) {
        let o1 = self.canvasCollection.newObject()
        let o2 = self.canvasCollection.newObject()
        let o3 = self.canvasCollection.newObject()
        let o4 = self.canvasCollection.newObject()
        let o5 = self.canvasCollection.newObject()
        return (o1, o2, o3, o4, o5)
    }

    private func createPageObjects() -> (Page, Page, Page, Page, Page) {
        var o1, o2, o3, o4, o5: Page!
        self.pageCollection.disableUndo {
            o1 = self.pageCollection.newObject()
            o1.title = "a"
            o2 = self.pageCollection.newObject()
            o2.title = "b"
            o3 = self.pageCollection.newObject()
            o3.title = "c"
            o4 = self.pageCollection.newObject()
            o4.title = "d"
            o5 = self.pageCollection.newObject()
            o5.title = "e"
        }
        return (o1, o2, o3, o4, o5)
    }


    //MARK: - .canvasItems
    func test_canvasItems_returnsCanvasItemForEachCanvas() {
        let o1 = self.canvasCollection.newObject()
        let o2 = self.canvasCollection.newObject()
        let o3 = self.canvasCollection.newObject()
        let viewModel = self.createViewModel()

        let canvasItems = viewModel.canvasItems

        XCTAssertTrue(canvasItems.contains(where: { $0.canvas == o1 }))
        XCTAssertTrue(canvasItems.contains(where: { $0.canvas == o2 }))
        XCTAssertTrue(canvasItems.contains(where: { $0.canvas == o3 }))
    }

    func test_canvasItems_returnsCanvasItemsSortedByCanvasSortIndex() {
        let o1 = self.canvasCollection.newObject()
        o1.sortIndex = 2
        let o2 = self.canvasCollection.newObject()
        o2.sortIndex = 0
        let o3 = self.canvasCollection.newObject()
        o3.sortIndex = 1

        let viewModel = self.createViewModel()

        let canvasItems = viewModel.canvasItems

        XCTAssertEqual(canvasItems[0].canvas, o2)
        XCTAssertEqual(canvasItems[1].canvas, o3)
        XCTAssertEqual(canvasItems[2].canvas, o1)
    }


    //MARK: - .pageItems
    func test_pageItems_returnsPageItemForEachPage() {
        let o1 = self.pageCollection.newObject()
        let o2 = self.pageCollection.newObject()
        let o3 = self.pageCollection.newObject()
        let viewModel = self.createViewModel()

        let pageItems = viewModel.pageItems

        XCTAssertTrue(pageItems.contains(where: { $0.page == o1 }))
        XCTAssertTrue(pageItems.contains(where: { $0.page == o2 }))
        XCTAssertTrue(pageItems.contains(where: { $0.page == o3 }))
    }

    func test_pageItems_returnsPageItemsSortedByPageTitle() {
        let o1 = self.pageCollection.newObject()
        o1.title = "Foo"
        let o2 = self.pageCollection.newObject()
        o2.title = "Bar"
        let o3 = self.pageCollection.newObject()
        o3.title = "Baz"

        let viewModel = self.createViewModel()

        let pageItems = viewModel.pageItems

        XCTAssertEqual(pageItems[0].page, o2)
        XCTAssertEqual(pageItems[1].page, o3)
        XCTAssertEqual(pageItems[2].page, o1)
    }


    //MARK: - moveCanvas(with:toIndex:)
    func test_moveCanvas_doesntMoveItemsIfNoObjectMatchesID() {
        let (o1, o2, o3, o4, o5) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.moveCanvas(with: Canvas.modelID(with: UUID()), aboveCanvasAtIndex: 2)

        let canvases = viewModel.canvasItems.map { $0.canvas }
        XCTAssertEqual(canvases, [o1, o2, o3, o4, o5])
    }

    func test_moveCanvas_movingFirstItemToStart() {
        let (o1, o2, o3, o4, o5) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.moveCanvas(with: o1.id, aboveCanvasAtIndex: 0)

        let canvases = viewModel.canvasItems.map { $0.canvas }
        XCTAssertEqual(canvases, [o1, o2, o3, o4, o5])
    }

    func test_moveCanvas_movingFirstItemToMiddle() {
        let (o1, o2, o3, o4, o5) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.moveCanvas(with: o1.id, aboveCanvasAtIndex: 3)

        let canvases = viewModel.canvasItems.map { $0.canvas }
        XCTAssertEqual(canvases, [o2, o3, o1, o4, o5])
    }

    func test_moveCanvas_movingFirstItemToEnd() {
        let (o1, o2, o3, o4, o5) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.moveCanvas(with: o1.id, aboveCanvasAtIndex: 5)

        let canvases = viewModel.canvasItems.map { $0.canvas }
        XCTAssertEqual(canvases, [o2, o3, o4, o5, o1])
    }

    func test_moveCanvas_movingMiddleItemToStart() {
        let (o1, o2, o3, o4, o5) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.moveCanvas(with: o3.id, aboveCanvasAtIndex: 0)

        let canvases = viewModel.canvasItems.map { $0.canvas }
        XCTAssertEqual(canvases, [o3, o1, o2, o4, o5])
    }

    func test_moveCanvas_movingMiddleItemToMiddle() {
        let (o1, o2, o3, o4, o5) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.moveCanvas(with: o3.id, aboveCanvasAtIndex: 3)

        let canvases = viewModel.canvasItems.map { $0.canvas }
        XCTAssertEqual(canvases, [o1, o2, o3, o4, o5])
    }

    func test_moveCanvas_movingMiddleItemToEnd() {
        let (o1, o2, o3, o4, o5) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.moveCanvas(with: o3.id, aboveCanvasAtIndex: 5)

        let canvases = viewModel.canvasItems.map { $0.canvas }
        XCTAssertEqual(canvases, [o1, o2, o4, o5, o3])
    }

    func test_moveCanvas_movingLastItemToStart() {
        let (o1, o2, o3, o4, o5) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.moveCanvas(with: o5.id, aboveCanvasAtIndex: 0)

        let canvases = viewModel.canvasItems.map { $0.canvas }
        XCTAssertEqual(canvases, [o5, o1, o2, o3, o4])
    }

    func test_moveCanvas_movingLastItemToMiddle() {
        let (o1, o2, o3, o4, o5) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.moveCanvas(with: o5.id, aboveCanvasAtIndex: 3)

        let canvases = viewModel.canvasItems.map { $0.canvas }
        XCTAssertEqual(canvases, [o1, o2, o3, o5, o4])
    }

    func test_moveCanvas_movingLastItemToEnd() {
        let (o1, o2, o3, o4, o5) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.moveCanvas(with: o5.id, aboveCanvasAtIndex: 5)

        let canvases = viewModel.canvasItems.map { $0.canvas }
        XCTAssertEqual(canvases, [o1, o2, o3, o4, o5])
    }


    //MARK: - .selectedObjectID
    func test_selectedObjectID_settingDoesntAddUndoIfUndoManagerIsntUndoingOrRedoing() {
        XCTAssertFalse(self.undoManager.canUndo)

        let viewModel = self.createViewModel()
        viewModel.selectedObjectID = Canvas.modelID(with: UUID())

        XCTAssertFalse(self.undoManager.canUndo)
    }

    func test_selectedObjectID_tellsViewToReloadSelection() {
        let mockSidebarView = MockSidebarView()

        let viewModel = self.createViewModel()
        viewModel.view = mockSidebarView

        viewModel.selectedObjectID = Canvas.modelID(with: UUID())

        XCTAssertTrue(mockSidebarView.reloadSelectionCalled)
    }

    func test_selectedObjectID_tellsDelegateOfChange() {
        let mockDelegate = MockSidebarViewModelDelegate()

        let viewModel = self.createViewModel()
        viewModel.delegate = mockDelegate

        viewModel.selectedObjectID = Canvas.modelID(with: UUID())

        XCTAssertTrue(mockDelegate.selectedObjectDidChangeCalled)
    }


    //MARK: - .selectedCanvasRow
    func test_selectedCanvasRow_returnsIndexOfCanvasIfOneIsSelected() {
        let (_, _, _, selectedCanvas, _) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectID = selectedCanvas.id

        XCTAssertEqual(viewModel.selectedCanvasRow, 3)
    }

    func test_selectedCanvasRow_returnsMinus1IfPageSelected() {
        _ = self.createCanvasObjects()
        let selectedPage = self.pageCollection.newObject()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectID = selectedPage.id

        XCTAssertEqual(viewModel.selectedCanvasRow, -1)
    }

    func test_selectedCanvasRow_returnsMinus1IfCanvasNotInCollectionIsSelected() {
        _ = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectID = Canvas.modelID(with: UUID())

        XCTAssertEqual(viewModel.selectedCanvasRow, -1)
    }

    func test_selectedCanvasRow_setsSelectedObjectIDToCanvasAtSuppliedIndex() {
        let (_, expectedCanvas, _, _, _) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedCanvasRow = 1

        XCTAssertEqual(viewModel.selectedObjectID, expectedCanvas.id)
    }

    func test_selectedCanvasRow_doesntChangeSelectedObjectIDIfNewIndexIsLessThan0() {
        let (_, expectedCanvas, _, _, _) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectID = expectedCanvas.id

        viewModel.selectedCanvasRow = -1

        XCTAssertEqual(viewModel.selectedObjectID, expectedCanvas.id)
    }

    func test_selectedCanvasRow_doesntChangeSelectedObjectIDIfNewIndexIsBeyondBounds() {
        let (_, _, _, expectedCanvas, _) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectID = expectedCanvas.id

        viewModel.selectedCanvasRow = 5

        XCTAssertEqual(viewModel.selectedObjectID, expectedCanvas.id)
    }


    //MARK: - .selectedPageRow
    func test_selectedPageRow_returnsIndexOfPageIfOneIsSelected() {
        let (_, _, selectedPage, _, _) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectID = selectedPage.id

        XCTAssertEqual(viewModel.selectedPageRow, 2)
    }

    func test_selectedPageRow_returnsMinus1IfCanvasSelected() {
        _ = self.createPageObjects()
        let selectedCanvas = self.canvasCollection.newObject()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectID = selectedCanvas.id

        XCTAssertEqual(viewModel.selectedPageRow, -1)
    }

    func test_selectedPageRow_returnsMinus1IfPageNotInCollectionIsSelected() {
        _ = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectID = Page.modelID(with: UUID())

        XCTAssertEqual(viewModel.selectedPageRow, -1)
    }

    func test_selectedPageRow_setsSelectedObjectIDToPageAtSuppliedIndex() {
        let (_, _, expectedPage, _, _) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedPageRow = 2

        XCTAssertEqual(viewModel.selectedObjectID, expectedPage.id)
    }

    func test_selectedPageRow_doesntChangeSelectedObjectIDIfNewIndexIsLessThan0() {
        let (_, _, _, expectedPage, _) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectID = expectedPage.id

        viewModel.selectedPageRow = -1

        XCTAssertEqual(viewModel.selectedObjectID, expectedPage.id)
    }

    func test_selectedPageRow_doesntChangeSelectedObjectIDIfNewIndexIsBeyondBounds() {
        let (_, expectedPage, _, _, _) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectID = expectedPage.id

        viewModel.selectedPageRow = 5

        XCTAssertEqual(viewModel.selectedObjectID, expectedPage.id)
    }


    //MARK: - Observation
    func test_observation_selectsNewlyCreatedCanvas() {
        let (_, c2, _, _, _) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.startObserving()
        viewModel.selectedObjectID = c2.id

        let newCanvas = self.canvasCollection.newObject()

        XCTAssertEqual(viewModel.selectedObjectID, newCanvas.id)
    }

    func test_observation_selectsNewlyCreatedPageIfPageAlreadySelected() {
        let (_, _, p3, _, _) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.startObserving()
        viewModel.selectedObjectID = p3.id

        let newPage = self.pageCollection.newObject()

        XCTAssertEqual(viewModel.selectedObjectID, newPage.id)
    }

    func test_observation_doesntSelectNewlyCreatedPageIfCanvasSelected() {
        let (_, c2, _, _, _) = self.createCanvasObjects()
        _ = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.startObserving()
        viewModel.selectedObjectID = c2.id

        self.pageCollection.newObject()

        XCTAssertEqual(viewModel.selectedObjectID, c2.id)
    }


    //MARK: - Selection Undo
//    func test_selectionUndo_undoingAnEditRevertsSelectionIfDifferent() {
//        let (o1, _, o3, o4, _) = self.createPageObjects()
//
//        self.undoManager.groupsByEvent = false
//
//        let viewModel = self.createViewModel()
//        viewModel.selectedObjectID = o4.id
//        self.undoManager.beginUndoGrouping()
//        o4.title = "Foo"
//        self.undoManager.endUndoGrouping()
//
//        RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 1))
//
//        viewModel.selectedObjectID = o3.id
//        self.undoManager.beginUndoGrouping()
//        o3.title = "Bar"
//        self.undoManager.endUndoGrouping()
//
//        RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 1))
//
//        viewModel.selectedObjectID = o1.id
//        self.undoManager.beginUndoGrouping()
//        o1.title = "Baz"
//        self.undoManager.endUndoGrouping()
//
//        RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 1))
//
//        XCTAssertEqual(viewModel.selectedObjectID, o1.id)
//        XCTAssertTrue(self.undoManager.canUndo)
//        self.undoManager.undo()
//        XCTAssertEqual(viewModel.selectedObjectID, o1.id)
//        XCTAssertTrue(self.undoManager.canUndo)
//        self.undoManager.undo()
//        XCTAssertEqual(viewModel.selectedObjectID, o1.id)
//        XCTAssertTrue(self.undoManager.canUndo)
//        self.undoManager.undo()
//        XCTAssertEqual(viewModel.selectedObjectID, o4.id)
//        XCTAssertTrue(self.undoManager.canUndo)
//        self.undoManager.undo()
//        XCTAssertNil(viewModel.selectedObjectID)
//    }
//
//    func test_selectionUndo_redoingAnEditRedoesSelectionIfDifferent() {
//        XCTFail()
//    }
//
//    func test_selectionUndo_undoingAnEditDoesntChangeSelectionIfTheSame() {
//        XCTFail()
//    }
//
//    func test_selectionUndo_redoingAnEditDoesntChangeSelectionIfTheSame() {
//        XCTFail()
//    }
}


//MARK: - Helpers

private class MockSidebarView: SidebarView {
    var reloadSelectionCalled = false
    func reloadSelection() {
        self.reloadSelectionCalled = true
    }

    var reloadCanvasesCalled = false
    func reloadCanvases() {
        self.reloadCanvasesCalled = true
    }

    var reloadPagesCalled = false
    func reloadPages() {
        self.reloadPagesCalled = true
    }
}

private class MockSidebarViewModelDelegate: SidebarViewModelDelegate {
    var selectedObjectDidChangeCalled = false
    func selectedObjectDidChange(in viewModel: SidebarViewModel) {
        self.selectedObjectDidChangeCalled = true
    }
}
