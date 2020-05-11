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

    func test_width_setsCanvasPageFrameWidthToMinimumPageWidthIfLessThanMinimumWidth() throws {
        let canvasPage = CanvasPage()
        canvasPage.frame = CGRect(x: 19, y: 31, width: 218, height: 921)
        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: BubblesModelController(undoManager: UndoManager()))

        viewModel.width = Int(GlobalConstants.minimumPageSize.width - 1)
        XCTAssertEqual(canvasPage.frame.width, GlobalConstants.minimumPageSize.width)
    }

    func test_width_alsoSetsHeightIfPageContentShouldMaintainAspectRatio() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.createPage(ofType: .image, in: modelController.rootFolder)
        let canvasPage = modelController.canvasPageCollection.newObject() {
            $0.page = page
            $0.frame = CGRect(x: 10, y: 20, width: 500, height: 333)
        }

        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: modelController)
        viewModel.width = 1000
        XCTAssertEqual(canvasPage.frame.size, CGSize(width: 1000, height: 666))
    }

    func test_width_usesInitialAspectRatioWhenDeterminingThePageSizeNotModifiedRatio() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.createPage(ofType: .image, in: modelController.rootFolder)
        let canvasPage = modelController.canvasPageCollection.newObject() {
            $0.page = page
            $0.frame = CGRect(x: 10, y: 20, width: 500, height: 333)
        }

        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: modelController)
        viewModel.width = 250
        XCTAssertEqual(canvasPage.frame.size, CGSize(width: 250, height: 166.5))
        viewModel.width = 1000
        XCTAssertEqual(canvasPage.frame.size, CGSize(width: 1000, height: 666))
    }

    func test_width_doesntAllowCanvasFrameHeightToGoBelowMinimumPageSizeWhenMaintainingAspectRatioEvenIfWidthIsAboveMinimumWidth() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.createPage(ofType: .image, in: modelController.rootFolder)
        let canvasPage = modelController.canvasPageCollection.newObject() {
            $0.page = page
            $0.frame = CGRect(x: 10, y: 20, width: 600, height: 200)
        }

        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: modelController)
        viewModel.width = 200
        XCTAssertEqual(canvasPage.frame.size, CGSize(width: 300, height: 100))
    }

    func test_width_doesntAllowCanvasFrameHeightToGoBelowMinimumPageSizeWhenMaintainingAspectRatioWhenWidthIsBelowMinimumWidth() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.createPage(ofType: .image, in: modelController.rootFolder)
        let canvasPage = modelController.canvasPageCollection.newObject() {
            $0.page = page
            $0.frame = CGRect(x: 10, y: 20, width: 600, height: 200)
        }

        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: modelController)
        viewModel.width = 100
        XCTAssertEqual(canvasPage.frame.size, CGSize(width: 300, height: 100))
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

    func test_height_alsoSetsWidthIfPageContentShouldMaintainAspectRatio() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.createPage(ofType: .image, in: modelController.rootFolder)
        let canvasPage = modelController.canvasPageCollection.newObject() {
            $0.page = page
            $0.frame = CGRect(x: 10, y: 20, width: 333, height: 500)
        }

        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: modelController)
        viewModel.height = 1000
        XCTAssertEqual(canvasPage.frame.size, CGSize(width: 666, height: 1000))
    }

    func test_height_usesInitialAspectRatioWhenDeterminingThePageSizeNotModifiedRatio() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.createPage(ofType: .image, in: modelController.rootFolder)
        let canvasPage = modelController.canvasPageCollection.newObject() {
            $0.page = page
            $0.frame = CGRect(x: 10, y: 20, width: 333, height: 500)
        }

        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: modelController)
        viewModel.height = 250
        XCTAssertEqual(canvasPage.frame.size, CGSize(width: 166.5, height: 250))
        viewModel.height = 1000
        XCTAssertEqual(canvasPage.frame.size, CGSize(width: 666, height: 1000))
    }

    func test_height_doesntAllowCanvasFrameWidthToGoBelowMinimumPageSizeWhenMaintainingAspectRatioEvenIfHeightIsAboveMinimumHeight() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.createPage(ofType: .image, in: modelController.rootFolder)
        let canvasPage = modelController.canvasPageCollection.newObject() {
            $0.page = page
            $0.frame = CGRect(x: 10, y: 20, width: 200, height: 400)
        }

        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: modelController)
        viewModel.height = 200
        XCTAssertEqual(canvasPage.frame.size, CGSize(width: 150, height: 300))
    }

    func test_height_doesntAllowCanvasFrameWidthToGoBelowMinimumPageSizeWhenMaintainingAspectRatioWhenHeightIsBelowMinimumHeight() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.createPage(ofType: .image, in: modelController.rootFolder)
        let canvasPage = modelController.canvasPageCollection.newObject() {
            $0.page = page
            $0.frame = CGRect(x: 10, y: 20, width: 200, height: 400)
        }

        let viewModel = CanvasPageInspectorViewModel(canvasPage: canvasPage, modelController: modelController)
        viewModel.height = 90
        XCTAssertEqual(canvasPage.frame.size, CGSize(width: 150, height: 300))
    }

}
