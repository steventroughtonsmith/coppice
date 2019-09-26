//
//  CanvasEditorViewModelTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 26/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest

class CanvasEditorViewModelTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    //MARK: - close(_:)
    func test_closeCanvasPage_removesPageFromCanvas() {
        XCTFail()
    }

    func test_closeCanvasPage_deleteCanvas() {
        XCTFail()
    }


    //MARK: - Page Updating
    func test_updatingPages_returnsAllCanvasPagesInCanvasAfterInitialisation() {
        XCTFail()
    }

    func test_updatingPages_allPagesAreAddedToLayoutEngineAfterInitialisation() {
        XCTFail()
    }

    func test_updatingPages_addingPagesToCanvasUpdatesCanvasPages() {
        XCTFail()
    }

    func test_updatingPages_addingPagesToCanvasAddsThosePagesToLayoutEngine() {
        XCTFail()
    }

    func test_updatingPages_removingPagesFromCanvasUpdatesCanvasPages() {
        XCTFail()
    }

    func test_updatingPages_removingPagesFromCanvasRemovesThosePagesFromLayoutEngine() {
        XCTFail()
    }


    //MARK: - canvasPage(with:)
    func test_canvasPageWithUUID_returnsCanvasPageWhosIDMatchesUUID() {
        XCTFail()
    }

    func test_canvasPageWithUUID_returnsNilIfNoCanvasPageMatchesUUID() {
        XCTFail()
    }


    //MARK: .zoomFactor
    func test_zoomFactor_capsZoomFactorToMaximumOf1() {
        XCTFail()
    }

    func test_zoomFactor_capsZoomFactorToMinimumOfPoint25() {
        XCTFail()
    }

    func test_zoomFactor_tellsViewToUpdateWhenSetToValueInsideBounds() {
        XCTFail()
    }

    func test_zoomFactor_tellsViewToUpdateWhenSetToValueAboveMax() {
        XCTFail()
    }

    func test_zoomFactor_tellsViewToUpdateWhenSetToValueBelowMinimum() {
        XCTFail()
    }


    //MARK: - .zoomLevels
    func test_zoomLevels_returnsJustStepsBetween25And100IfZoomFactorIs1() {
        XCTFail()
    }

    func test_zoomLevels_returnsJustStepsBetween25And100IfZoomFactorIsPoint75() {
        XCTFail()
    }

    func test_zoomLevels_returnsJustStepsBetween25And100IfZoomFactorIsPoint5() {
        XCTFail()
    }

    func test_zoomLevels_returnsJustStepsBetween25And100IfZoomFactorIsPoint25() {
        XCTFail()
    }

    func test_zoomLevels_includesAdditionalStepBefore25IfZoomFactorIsBelowPoint25() {
        XCTFail()
    }

    func test_zoomLevels_includesAdditionalStepBefore50IfZoomFactorIsBetweenPoint25AndPoint5() {
        XCTFail()
    }

    func test_zoomLevels_includesAdditionalStepBefore75IfZoomFactorIsBetweenPoint5AndPoint75() {
        XCTFail()
    }

    func test_zoomLevels_includesAdditionalStepBefore100IfZoomFactorIsBetweenPoint75And1() {
        XCTFail()
    }


    //MARK: .selectedZoomLevel
    func test_selectedZoomLevel_returnsIndexOfZoomIndexMatchingLevelForStandardLevel() {
        XCTFail()
    }

    func test_selectedZoomLevel_returnsIndexOfZoomIndexMatchingLevelForCustomLevel() {
        XCTFail()
    }

    func test_selectedZoomLevel_settingSelectedZoomLevelSetsZoomFactorTo100thOfMatchingZoomLevel() {
        XCTFail()
    }

    func test_selectedZoomLevel_settingSelectedZoomLevelToBelow0SetsTo0() {
        XCTFail()
    }

    func test_selectedZoomLevel_settingSelectedZoomLevelToAboveNumberOfZoomLevelsSetsToLastZoomLevelIndex() {
        XCTFail()
    }


    //MARK: .zoomIn/Out/To100
    func test_zoomIn_increasesZoomLevelIfStandardAndNotAtHighestZoom() {
        XCTFail()
    }

    func test_zoomIn_increasesZoomLevelIfCustomAndNotAtHighestZoom() {
        XCTFail()
    }

    func test_zoomOut_decreasesZoomLevelIfStandardAndNotAtLowestZoom() {
        XCTFail()
    }

    func test_zoomOut_decreasesZoomLevelIfCustomAndNotAtLowestZoom() {
        XCTFail()
    }

    func test_zoomTo100_setsZoomFactorTo1() {
        XCTFail()
    }

    func test_zoomIn_decreasesZoomLevelIfCustomAndNotAtHighestZoom() {
        XCTFail()
    }

}
