//
//  CanvasPageInspectorViewModelTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 21/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class CanvasPageInspectorViewModelTests: XCTestCase {

    //MARK: - .width
    func test_width_returnsCanvasPageFrameWidth() throws {
        let canvasPage = CanvasPage()
        canvasPage.frame = CGRect(x: 19, y: 31, width: 218, height: 921)
        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: BubblesModelController(undoManager: UndoManager()))

        XCTAssertEqual(viewModel.width, 218)
    }

    func test_width_setsCanvasPageFrameWidthToSuppliedValueIfGreaterThanMinimumWidth() throws {
        let canvasPage = CanvasPage()
        canvasPage.frame = CGRect(x: 19, y: 31, width: 218, height: 921)
        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: BubblesModelController(undoManager: UndoManager()))

        viewModel.width = Int(GlobalConstants.minimumPageSize.width + 1)
        XCTAssertEqual(canvasPage.frame.width, GlobalConstants.minimumPageSize.width + 1)
    }

    func test_width_setsCanvasPageFrameWidthToSuppliedValueIfEqualToMinimumWidth() throws {
        let canvasPage = CanvasPage()
        canvasPage.frame = CGRect(x: 19, y: 31, width: 218, height: 921)
        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: BubblesModelController(undoManager: UndoManager()))

        viewModel.width = Int(GlobalConstants.minimumPageSize.width)
        XCTAssertEqual(canvasPage.frame.width, GlobalConstants.minimumPageSize.width)
    }

    func test_width_setsCanvasPageFrameWidthToSuppliedValueIfLessThanMinimumWidth() throws {
        let canvasPage = CanvasPage()
        canvasPage.frame = CGRect(x: 19, y: 31, width: 218, height: 921)
        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: BubblesModelController(undoManager: UndoManager()))

        viewModel.width = Int(GlobalConstants.minimumPageSize.width - 1)
        XCTAssertEqual(canvasPage.frame.width, GlobalConstants.minimumPageSize.width)
    }


    //MARK: - .height
    func test_height_returnsCanvasPageFrameHeight() throws {
        let canvasPage = CanvasPage()
        canvasPage.frame = CGRect(x: 19, y: 31, width: 218, height: 921)
        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: BubblesModelController(undoManager: UndoManager()))

        XCTAssertEqual(viewModel.height, 921)
    }

    func test_height_setsCanvasPageFrameHeightToSuppliedValueIfGreaterThanMinimumHeight() throws {
        let canvasPage = CanvasPage()
        canvasPage.frame = CGRect(x: 19, y: 31, width: 200, height: 218)
        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: BubblesModelController(undoManager: UndoManager()))

        viewModel.height = Int(GlobalConstants.minimumPageSize.height + 1)
        XCTAssertEqual(canvasPage.frame.height, GlobalConstants.minimumPageSize.height + 1)
    }

    func test_height_setsCanvasPageFrameHeightToSuppliedValueIfEqualToMinimumHeight() throws {
        let canvasPage = CanvasPage()
        canvasPage.frame = CGRect(x: 19, y: 31, width: 200, height: 218)
        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: BubblesModelController(undoManager: UndoManager()))

        viewModel.height = Int(GlobalConstants.minimumPageSize.height)
        XCTAssertEqual(canvasPage.frame.height, GlobalConstants.minimumPageSize.height)
    }

    func test_height_setsCanvasPageFrameHeightToSuppliedValueIfLessThanMinimumHeight() throws {
        let canvasPage = CanvasPage()
        canvasPage.frame = CGRect(x: 19, y: 31, width: 200, height: 218)
        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: BubblesModelController(undoManager: UndoManager()))

        viewModel.height = Int(GlobalConstants.minimumPageSize.height - 1)
        XCTAssertEqual(canvasPage.frame.height, GlobalConstants.minimumPageSize.height)
    }

}
