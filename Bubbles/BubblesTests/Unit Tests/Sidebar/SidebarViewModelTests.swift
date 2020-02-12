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

    var documentWindowViewModel: DocumentWindowViewModel!

    var modelController: TestModelController!

    override func setUp() {
        super.setUp()

        self.notificationCenter = NotificationCenter()

        self.modelController = TestModelController()
        self.undoManager = self.modelController.undoManager
        self.canvasCollection = self.modelController.addModelCollection(for: Canvas.self)
        self.pageCollection = self.modelController.addModelCollection(for: Page.self)
        self.modelController.addModelCollection(for: CanvasPage.self)

        self.documentWindowViewModel = MockDocumentWindowViewModel(modelController: self.modelController)

        self.canvasCollection.modelController = self.modelController
        self.pageCollection.modelController = self.modelController
    }

    override func tearDown() {
        super.tearDown()

        self.canvasCollection = nil
        self.pageCollection = nil
        self.undoManager = nil
        self.notificationCenter = nil
        self.documentWindowViewModel = nil
    }

    private func createViewModel() -> SidebarViewModel {
        return  SidebarViewModel(documentWindowViewModel: self.documentWindowViewModel,
                                 notificationCenter: self.notificationCenter)
    }

    @discardableResult private func createCanvasObjects() -> (Canvas, Canvas, Canvas, Canvas, Canvas) {
        let o1 = self.canvasCollection.newObject()
        let o2 = self.canvasCollection.newObject()
        let o3 = self.canvasCollection.newObject()
        let o4 = self.canvasCollection.newObject()
        let o5 = self.canvasCollection.newObject()
        return (o1, o2, o3, o4, o5)
    }

    @discardableResult private func createPageObjects() -> (Page, Page, Page, Page, Page) {
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
        viewModel.sortKey = .title

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


    //MARK: - .selectedObjectIDs
    func test_selectedObjectID_settingDoesntAddUndoIfUndoManagerIsntUndoingOrRedoing() {
        XCTAssertFalse(self.undoManager.canUndo)

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([Canvas.modelID(with: UUID())])

        XCTAssertFalse(self.undoManager.canUndo)
    }

    func test_selectedObjectID_tellsViewToReloadSelection() {
        let mockSidebarView = MockSidebarView()

        let viewModel = self.createViewModel()
        viewModel.view = mockSidebarView

        viewModel.selectedObjectIDs = Set([Canvas.modelID(with: UUID())])

        XCTAssertTrue(mockSidebarView.reloadSelectionCalled)
    }

    func test_selectedObjectID_updatesDocumentWindowState() {
        let viewModel = self.createViewModel()
        let expectedID = Canvas.modelID(with: UUID())

        viewModel.selectedObjectIDs = Set([expectedID])

        XCTAssertEqual(self.documentWindowViewModel.selectedSidebarObjectIDs.first, expectedID)
    }


    //MARK: - .selectedCanvasRow
    func test_selectedCanvasRowIndexes_returnsIndexOfCanvasIfOneIsSelected() {
        let (_, _, _, selectedCanvas, _) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([selectedCanvas.id])

        XCTAssertEqual(viewModel.selectedCanvasRowIndexes, IndexSet(integer: 3))
    }

    func test_selectedCanvasRowIndexes_returnsMinus1IfPageSelected() {
        _ = self.createCanvasObjects()
        let selectedPage = self.pageCollection.newObject()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([selectedPage.id])

        XCTAssertEqual(viewModel.selectedCanvasRowIndexes, IndexSet())
    }

    func test_selectedCanvasRowIndexes_returnsMinus1IfCanvasNotInCollectionIsSelected() {
        _ = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([Canvas.modelID(with: UUID())])

        XCTAssertEqual(viewModel.selectedCanvasRowIndexes, IndexSet())
    }

    func test_selectedCanvasRowIndexes_setsSelectedObjectIDToCanvasAtSuppliedIndex() {
        let (_, expectedCanvas, _, _, _) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedCanvasRowIndexes = IndexSet(integer: 1)

        XCTAssertEqual(viewModel.selectedObjectIDs.first, expectedCanvas.id)
    }

    func test_selectedCanvasRowIndexes_doesntChangeSelectedObjectIDIfNewIndexIsLessThan0() {
        let (_, expectedCanvas, _, _, _) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([expectedCanvas.id])

        viewModel.selectedCanvasRowIndexes = IndexSet(integer: -1)

        XCTAssertEqual(viewModel.selectedObjectIDs.first, expectedCanvas.id)
    }

    func test_selectedCanvasRowIndexes_doesntChangeSelectedObjectIDIfNewIndexIsBeyondBounds() {
        let (_, _, _, expectedCanvas, _) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([expectedCanvas.id])

        viewModel.selectedCanvasRowIndexes = IndexSet(integer: 5)

        XCTAssertEqual(viewModel.selectedObjectIDs.first, expectedCanvas.id)
    }


    //MARK: - .selectedPageRowIndexes
    func test_selectedPageRowIndexes_returnsIndexOfPageIfOneIsSelected() {
        let (_, _, selectedPage, _, _) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([selectedPage.id])

        XCTAssertEqual(viewModel.selectedPageRowIndexes, IndexSet(integer: 2))
    }

    func test_selectedPageRowIndexes_returnsIndexesOfPagesIfMultipleAreSelected() {
        let (_, selectedPage1, _ , selectedPage2, _) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([selectedPage1.id, selectedPage2.id])

        XCTAssertEqual(viewModel.selectedPageRowIndexes, IndexSet([1, 3]))
    }

    func test_selectedPageRowIndexes_returnsMinus1IfCanvasSelected() {
        _ = self.createPageObjects()
        let selectedCanvas = self.canvasCollection.newObject()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([selectedCanvas.id])

        XCTAssertEqual(viewModel.selectedPageRowIndexes, IndexSet())
    }

    func test_selectedPageRowIndexes_returnsMinus1IfPageNotInCollectionIsSelected() {
        _ = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([Page.modelID(with: UUID())])

        XCTAssertEqual(viewModel.selectedPageRowIndexes, IndexSet())
    }

    func test_selectedPageRowIndexes_setsSelectedObjectIDsToPagesAtSuppliedIndex() {
        let (_, _, expectedPage, _, expectedPage2) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedPageRowIndexes = IndexSet([2, 4])

        XCTAssertTrue(viewModel.selectedObjectIDs.contains(expectedPage.id))
        XCTAssertTrue(viewModel.selectedObjectIDs.contains(expectedPage2.id))
    }

    func test_selectedPageRowIndexes_doesntChangeSelectedObjectIDIfNewIndexIsLessThan0() {
        let (_, _, _, expectedPage, _) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([expectedPage.id])

        viewModel.selectedPageRowIndexes = IndexSet(integer: -1)

        XCTAssertEqual(viewModel.selectedObjectIDs.first, expectedPage.id)
    }

    func test_selectedPageRowIndexes_doesntChangeSelectedObjectIDIfNewIndexIsBeyondBounds() {
        let (_, expectedPage, _, _, _) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.selectedObjectIDs = Set([expectedPage.id])

        viewModel.selectedPageRowIndexes = IndexSet(integer: 5)

        XCTAssertEqual(viewModel.selectedObjectIDs.first, expectedPage.id)
    }


    //MARK: - Observation
    func test_observation_selectsNewlyCreatedCanvas() {
        let (_, c2, _, _, _) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.startObserving()
        viewModel.selectedObjectIDs = Set([c2.id])

        let newCanvas = self.canvasCollection.newObject()

        XCTAssertEqual(viewModel.selectedObjectIDs.first, newCanvas.id)
    }

    func test_observation_selectsNewlyCreatedPageIfPageAlreadySelected() {
        let (_, _, p3, _, _) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.startObserving()
        viewModel.selectedObjectIDs = Set([p3.id])

        let newPage = self.pageCollection.newObject()

        XCTAssertEqual(viewModel.selectedObjectIDs.first, newPage.id)
    }

    func test_observation_doesntSelectNewlyCreatedPageIfCanvasSelected() {
        let (_, c2, _, _, _) = self.createCanvasObjects()
        _ = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.startObserving()
        viewModel.selectedObjectIDs = Set([c2.id])

        self.pageCollection.newObject()

        XCTAssertEqual(viewModel.selectedObjectIDs.first, c2.id)
    }


    //MARK: - deleteCanvases(atIndexes:)
    func test_deleteCanvasesAtIndexes_deletesCanvasAtSuppliedIndex() {
        let (_, _, c3, _, _) = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.deleteCanvases(atIndexes: IndexSet(integer: 2))

        XCTAssertFalse(self.canvasCollection.all.contains(c3))
        XCTAssertEqual(self.canvasCollection.all.count, 4)
    }

    func test_deleteCanvasesAtIndexes_doesntDeleteCanvasesIfIndexesAreOutsideOfBounds() {
        _ = self.createCanvasObjects()

        let viewModel = self.createViewModel()
        viewModel.deleteCanvases(atIndexes: IndexSet([-1, 6]))

        XCTAssertEqual(self.canvasCollection.all.count, 5)
    }


    //MARK: - deletePages(atIndexes:)
    func test_deletePagesAtIndexes_deletesPagesAtSuppliedIndex() {
        let (p1, _, p3, _, _) = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.deletePages(atIndexes: IndexSet([0, 2]))

        XCTAssertFalse(self.pageCollection.all.contains(p1))
        XCTAssertFalse(self.pageCollection.all.contains(p3))
        XCTAssertEqual(self.pageCollection.all.count, 3)
    }

    func test_deletePagesAtIndexes_doesntDeletePagesIfIndexesAreOutsideOfBounds() {
        _ = self.createPageObjects()

        let viewModel = self.createViewModel()
        viewModel.deletePages(atIndexes: IndexSet([-1, 6]))

        XCTAssertEqual(self.pageCollection.all.count, 5)
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

