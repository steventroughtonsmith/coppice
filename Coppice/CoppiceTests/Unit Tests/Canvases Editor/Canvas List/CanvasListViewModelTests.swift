//
//  CanvasListViewModelTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 21/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import Coppice
@testable import CoppiceCore
import XCTest

class CanvasListViewModelTests: XCTestCase {
    var modelController: MockCoppiceModelController!
    var documentViewModel: MockDocumentWindowViewModel!
    var viewModel: CanvasListViewModel!

    var canvas1: Canvas!
    var canvas2: Canvas!
    var canvas3: Canvas!

    override func setUp() {
        super.setUp()

        self.modelController = MockCoppiceModelController(undoManager: UndoManager())
        self.canvas1 = Canvas.create(in: self.modelController) { $0.sortIndex = 0 }
        self.canvas2 = Canvas.create(in: self.modelController) { $0.sortIndex = 1 }
        self.canvas3 = Canvas.create(in: self.modelController) { $0.sortIndex = 2 }

        self.documentViewModel = MockDocumentWindowViewModel(modelController: self.modelController)
        self.viewModel = CanvasListViewModel(documentWindowViewModel: self.documentViewModel)
    }

    //MARK: - .canvases
    func test_canvases_returnsAllCanvasesSortedBySortIndex() throws {
        XCTAssertEqual(self.viewModel.canvases, [self.canvas1, self.canvas2, self.canvas3])
    }

    func test_canvases_updatesIfCanvasIsAdded() throws {
        let newCanvas = Canvas.create(in: self.modelController) { $0.sortIndex = 3 }
        XCTAssertEqual(self.viewModel.canvases, [self.canvas1, self.canvas2, self.canvas3, newCanvas])
    }

    func test_canvases_updatesIfCanvasIsDeleted() throws {
        self.modelController.collection(for: Canvas.self).delete(self.canvas2)
        XCTAssertEqual(self.viewModel.canvases, [self.canvas1, self.canvas3])
    }

    func test_canvases_updatesIfCanvasSortIndexesAreChanged() throws {
        self.viewModel.startObserving()
        XCTAssertEqual(self.viewModel.canvases, [self.canvas1, self.canvas2, self.canvas3])
        self.canvas3.sortIndex = 1
        self.canvas2.sortIndex = 2
        XCTAssertEqual(self.viewModel.canvases, [self.canvas1, self.canvas3, self.canvas2])
    }


    //MARK: - .selectedCanvasIndex
    func test_selectedCanvasIndex_tellsViewToReloadSelectionWhenUpdated() throws {
        let view = TestCanvasListView()
        self.viewModel.view = view

        self.viewModel.selectedCanvasIndex = 5

        XCTAssertTrue(view.reloadSelectionCalled)
    }

    func test_selectedCanvasIndex_updatesWhenDocumentViewModelUpdates() throws {
        self.viewModel.startObserving()
        self.viewModel.selectedCanvasIndex = 0
        self.documentViewModel.selectedCanvasID = self.canvas2.id
        XCTAssertEqual(self.viewModel.selectedCanvasIndex, 1)
    }


    //MARK: - selectCanvas(atIndex:)
    func test_selectCanvasAtIndex_setsSelectedCanvasIDToNilIfIndexIsLessThan0() throws {
        self.documentViewModel.selectedCanvasID = self.canvas2.id
        self.viewModel.selectCanvas(atIndex: -1)
        XCTAssertNil(self.documentViewModel.selectedCanvasID)
    }

    func test_selectCanvasAtIndex_setsSelectedCanvasIDToNilIfIndexIsEqualToCanvasesCount() throws {
        self.documentViewModel.selectedCanvasID = self.canvas2.id
        self.viewModel.selectCanvas(atIndex: 3)
        XCTAssertNil(self.documentViewModel.selectedCanvasID)
    }

    func test_selectCanvasAtIndex_setsSelectedCanvasIDToIDOfCanvasAtSuppliedIndex() throws {
        self.documentViewModel.selectedCanvasID = self.canvas2.id
        self.viewModel.selectCanvas(atIndex: 2)
        XCTAssertEqual(self.documentViewModel.selectedCanvasID, self.canvas3.id)
    }


    //MARK: - addPage(with:toCanvasAtIndex:)
    func test_addPageWithIDToCanvasAtIndex_addsPagesToCanvasAtIndex() throws {
        let page = Page.create(in: self.modelController)

        self.viewModel.addPage(with: page.id, toCanvasAtIndex: 1)

        XCTAssertEqual([page], self.canvas2.pages.compactMap(\.page))
    }

    func test_addPageWithIDToCanvasAtIndex_addsToMiddleOfCanvasViewPort() throws {
        let page = Page.create(in: self.modelController)
        self.canvas2.viewPort = CGRect(x: 10, y: 10, width: 90, height: 90)

        self.viewModel.addPage(with: page.id, toCanvasAtIndex: 1)

        let canvasPage = try XCTUnwrap(self.canvas2.pages.first)

        XCTAssertEqual(canvasPage.frame.midPoint, CGPoint(x: 55, y: 55))
    }


    //MARK: - addPages(fromFilesAtURLs:toCanvasAtIndex:)
    func test_addPagesFromFilesAtURLs_tellsDocumentViewModelToCreateFiles() throws {
        let url = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))

        let pages = self.viewModel.addPages(fromFilesAtURLs: [url], toCanvasAtIndex: 2)

        let (urls, _, _, _) = try XCTUnwrap(self.modelController.createPagesFromFilesMock.arguments.first)
        XCTAssertEqual(urls, [url])
        XCTAssertEqual(pages.first?.canvasPages.first?.canvas, self.canvas3)
    }


    //MARK: - moveCanvas(with:aboveCanvasAtIndex:)
    func test_moveCanvasWithIDAboveCanvasAtIndex_doesNothingIfModelIDIsNotACanvas() throws {
        let canvas4 = Canvas.create(in: self.modelController) { $0.sortIndex = 3 }
        let canvas5 = Canvas.create(in: self.modelController) { $0.sortIndex = 4 }

        self.viewModel.moveCanvas(with: Page.modelID(with: UUID()), aboveCanvasAtIndex: 2)
        self.viewModel.moveCanvas(with: Folder.modelID(with: UUID()), aboveCanvasAtIndex: 2)
        self.viewModel.moveCanvas(with: CanvasPage.modelID(with: UUID()), aboveCanvasAtIndex: 2)

        XCTAssertEqual(self.canvas1.sortIndex, 0)
        XCTAssertEqual(self.canvas2.sortIndex, 1)
        XCTAssertEqual(self.canvas3.sortIndex, 2)
        XCTAssertEqual(canvas4.sortIndex, 3)
        XCTAssertEqual(canvas5.sortIndex, 4)
    }

    func test_moveCanvasWithIDAboveCanvasAtIndex_updatesSortIndexOfItemToMatchSuppliedIndex() throws {
        let canvas4 = Canvas.create(in: self.modelController) { $0.sortIndex = 3 }
        _ = Canvas.create(in: self.modelController) { $0.sortIndex = 4 }

        self.viewModel.moveCanvas(with: canvas4.id, aboveCanvasAtIndex: 2)

        XCTAssertEqual(canvas4.sortIndex, 2)
    }

    func test_moveCanvasWithIDAboveCanvasAtIndex_updatesIndexOfAllCanvasesBelowSuppliedIndexIfCanvasMovedUp() throws {
        let canvas4 = Canvas.create(in: self.modelController) { $0.sortIndex = 3 }
        let canvas5 = Canvas.create(in: self.modelController) { $0.sortIndex = 4 }

        self.viewModel.moveCanvas(with: canvas5.id, aboveCanvasAtIndex: 2)

        XCTAssertEqual(canvas5.sortIndex, 2)
        XCTAssertEqual(self.canvas3.sortIndex, 3)
        XCTAssertEqual(canvas4.sortIndex, 4)
    }

    func test_moveCanvasWithIDAboveCanvasAtIndex_updatesIndexOfAllCanvasesAboveSuppliedIndexIfCanvasMovedDown() throws {
        _ = Canvas.create(in: self.modelController) { $0.sortIndex = 3 }
        _ = Canvas.create(in: self.modelController) { $0.sortIndex = 4 }

        self.viewModel.moveCanvas(with: self.canvas1.id, aboveCanvasAtIndex: 3)

        XCTAssertEqual(self.canvas2.sortIndex, 0)
        XCTAssertEqual(self.canvas3.sortIndex, 1)
        XCTAssertEqual(self.canvas1.sortIndex, 2)
    }

    func test_moveCanvasWithIDAboveCanvasAtIndex_correctlyMovesItemToTopIfIndexIs0() throws {
        let canvas4 = Canvas.create(in: self.modelController) { $0.sortIndex = 3 }
        _ = Canvas.create(in: self.modelController) { $0.sortIndex = 4 }

        self.viewModel.moveCanvas(with: canvas4.id, aboveCanvasAtIndex: 0)

        XCTAssertEqual(canvas4.sortIndex, 0)
        XCTAssertEqual(self.canvas1.sortIndex, 1)
        XCTAssertEqual(self.canvas2.sortIndex, 2)
        XCTAssertEqual(self.canvas3.sortIndex, 3)
    }

    func test_moveCanvasWithIDAboveCanvasAtIndex_correctlyMovesItemToBottomifIndexEqualsCount() throws {
        let canvas4 = Canvas.create(in: self.modelController) { $0.sortIndex = 3 }
        let canvas5 = Canvas.create(in: self.modelController) { $0.sortIndex = 4 }

        self.viewModel.moveCanvas(with: self.canvas2.id, aboveCanvasAtIndex: 5)

        XCTAssertEqual(self.canvas3.sortIndex, 1)
        XCTAssertEqual(canvas4.sortIndex, 2)
        XCTAssertEqual(canvas5.sortIndex, 3)
        XCTAssertEqual(self.canvas2.sortIndex, 4)
    }


    //MARK: - deleteCanvas(atIndex:)
    func test_deleteCanvasAtIndex_doesNothingIfIndexIsLessThan0() throws {
        self.viewModel.deleteCanvas(atIndex: -1)
        XCTAssertNil(self.documentViewModel.deleteCanvasArguments)
    }

    func test_deleteCanvasAtIndex_doesNothingIfIndexIsEqualToCanvasCount() throws {
        self.viewModel.deleteCanvas(atIndex: 3)
        XCTAssertNil(self.documentViewModel.deleteCanvasArguments)
    }

    func test_deleteCanvasAtindex_tellsDocumentWindowViewModelToDeleteCanvas() throws {
        self.viewModel.deleteCanvas(atIndex: 1)
        let (deletedCanvas) = try XCTUnwrap(self.documentViewModel.deleteCanvasArguments)
        XCTAssertEqual(deletedCanvas, self.canvas2)
    }
}


class TestCanvasListView: CanvasListView {
    var reloadCalled = false
    func reload() {
        self.reloadCalled = true
    }

    var reloadSelectionCalled = false
    func reloadSelection() {
        self.reloadSelectionCalled = true
    }
}
