//
//  CanvasEditorViewModelTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 26/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class CanvasEditorViewModelTests: XCTestCase {
    var modelController: ModelController!
    var canvas: Canvas!
    var canvasPage1: CanvasPage!
    var canvasPage2: CanvasPage!

    var viewModel: CanvasEditorViewModel!

    override func setUp() {
        super.setUp()

        self.modelController = BubblesModelController(undoManager: UndoManager())
        self.canvas = self.modelController.collection(for: Canvas.self).newObject()

        let canvasPageCollection = self.modelController.collection(for: CanvasPage.self)
        self.canvasPage1 = canvasPageCollection.newObject()
        self.canvasPage1.canvas = self.canvas
        self.canvasPage2 = canvasPageCollection.newObject()
        self.canvasPage2.canvas = self.canvas

        self.viewModel = CanvasEditorViewModel(canvas: self.canvas, modelController: self.modelController)
    }

    override func tearDown() {
        self.modelController = nil
        self.canvas = nil
        self.canvasPage1 = nil
        self.canvasPage2 = nil
        self.viewModel = nil
        super.tearDown()
    }


    //MARK: - close(_:)
    func test_closeCanvasPage_removesPageFromCanvas() {
        self.viewModel.close(self.canvasPage1)
        XCTAssertNil(self.canvasPage1.canvas)
        XCTAssertFalse(self.canvas.pages.contains(self.canvasPage1))
    }

    func test_closeCanvasPage_deleteCanvasPage() {
        self.viewModel.close(self.canvasPage2)
        XCTAssertNil(self.modelController.collection(for: CanvasPage.self).objectWithID(self.canvasPage2.id))
    }


    //MARK: - Page Updating
    func test_updatingPages_returnsAllCanvasPagesInCanvasAfterInitialisation() {
        let canvasPages = self.viewModel.canvasPages
        XCTAssertEqual(canvasPages.count, 2)
        XCTAssertTrue(canvasPages.contains(self.canvasPage1))
        XCTAssertTrue(canvasPages.contains(self.canvasPage2))
    }

    func test_updatingPages_allPagesAreAddedToLayoutEngineAfterInitialisation() {
        let layoutPages = self.viewModel.layoutEngine.pages
        XCTAssertEqual(layoutPages.count, 2)
        XCTAssertTrue(layoutPages.contains(where: { $0.id == self.canvasPage1.id.uuid }))
        XCTAssertTrue(layoutPages.contains(where: { $0.id == self.canvasPage2.id.uuid }))
    }

    func test_updatingPages_addingPagesToCanvasUpdatesCanvasPages() {
        let newCanvasPage = self.modelController.collection(for: CanvasPage.self).newObject()
        newCanvasPage.canvas = self.canvas

        let canvasPages = self.viewModel.canvasPages
        XCTAssertEqual(canvasPages.count, 3)
        XCTAssertTrue(canvasPages.contains(newCanvasPage))
    }

    func test_updatingPages_addingPagesToCanvasAddsThosePagesToLayoutEngine() {
        let newCanvasPage = self.modelController.collection(for: CanvasPage.self).newObject()
        newCanvasPage.canvas = self.canvas

        let layoutPages = self.viewModel.layoutEngine.pages
        XCTAssertEqual(layoutPages.count, 3)
        XCTAssertTrue(layoutPages.contains(where: { $0.id == newCanvasPage.id.uuid }))
    }

    func test_updatingPages_removingPagesFromCanvasUpdatesCanvasPages() {
        self.modelController.collection(for: CanvasPage.self).delete(self.canvasPage1)

        let canvasPages = self.viewModel.canvasPages
        XCTAssertEqual(canvasPages.count, 1)
        XCTAssertFalse(canvasPages.contains(self.canvasPage1))
    }

    func test_updatingPages_removingPagesFromCanvasRemovesThosePagesFromLayoutEngine() {
        self.modelController.collection(for: CanvasPage.self).delete(self.canvasPage2)

        let layoutPages = self.viewModel.layoutEngine.pages
        XCTAssertEqual(layoutPages.count, 1)
        XCTAssertFalse(layoutPages.contains(where: { $0.id == self.canvasPage2.id.uuid }))
    }


    //MARK: - canvasPage(with:)
    func test_canvasPageWithUUID_returnsCanvasPageWhosIDMatchesUUID() {
        XCTAssertEqual(self.viewModel.canvasPage(with: self.canvasPage2.id.uuid), self.canvasPage2)
    }

    func test_canvasPageWithUUID_returnsNilIfNoCanvasPageMatchesUUID() {
        XCTAssertNil(self.viewModel.canvasPage(with: UUID()))
    }


    //MARK: .zoomFactor
    func test_zoomFactor_capsZoomFactorToMaximumOf1() {
        self.viewModel.zoomFactor = 1.5
        XCTAssertEqual(self.viewModel.zoomFactor, 1, accuracy: 0.001)
    }

    func test_zoomFactor_capsZoomFactorToMinimumOfPoint25() {
        self.viewModel.zoomFactor = 0.24
        XCTAssertEqual(self.viewModel.zoomFactor, 0.25, accuracy: 0.001)
    }

    func test_zoomFactor_tellsViewToUpdateWhenSetToValueInsideBounds() {
        let view = TestCanvasEditorView()
        self.viewModel.view = view

        self.viewModel.zoomFactor = 0.6
        XCTAssertTrue(view.updateZoomFactorCalled)
    }

    func test_zoomFactor_tellsViewToUpdateWhenSetToValueAboveMax() {
        let view = TestCanvasEditorView()
        self.viewModel.view = view

        self.viewModel.zoomFactor = 1.6
        XCTAssertTrue(view.updateZoomFactorCalled)
    }

    func test_zoomFactor_tellsViewToUpdateWhenSetToValueBelowMinimum() {
        let view = TestCanvasEditorView()
        self.viewModel.view = view

        self.viewModel.zoomFactor = 0.2
        XCTAssertTrue(view.updateZoomFactorCalled)
    }


    //MARK: - .zoomLevels
    func test_zoomLevels_returnsJustStepsBetween25And100IfZoomFactorIs1() {
        self.viewModel.zoomFactor = 1
        XCTAssertEqual(self.viewModel.zoomLevels, [25, 50, 75, 100])
    }

    func test_zoomLevels_returnsJustStepsBetween25And100IfZoomFactorIsPoint75() {
        self.viewModel.zoomFactor = 0.75
        XCTAssertEqual(self.viewModel.zoomLevels, [25, 50, 75, 100])
    }

    func test_zoomLevels_returnsJustStepsBetween25And100IfZoomFactorIsPoint5() {
        self.viewModel.zoomFactor = 0.50
        XCTAssertEqual(self.viewModel.zoomLevels, [25, 50, 75, 100])
    }

    func test_zoomLevels_returnsJustStepsBetween25And100IfZoomFactorIsPoint25() {
        self.viewModel.zoomFactor = 0.25
        XCTAssertEqual(self.viewModel.zoomLevels, [25, 50, 75, 100])
    }

    func test_zoomLevels_includesAdditionalStepBefore50IfZoomFactorIsBetweenPoint25AndPoint5() {
        self.viewModel.zoomFactor = 0.329
        XCTAssertEqual(self.viewModel.zoomLevels, [25, 32, 50, 75, 100])
    }

    func test_zoomLevels_includesAdditionalStepBefore75IfZoomFactorIsBetweenPoint5AndPoint75() {
        self.viewModel.zoomFactor = 0.622
        XCTAssertEqual(self.viewModel.zoomLevels, [25, 50, 62, 75, 100])
    }

    func test_zoomLevels_includesAdditionalStepBefore100IfZoomFactorIsBetweenPoint75And1() {
        self.viewModel.zoomFactor = 0.875
        XCTAssertEqual(self.viewModel.zoomLevels, [25, 50, 75, 87, 100])
    }


    //MARK: .selectedZoomLevel
    func test_selectedZoomLevel_returnsIndexOfZoomIndexMatchingLevelForStandardLevel() {
        self.viewModel.zoomFactor = 0.5
        XCTAssertEqual(self.viewModel.selectedZoomLevel, 1)
    }

    func test_selectedZoomLevel_returnsIndexOfZoomIndexMatchingLevelForCustomLevel() {
        self.viewModel.zoomFactor = 0.875
        XCTAssertEqual(self.viewModel.selectedZoomLevel, 3)
    }

    func test_selectedZoomLevel_settingSelectedZoomLevelSetsZoomFactorTo100thOfMatchingZoomLevel() {
        self.viewModel.selectedZoomLevel = 2
        XCTAssertEqual(self.viewModel.zoomFactor, 0.75, accuracy: 0.001)
    }

    func test_selectedZoomLevel_settingSelectedZoomLevelToBelow0SetsTo0() {
        self.viewModel.selectedZoomLevel = -2
        XCTAssertEqual(self.viewModel.selectedZoomLevel, 0)
    }

    func test_selectedZoomLevel_settingSelectedZoomLevelToAboveNumberOfZoomLevelsSetsToLastZoomLevelIndex() {
        self.viewModel.selectedZoomLevel = 4
        XCTAssertEqual(self.viewModel.selectedZoomLevel, 3)
    }


    //MARK: .zoomIn/Out/To100
    func test_zoomIn_increasesZoomLevelIfStandardAndNotAtHighestZoom() {
        self.viewModel.zoomFactor = 0.5
        self.viewModel.zoomIn()
        XCTAssertEqual(self.viewModel.zoomFactor, 0.75, accuracy: 0.001)
    }

    func test_zoomIn_increasesZoomLevelIfCustomAndNotAtHighestZoom() {
        self.viewModel.zoomFactor = 0.43
        self.viewModel.zoomIn()
        XCTAssertEqual(self.viewModel.zoomFactor, 0.5, accuracy: 0.001)
    }

    func test_zoomOut_decreasesZoomLevelIfStandardAndNotAtLowestZoom() {
        self.viewModel.zoomFactor = 0.5
        self.viewModel.zoomOut()
        XCTAssertEqual(self.viewModel.zoomFactor, 0.25, accuracy: 0.001)
    }

    func test_zoomOut_decreasesZoomLevelIfCustomAndNotAtLowestZoom() {
        self.viewModel.zoomFactor = 0.56
        self.viewModel.zoomOut()
        XCTAssertEqual(self.viewModel.zoomFactor, 0.5, accuracy: 0.001)
    }

    func test_zoomTo100_setsZoomFactorTo1() {
        self.viewModel.zoomFactor = 0.5
        self.viewModel.zoomTo100()
        XCTAssertEqual(self.viewModel.zoomFactor, 1, accuracy: 0.001)
    }


    //MARK: - Helpers
    class TestCanvasEditorView: CanvasEditorView {
        var updateZoomFactorCalled = false
        func updateZoomFactor() {
            self.updateZoomFactorCalled = true
        }
    }
}
