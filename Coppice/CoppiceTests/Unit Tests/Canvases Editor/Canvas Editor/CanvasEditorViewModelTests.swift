//
//  CanvasEditorViewModelTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 26/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class CanvasEditorViewModelTests: XCTestCase {
    var modelController: MockCoppiceModelController!
    var canvas: Canvas!
    var canvasPage1: CanvasPage!
    var canvasPage2: CanvasPage!

    var viewModel: CanvasEditorViewModel!
    var documentViewModel: MockDocumentWindowViewModel!

    override func setUp() {
        super.setUp()

        self.modelController = MockCoppiceModelController(undoManager: UndoManager())
        self.canvas = self.modelController.collection(for: Canvas.self).newObject()

        let canvasPageCollection = self.modelController.collection(for: CanvasPage.self)
        self.canvasPage1 = canvasPageCollection.newObject() { $0.canvas = self.canvas }
        self.canvasPage2 = canvasPageCollection.newObject() { $0.canvas = self.canvas }

        self.documentViewModel = MockDocumentWindowViewModel(modelController: self.modelController)
        self.viewModel = CanvasEditorViewModel(canvas: self.canvas, documentWindowViewModel: self.documentViewModel)
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

    func test_closeCanvasPage_removesChildPagesFromCanvas() {
        let canvasPageCollection = self.modelController.collection(for: CanvasPage.self)
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage1
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage1
        }

        self.viewModel.close(self.canvasPage1)
        XCTAssertNil(child1.canvas)
        XCTAssertFalse(self.canvas.pages.contains(child1))
        XCTAssertNil(child2.canvas)
        XCTAssertFalse(self.canvas.pages.contains(child2))
    }

    func test_closeCanvasPage_deletesChildCanvasPages() {
        let canvasPageCollection = self.modelController.collection(for: CanvasPage.self)
        let child1 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage1
        }
        let child2 = canvasPageCollection.newObject() {
            $0.canvas = self.canvas
            $0.parent = self.canvasPage1
        }

        self.viewModel.close(self.canvasPage1)
        XCTAssertNil(canvasPageCollection.objectWithID(child1.id))
        XCTAssertNil(canvasPageCollection.objectWithID(child2.id))
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


    //MARK: - addPage(at:centredOn:)
    func test_addPageAtLink_tellsModelControllerToOpenPageOnCanvas() throws {
        let pageLink = PageLink(destination: Page.modelID(with: UUID()))
        self.viewModel.addPage(at: pageLink)

        let (link, canvas) = try XCTUnwrap(self.modelController.openPageMock.arguments.first)
        XCTAssertEqual(link, pageLink)
        XCTAssertEqual(canvas, self.canvas)
    }

    func test_addPageAtLink_flashesAllCanvasPagesOpened() throws {
        let view = TestCanvasEditorView()
        self.viewModel.view = view
        let pageLink = PageLink(destination: Page.modelID(with: UUID()))
        let canvasPage1 = CanvasPage()
        let canvasPage2 = CanvasPage()

        self.modelController.openPageMock.returnValue = [canvasPage1, canvasPage2]

        self.viewModel.addPage(at: pageLink)

        XCTAssertEqual(view.flashedPages.count, 2)
        XCTAssertEqual(view.flashedPages[safe: 0], canvasPage1)
        XCTAssertEqual(view.flashedPages[safe: 1], canvasPage2)
    }


    //MARK: - addPages(with:centredOn:)
    func test_addPagesWithIDsCenteredOnPoint_addsPagesToCanvasAtSuppliedPoint() throws {
        let page1 = self.modelController.collection(for: Page.self).newObject()
        let page2 = self.modelController.collection(for: Page.self).newObject()

        self.viewModel.addPages(with: [page1.id, page2.id], centredOn: CGPoint(x: 30, y: 50))

        let pages = self.canvas.pages.compactMap(\.page)
        XCTAssertTrue(pages.contains(page1))
        XCTAssertTrue(pages.contains(page2))
        XCTAssertEqual(page1.canvases.first?.frame.midPoint, CGPoint(x: 30, y: 50))
    }

    //MARK: - addPages(forFilesAtURLs:centredOn:)
    func test_addPagesForFilesAtURLsCentredOnPoint_tellsModelControllerToCreatesPagesFromURLsAndAddsToCanvas() throws {
        let textURL = try XCTUnwrap(self.testBundle.url(forResource: "test-rtf", withExtension: "rtf"))
        let imageURL = try XCTUnwrap(self.testBundle.url(forResource: "test-image", withExtension: "png"))

        let initialPageCount = self.canvas.pages.count

        self.viewModel.addPages(forFilesAtURLs: [textURL, imageURL], centredOn: CGPoint(x: 30, y: 50))

        let (urls, _, _, _) = try XCTUnwrap(self.modelController.createPagesFromFilesMock.arguments.first)
        XCTAssertEqual(urls, [textURL, imageURL])
        XCTAssertEqual(self.canvas.pages.count, initialPageCount + 2)
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

    //MARK: .canZoomIn/Out/To100
    func test_canZoomIn_returnsTrueIfSelectedZoomLevelIs0() throws {
        self.viewModel.selectedZoomLevel = 0
        XCTAssertTrue(self.viewModel.canZoomIn)
    }

    func test_canZoomIn_returnsTrueIfSelectedZoomLevelIsPenultimateLevel() throws {
        self.viewModel.selectedZoomLevel = self.viewModel.zoomLevels.count - 2
        XCTAssertTrue(self.viewModel.canZoomIn)
    }

    func test_canZoomIn_returnsFalseIfSelectedZoomLevelIsLastLevel() throws {
        self.viewModel.selectedZoomLevel = self.viewModel.zoomLevels.count - 1
        XCTAssertFalse(self.viewModel.canZoomIn)
    }

    func test_canZoomOut_returnsTrueIfSelectedZoomLevelIsLastLevel() throws {
        self.viewModel.selectedZoomLevel = self.viewModel.zoomLevels.count - 1
        XCTAssertTrue(self.viewModel.canZoomOut)
    }

    func test_canZoomOut_returnsTrueIfSelectedZoomLevelIs1() throws {
        self.viewModel.selectedZoomLevel = 1
        XCTAssertTrue(self.viewModel.canZoomOut)
    }

    func test_canZoomOut_returnsFalseIfSelectedZoomLevelIs0() throws {
        self.viewModel.selectedZoomLevel = 0
        XCTAssertFalse(self.viewModel.canZoomOut)
    }

    func test_canZoomTo100_returnsFalseIfZoomFactorIs1() throws {
        self.viewModel.zoomFactor = 1
        XCTAssertFalse(self.viewModel.canZoomTo100)
    }

    func test_canZoomTo100_returnsTrueIfZoomFactorIsLessThan1() throws {
        self.viewModel.zoomFactor = 0.9
        XCTAssertTrue(self.viewModel.canZoomTo100)
    }


    //MARK: - Observation/Undo
    func test_updatesPagesIfCanvasPageAddedToCanvas() {
        XCTAssertEqual(self.viewModel.canvasPages.count, 2)
        CanvasPage.create(in: self.modelController) { $0.canvas = self.canvas }

        XCTAssertEqual(self.viewModel.canvasPages.count, 3)
    }

    func test_updatesPagesIfCanvasPageRemovedFromCanvas() {
        XCTAssertEqual(self.viewModel.canvasPages.count, 2)
        self.canvasPage1.canvas = nil

        XCTAssertEqual(self.viewModel.canvasPages.count, 1)
    }



    //MARK: - CanvasLayoutEngineDelegate

    //MARK: - remove(pages:from:)
    func test_removePagesFromLayout_closesSuppliedPages() throws {
        let page = LayoutEnginePage(id: self.canvasPage1.id.uuid, contentFrame: .zero)
        self.viewModel.remove(pages: [page], from: self.viewModel.layoutEngine)

        XCTAssertNil(self.canvasPage1.canvas)
        XCTAssertFalse(self.canvas.pages.contains(self.canvasPage1))
    }

    func test_removePagesFromLayout_doesntTouchOtherPageHierarchies() throws {
        let page = LayoutEnginePage(id: self.canvasPage1.id.uuid, contentFrame: .zero)
        self.viewModel.remove(pages: [page], from: self.viewModel.layoutEngine)

        XCTAssertEqual(self.canvasPage2.canvas, self.canvas)
        XCTAssertTrue(self.canvas.pages.contains(self.canvasPage2))
    }


    //MARK: - moved(pages:in:)
    func test_movedPagesInLayout_updatesFramesofAllSuppliedPages() throws {
        let page1 = LayoutEnginePage(id: self.canvasPage1.id.uuid, contentFrame: CGRect(x: 19, y: 20, width: 200, height: 200))
        let page2 = LayoutEnginePage(id: self.canvasPage2.id.uuid, contentFrame: CGRect(x: -60, y: 40, width: 960, height: 400))
        self.viewModel.moved(pages: [page1, page2], in: self.viewModel.layoutEngine)

        XCTAssertEqual(self.canvasPage1.frame, CGRect(x: 19, y: 20, width: 200, height: 200))
        XCTAssertEqual(self.canvasPage2.frame, CGRect(x: -60, y: 40, width: 960, height: 400))
    }

    func test_movedPagesInLayout_doesntUpdateFramesOfOtherPages() throws {
        let expectedFrame = self.canvasPage2.frame
        let page1 = LayoutEnginePage(id: self.canvasPage1.id.uuid, contentFrame: CGRect(x: 19, y: 20, width: 200, height: 200))
        self.viewModel.moved(pages: [page1], in: self.viewModel.layoutEngine)

        XCTAssertEqual(self.canvasPage2.frame, expectedFrame)
    }


    //MARK: - Helpers
    class TestCanvasEditorView: CanvasEditorView {
        var flashedPages = [CanvasPage]()
        func flash(_ canvasPage: CanvasPage) {
            self.flashedPages.append(canvasPage)
        }

        var updateZoomFactorCalled = false
        func updateZoomFactor() {
            self.updateZoomFactorCalled = true
        }
    }
}
