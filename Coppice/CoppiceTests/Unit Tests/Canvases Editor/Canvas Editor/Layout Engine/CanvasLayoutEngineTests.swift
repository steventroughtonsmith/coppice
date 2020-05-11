//
//  CanvasLayoutEngineTests.swift
//  Canvas FinalTests
//
//  Created by Martin Pilkington on 31/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice
import Carbon.HIToolbox

let testLayoutASCII = """
          |
          |       ____
     ___  |      | 3  |
    | 2 | |      |____|
    |   | |
----|---|-|------------
    |   | |
    |___| |
          |
          |         _
          |        |1|
          |
"""

class CanvasLayoutEngineTests: XCTestCase {

    var layoutEngine: CanvasLayoutEngine!
    var page1: LayoutEnginePage!
    var page2: LayoutEnginePage!
    var page3: LayoutEnginePage!
    var contentFrame: CGRect = .zero
    var expectedOffset: CGPoint!

    let contentBorder: CGFloat = 20

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        self.layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 5,
                                                                                borderSize: 0,
                                                                                shadowOffset: .zero,
                                                                                edgeResizeHandleSize: 1,
                                                                                cornerResizeHandleSize: 1),
                                                                    contentBorder: self.contentBorder,
                                                                    arrow: .standard))

        self.page1 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 40, y: 40, width: 10, height: 10),
                                      minimumContentSize: CGSize(width: 0, height: 0))

        self.page2 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: -30, y: -20, width: 20, height: 40),
                                      minimumContentSize: CGSize(width: 0, height: 0))

        self.page3 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 30, y: -30, width: 30, height: 20),
                                      minimumContentSize: CGSize(width: 0, height: 0))
        self.layoutEngine.add([self.page1, self.page2, self.page3])

        self.contentFrame = self.page1.layoutFrame.union(self.page2.layoutFrame).union(self.page3.layoutFrame)
        self.expectedOffset = CGPoint(x: 50, y: 55) //This is (50, 50) for the content frame, but we have a 5pt title which pushes the y up a bit
    }

    override func tearDown() {
        self.layoutEngine = nil
        self.page1 = nil
        self.page2 = nil
        self.page3 = nil
        self.contentFrame = .zero
    }

    //MARK: - Adding/Removing Pages
    func test_addPage_addsPageWithSuppliedValuesToPagesArray() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 1, width: 2, height: 3),
                                    minimumContentSize: CGSize(width: 4, height: 5))
        self.layoutEngine.add([page])
        XCTAssertTrue(self.layoutEngine.pages.contains(page))
    }

    func test_addPage_setsLayoutEngineOfSuppliedPages() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 1, width: 2, height: 3),
                                    minimumContentSize: CGSize(width: 4, height: 5))
        self.layoutEngine.add([page])
        XCTAssertTrue(page.layoutEngine === self.layoutEngine)
    }

    func test_removePages_removesSuppliedPagesFromPagesArray() {
        XCTAssertTrue(self.layoutEngine.pages.contains(self.page1))
        XCTAssertTrue(self.layoutEngine.pages.contains(self.page3))

        self.layoutEngine.remove([self.page1, self.page3])

        XCTAssertFalse(self.layoutEngine.pages.contains(self.page1))
        XCTAssertTrue(self.layoutEngine.pages.contains(self.page2))
        XCTAssertFalse(self.layoutEngine.pages.contains(self.page3))
    }


    //MARK: - Updating Pages
    func test_updateFrame_updatesTheFrameOfPageWithSuppliedUUID() {
        let expectedContentFrame = CGRect(x: 35, y: 35, width: 20, height: 20)
        self.layoutEngine.updateContentFrame(expectedContentFrame, ofPageWithID: self.page1.id)
        XCTAssertEqual(self.page1.contentFrame, expectedContentFrame)
    }

    func test_updateFrame_updatesCanvasSizeIfNewFrameChangesSize() {
        let expectedCanvasSize = self.layoutEngine.canvasSize.plus(CGSize(width: 10, height: 10))
        self.layoutEngine.updateContentFrame(CGRect(x: 30, y: -40, width: 40, height: 20), ofPageWithID: self.page3.id)
        XCTAssertEqual(self.layoutEngine.canvasSize, expectedCanvasSize)
    }

    func test_updateFrame_notifiesViewOfLayoutChange() {
        let view = TestCanvasView()
        view.viewPortFrame = CGRect(x: 50, y: 50, width: 10, height: 10)
        self.layoutEngine.view = view
        self.layoutEngine.updateContentFrame(CGRect(x: -20, y: -10, width: 20, height: 40), ofPageWithID: self.page2.id)

        let expectedContext = CanvasLayoutEngine.LayoutContext(sizeChanged: true, pageOffsetChange: CGPoint(x: -10, y: 0))
        XCTAssertEqual(view.context, expectedContext)
    }

    func test_updateFrame_doesntUpdateLayoutIfFrameHasNotChanged() {
        let view = TestCanvasView()
        view.viewPortFrame = CGRect(x: 50, y: 50, width: 10, height: 10)
        self.layoutEngine.view = view
        self.layoutEngine.updateContentFrame(CGRect(x: -30, y: -20, width: 20, height: 40), ofPageWithID: self.page2.id)

        XCTAssertNil(view.context)
    }


    //MARK: - Point Conversion
    func test_pointConversion_convertsPointFromPageSpaceToCanvasSpaceForEmptyEngine() {
        let basePoint = CGPoint(x: 10, y: 42)

        let emptyEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 5,
                                                                              borderSize: 0,
                                                                              shadowOffset: .zero,
                                                                              edgeResizeHandleSize: 1,
                                                                              cornerResizeHandleSize: 1),
                                                                  contentBorder: 20,
                                                                  arrow: .standard))

        let expectedPoint = basePoint
        XCTAssertEqual(emptyEngine.convertPointToCanvasSpace(basePoint), expectedPoint)
    }

    func test_pointConversion_convertsPointFromPageSpaceToCanvasSpace() {
        let basePoint = CGPoint(x: 10, y: 42)

        let expectedPoint = basePoint.plus(self.expectedOffset)
        XCTAssertEqual(self.layoutEngine.convertPointToCanvasSpace(basePoint), expectedPoint)
    }

    func test_pointConversion_convertsPointFromCanvasSpaceToPageSpaceForEmptyEngine() {
        let basePoint = CGPoint(x: 15, y: 31)

        let emptyEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 5,
                                                                              borderSize: 0,
                                                                              shadowOffset: .zero,
                                                                              edgeResizeHandleSize: 1,
                                                                              cornerResizeHandleSize: 1),
                                                                  contentBorder: 20,
                                                                  arrow: .standard))
        let expectedPoint = basePoint
        XCTAssertEqual(emptyEngine.convertPointToPageSpace(basePoint), expectedPoint)
    }

    func test_pointConversion_convertsPointFromCanvasSpaceToPageSpace() {
        let basePoint = CGPoint(x: 65, y: 81)

        let expectedPoint = basePoint.minus(self.expectedOffset)
        XCTAssertEqual(self.layoutEngine.convertPointToPageSpace(basePoint), expectedPoint)
    }


    //MARK: - selectAll()
    func test_selectAll_selectsAllPagesIfNoneWereSelected() {
        self.layoutEngine.selectAll()
        XCTAssertTrue(self.page1.selected)
        XCTAssertTrue(self.page2.selected)
        XCTAssertTrue(self.page3.selected)
    }

    func test_selectAll_selectsAllPagesEvenIfSomeWereAlreadySelected() {
        self.page2.selected = true
        self.layoutEngine.selectAll()
        XCTAssertTrue(self.page1.selected)
        XCTAssertTrue(self.page2.selected)
        XCTAssertTrue(self.page3.selected)
    }

    func test_selectAll_doesntChangeSelectionIfAllWereAlreadySelected() {
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.selectAll()
        XCTAssertTrue(self.page1.selected)
        XCTAssertTrue(self.page2.selected)
        XCTAssertTrue(self.page3.selected)
    }

    func test_selectAll_updatesTheEnabledPage() {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        let clickPoint = self.page3.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint)
        self.layoutEngine.upEvent(at: clickPoint)
        XCTAssertTrue(self.layoutEngine.enabledPage === self.page3)

        self.layoutEngine.selectAll()

        XCTAssertNil(self.layoutEngine.enabledPage)

    }

    func test_selectAll_informsViewOfLayoutChange() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.selectAll()

        let context = try XCTUnwrap(view.context)
        XCTAssertTrue(context.selectionChanged)
    }


    //MARK: - deselectAll()
    func test_deselectAll_deselectsAllPagesIfAllWereSelected() {
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.deselectAll()
        XCTAssertFalse(self.page1.selected)
        XCTAssertFalse(self.page2.selected)
        XCTAssertFalse(self.page3.selected)
    }

    func test_deselectAll_deselectsAllPagesIfSomeWereSelected() {
        self.page1.selected = true
        self.page3.selected = true
        self.layoutEngine.deselectAll()
        XCTAssertFalse(self.page1.selected)
        XCTAssertFalse(self.page2.selected)
        XCTAssertFalse(self.page3.selected)
    }

    func test_deselectAll_doesntChangeSelectionIfNoneWereAlreadySelected() {
        self.layoutEngine.deselectAll()
        XCTAssertFalse(self.page1.selected)
        XCTAssertFalse(self.page2.selected)
        XCTAssertFalse(self.page3.selected)
    }

    func test_deselectAll_updatesTheEnabledPage() {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        let clickPoint = self.page3.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint)
        self.layoutEngine.upEvent(at: clickPoint)
        XCTAssertTrue(self.layoutEngine.enabledPage === self.page3)

        self.layoutEngine.deselectAll()

        XCTAssertNil(self.layoutEngine.enabledPage)
    }

    func test_deselectAll_informsViewOfLayoutChange() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.deselectAll()

        let context = try XCTUnwrap(view.context)
        XCTAssertTrue(context.selectionChanged)
    }


    //MARK: - Click Selection
    func test_selection_selectedPagesReturnsAllPagesWithSelectedTrue() throws {
        self.page1.selected = true
        self.page2.selected = true

        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 0]) === self.page1)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 1]) === self.page2)
    }

    func test_selection_mouseUpOnCanvasDeselectsAllPagesIfMouseNotMoved() {
        self.page1.selected = true
        self.page2.selected = true

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)
        self.layoutEngine.downEvent(at: CGPoint(x: 50, y: 50))
        self.layoutEngine.upEvent(at: CGPoint(x: 50, y: 50))
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)
    }

    func test_selection_mouseDownWithNoModifiersOnPageTitleSelectsThatPage() throws {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        let clickPoint = self.page3.layoutFrame.origin.plus(.identity)
        self.layoutEngine.downEvent(at: clickPoint)

        XCTAssertTrue(self.layoutEngine.selectedPages.first === self.page3)
    }

    func test_selection_mouseDownWithNoModifiersOnPageContentSelectsThatPage() throws {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        let clickPoint = self.page3.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint)

        XCTAssertTrue(self.layoutEngine.selectedPages.first === self.page3)
    }

    func test_selection_mouseDownWithNoModifiersOnUnselectedPageTitleDeselectsCurrentSelectionAndSelectsThatPage() throws {
        self.page1.selected = true
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 1)

        let clickPoint = self.page3.layoutFrame.origin.plus(.identity)
        self.layoutEngine.downEvent(at: clickPoint)
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 1)
        XCTAssertTrue(self.layoutEngine.selectedPages.first === self.page3)
    }

    func test_selection_mouseDownWithNoModifiersOnUnselectedPageContentDeselectsCurrentSelectionAndSelectsThatPage() {
        self.page1.selected = true
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 1)

        let clickPoint = self.page3.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint)
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 1)
        XCTAssertTrue(self.layoutEngine.selectedPages.first === self.page3)
    }

    func test_selection_mouseDownWithNoModifiersOnPageTitleInCurrentSelectionDoesntChangeSelection() throws {
        self.page1.selected = true
        self.page3.selected = true
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)

        let clickPoint = self.page3.layoutFrame.origin.plus(.identity)
        self.layoutEngine.downEvent(at: clickPoint)

        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertEqual(selectedPages.count, 2)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 0]) === self.page1)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 1]) === self.page3)
    }

    func test_selection_mouseDownWithNoModifiersOnPageContentInCurrentSelectionDoesntChangeSelection() throws {
        self.page1.selected = true
        self.page3.selected = true
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)

        let clickPoint = self.page3.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint)

        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertEqual(selectedPages.count, 2)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 0]) === self.page1)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 1]) === self.page3)
    }

    func test_selection_mouseDownWithShiftModifierOnPageTitleAddsThatPageToSelectionIfNotAlreadySelected() throws {
        self.page3.selected = true

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 1)
        self.layoutEngine.downEvent(at: self.page1.layoutFrame.origin.plus(.identity), modifiers: .shift)
        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(selectedPages.contains(self.page1))
        XCTAssertTrue(selectedPages.contains(self.page3))
    }

    func test_selection_mouseDownWithShiftModifierOnPageContentAddsThatPageToSelectionIfNotAlreadySelected() throws {
        self.page3.selected = true

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 1)
        self.layoutEngine.downEvent(at: self.page1.layoutFrame.midPoint, modifiers: .shift)
        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(selectedPages.contains(self.page1))
        XCTAssertTrue(selectedPages.contains(self.page3))
    }

    func test_selection_mouseDownWithShiftModifierOnPageTitleRemovesThatPageFromSelectionIfAlreadySelected() {
        self.page2.selected = true
        self.page3.selected = true

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)
        self.layoutEngine.downEvent(at: self.page2.layoutFrame.origin.plus(.identity), modifiers: .shift)
        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertEqual(selectedPages.count, 1)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 0]) === self.page3)
    }

    func test_selection_mouseDownWithShiftModifierOnPageContentRemovesThatPageFromSelectionIfAlreadySelected() {
        self.page2.selected = true
        self.page3.selected = true

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)
        self.layoutEngine.downEvent(at: self.page2.layoutFrame.midPoint, modifiers: .shift)
        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertEqual(selectedPages.count, 1)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 0]) === self.page3)
    }

    func test_selection_informsViewOfSelectionChangeAfterUpEvent() throws {

        let testCanvas = TestCanvasView()
        self.layoutEngine.view = testCanvas

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)
        self.layoutEngine.downEvent(at: self.page1.layoutFrame.origin.plus(.identity))
        XCTAssertFalse(try XCTUnwrap(testCanvas.context?.selectionChanged))
        self.layoutEngine.draggedEvent(at: self.page1.layoutFrame.origin.plus(.identity))
        XCTAssertFalse(try XCTUnwrap(testCanvas.context?.selectionChanged))
        self.layoutEngine.upEvent(at: self.page1.layoutFrame.origin.plus(.identity))
        XCTAssertTrue(try XCTUnwrap(testCanvas.context?.selectionChanged))
    }


    //MARK: - Selection Rect
    func test_selectionRect_clickingAndDraggingOnCanvasCreatesASelectionRect() throws {
        XCTAssertNil(self.layoutEngine.selectionRect)

        self.layoutEngine.downEvent(at: CGPoint(x: 50, y: 50))
        self.layoutEngine.draggedEvent(at: CGPoint(x: 53, y: 53))
        let rect = try XCTUnwrap(self.layoutEngine.selectionRect)
        XCTAssertEqual(rect, CGRect(x: 50, y: 50, width: 3, height: 3))
    }

    func test_selectionRect_drawingSelectionRectOverPagesSelectsThosePages() throws {
        XCTAssertNil(self.layoutEngine.selectionRect)

        self.layoutEngine.downEvent(at: CGPoint(x: 10, y: 10))
        self.layoutEngine.draggedEvent(at: CGPoint(x: 85, y: 35))

        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 0]) === self.page2)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 1]) === self.page3)
    }

    func test_selectionRect_draggingSelectionRectBackOffPageDeselectsThatPage() {
        XCTAssertNil(self.layoutEngine.selectionRect)

        self.layoutEngine.downEvent(at: CGPoint(x: 10, y: 10))
        self.layoutEngine.draggedEvent(at: CGPoint(x: 85, y: 35))

        let initialSelectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(try XCTUnwrap(initialSelectedPages[safe: 0]) === self.page2)
        XCTAssertTrue(try XCTUnwrap(initialSelectedPages[safe: 1]) === self.page3)

        self.layoutEngine.draggedEvent(at: CGPoint(x: 45, y: 35))
        let finalSelectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(try XCTUnwrap(finalSelectedPages[safe: 0]) === self.page2)
    }

    func test_selectionRect_drawingSelectionRectOverPagesWithShiftModifierTogglesSelectionOnThosePages() throws {
         XCTAssertNil(self.layoutEngine.selectionRect)

        self.layoutEngine.downEvent(at: CGPoint(x: 10, y: 10), modifiers: .shift)
        self.layoutEngine.draggedEvent(at: CGPoint(x: 85, y: 35), modifiers: .shift)

        let initialSelectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(try XCTUnwrap(initialSelectedPages[safe: 0]) === self.page2)
        XCTAssertTrue(try XCTUnwrap(initialSelectedPages[safe: 1]) === self.page3)

        self.layoutEngine.draggedEvent(at: CGPoint(x: 45, y: 35))
        let finalSelectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(try XCTUnwrap(finalSelectedPages[safe: 0]) === self.page2)
    }

    func test_selectionRect_drawingSelectionRectOverSelectedPageWithShiftModifierTogglesDeselectsPageAndDraggingOffReselectsPage() throws {
         XCTAssertNil(self.layoutEngine.selectionRect)

        self.page2.selected = true

        self.layoutEngine.downEvent(at: CGPoint(x: 10, y: 10), modifiers: .shift)
        self.layoutEngine.draggedEvent(at: CGPoint(x: 85, y: 35), modifiers: .shift)

        let initialSelectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(try XCTUnwrap(initialSelectedPages[safe: 0]) === self.page3)

        self.layoutEngine.draggedEvent(at: CGPoint(x: 45, y: 35))
        let finalSelectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(try XCTUnwrap(finalSelectedPages[safe: 0]) === self.page2)
    }

    func test_selectionRect_informsViewOfSelectionChangeAfterUpEvent() throws {
        let testCanvas = TestCanvasView()
        self.layoutEngine.view = testCanvas

        self.layoutEngine.downEvent(at: CGPoint(x: 10, y: 10))
        XCTAssertFalse(try XCTUnwrap(testCanvas.context?.selectionChanged))
        self.layoutEngine.draggedEvent(at: CGPoint(x: 85, y: 35))
        XCTAssertFalse(try XCTUnwrap(testCanvas.context?.selectionChanged))
        self.layoutEngine.upEvent(at: CGPoint(x: 85, y: 35))
        XCTAssertTrue(try XCTUnwrap(testCanvas.context?.selectionChanged))
    }


    //MARK: - Enabled Page
    func test_enabledPage_isNilWhenNoPageSelected() {
        self.layoutEngine.finishedModifying([])

        XCTAssertNil(self.layoutEngine.enabledPage)
    }

    func test_enabledPage_isSetToSelectedPageIfSinglePageSelected() {
        self.page2.selected = true
        self.layoutEngine.finishedModifying([])

        XCTAssertEqual(self.layoutEngine.enabledPage, self.page2)
    }

    func test_enabledPage_isNilIfMultiplePagesSelected() {
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.finishedModifying([])

        XCTAssertNil(self.layoutEngine.enabledPage)
    }

    func test_enabledPage_isSetToSelectedPageIfAllOtherPagesAreDeselected() {
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.finishedModifying([])
        XCTAssertNil(self.layoutEngine.enabledPage)

        self.page2.selected = false
        self.layoutEngine.finishedModifying([])
        XCTAssertEqual(self.layoutEngine.enabledPage, self.page3)
    }


    //MARK: - Move Pages
    func test_moving_mouseDraggedFromPageTitleMovesThatPage() {
        let page1Point = self.page1.layoutFrame.origin

        let offset = CGPoint(x: 5, y: 3)
        self.layoutEngine.downEvent(at: page1Point.plus(.identity))
        self.layoutEngine.draggedEvent(at: page1Point.plus(.identity).plus(offset.multiplied(by: 0.5)))
        self.layoutEngine.draggedEvent(at: page1Point.plus(.identity).plus(offset))

        let expectedPoint = page1Point.plus(CGPoint(x: 5, y: 3))
        XCTAssertEqual(self.page1.layoutFrame.origin, expectedPoint)
    }

    func test_moving_mouseDraggedFromPageContentOfUnselectedPageMovesThatPage() {
        let page1Point = self.page1.layoutFrame.origin

        let offset = CGPoint(x: 5, y: 3)
        let eventStartPoint = self.page1.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: eventStartPoint)
        self.layoutEngine.draggedEvent(at: eventStartPoint.plus(offset.multiplied(by: 0.5)))
        self.layoutEngine.draggedEvent(at: eventStartPoint.plus(offset))

        let expectedPoint = page1Point.plus(CGPoint(x: 5, y: 3))
        XCTAssertEqual(self.page1.layoutFrame.origin, expectedPoint)
    }

    func test_moving_mouseDraggedFromPageTitleMovesAllSelectedPages() {
        self.page2.selected = true
        self.page3.selected = true
        let page2Point = self.page2.layoutFrame.origin
        let page3Point = self.page3.layoutFrame.origin

        let offset = CGPoint(x: 7, y: 8)

        self.layoutEngine.downEvent(at: page3Point.plus(.identity))
        self.layoutEngine.draggedEvent(at: page3Point.plus(.identity).plus(offset.multiplied(by: 0.5)))
        self.layoutEngine.draggedEvent(at: page3Point.plus(.identity).plus(offset))

        let expectedPage2Point = page2Point.plus(offset)
        XCTAssertEqual(self.page2.layoutFrame.origin, expectedPage2Point)
        let expectedPage3Point = page3Point.plus(offset)
        XCTAssertEqual(self.page3.layoutFrame.origin, expectedPage3Point)
    }

    func test_moving_mouseDraggedFromPageContentWithMultipleSelectionsMovesAllSelectedPages() {
        self.page2.selected = true
        self.page3.selected = true
        let page2Point = self.page2.layoutFrame.origin
        let page3Point = self.page3.layoutFrame.origin

        let offset = CGPoint(x: 7, y: 8)

        let eventStartPoint = self.page3.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: eventStartPoint)
        self.layoutEngine.draggedEvent(at: eventStartPoint.plus(offset.multiplied(by: 0.5)))
        self.layoutEngine.draggedEvent(at: eventStartPoint.plus(offset))

        let expectedPage2Point = page2Point.plus(offset)
        XCTAssertEqual(self.page2.layoutFrame.origin, expectedPage2Point)
        let expectedPage3Point = page3Point.plus(offset)
        XCTAssertEqual(self.page3.layoutFrame.origin, expectedPage3Point)
    }

    func test_moving_mouseUpInformsDelegateOfChangeToPages() throws {
        let delegate = TestLayoutDelegate()

        self.layoutEngine.delegate = delegate

        self.page2.selected = true
        self.page3.selected = true

        let page3Point = self.page3.layoutFrame.origin

        let offset = CGPoint(x: 7, y: 8)

        self.layoutEngine.downEvent(at: page3Point.plus(.identity))
        self.layoutEngine.draggedEvent(at: page3Point.plus(.identity).plus(offset))
        self.layoutEngine.upEvent(at: page3Point.plus(.identity).plus(offset))

        XCTAssertTrue(try XCTUnwrap(delegate.movedPages?[safe: 0]) === self.page2)
        XCTAssertTrue(try XCTUnwrap(delegate.movedPages?[safe: 1]) === self.page3)
    }

    func test_moving_downEventWithCount2SelectsAllChildPages() {
        let child1 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 120, y: 120, width: 30, height: 30),
                                      minimumContentSize: .zero)
        let child2 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 150, y: 180, width: 30, height: 30),
                                      minimumContentSize: .zero)
        self.page1.addChild(child1)
        self.page1.addChild(child2)
        self.layoutEngine.add([child1, child2])

        self.layoutEngine.downEvent(at: self.page1.layoutFrame.origin.plus(.identity), eventCount: 2)
        XCTAssertTrue(self.page1.selected)
        XCTAssertTrue(child1.selected)
        XCTAssertTrue(child2.selected)
    }



    //MARK: - Resize Page

    enum TestDragEdge {
        case min
        case mid
        case max
    }

    func drag(_ page: LayoutEnginePage, byXEdge xEdge: TestDragEdge, yEdge: TestDragEdge, deltaX: CGFloat, deltaY: CGFloat) {
        let startX: CGFloat
        switch (xEdge) {
        case .min:
            startX = page.layoutFrame.minX
        case .mid:
            startX = page.layoutFrame.midX
        case .max:
            startX = page.layoutFrame.maxX - 1
        }

        let startY: CGFloat
        switch (yEdge) {
        case .min:
            startY = page.layoutFrame.minY
        case .mid:
            startY = page.layoutFrame.midY
        case .max:
            startY = page.layoutFrame.maxY - 1
        }

        let startPoint = CGPoint(x: startX, y: startY)
        let endPoint = startPoint.plus(CGPoint(x: deltaX, y: deltaY))
        self.layoutEngine.downEvent(at: startPoint)
        self.layoutEngine.draggedEvent(at: endPoint)
        self.layoutEngine.upEvent(at: endPoint)
    }

    //Left
    func test_resizing_draggingLeftEdgeToLeftIncreasesWidthAndDecreasesOriginX() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.x -= 2
        expectedFrame.size.width += 2

        self.drag(self.page1, byXEdge: .min, yEdge: .mid, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingLeftEdgeToRightDecreasesWidthAndIncreasesOriginX() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.x += 2
        expectedFrame.size.width -= 2

        self.drag(self.page1, byXEdge: .min, yEdge: .mid, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingLeftEdgeToLeftStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width += expectedFrame.origin.x
        expectedFrame.origin.x = self.contentBorder

        self.drag(self.page1, byXEdge: .min, yEdge: .mid, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingLeftEdgeToRightStopsAtMinimumWidth() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.x += expectedFrame.width - self.page1.minimumContentSize.width
        expectedFrame.size.width = self.page1.minimumContentSize.width

        self.drag(self.page1, byXEdge: .min, yEdge: .mid, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top
    func test_resizing_draggingTopEdgeUpIncreasesHeightAndDecreasesOriginY() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.y -= 2
        expectedFrame.size.height += 2

        self.drag(self.page1, byXEdge: .mid, yEdge: .min, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopEdgeDownDecreasesHeightAndIncreasesOriginY() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.y += 2
        expectedFrame.size.height -= 2

        self.drag(self.page1, byXEdge: .mid, yEdge: .min, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopEdgeUpStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height += expectedFrame.origin.y
        expectedFrame.origin.y = self.contentBorder

        self.drag(self.page1, byXEdge: .mid, yEdge: .min, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopEdgeDownStopsAtMinimumHeight() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.y += expectedFrame.height - self.page1.minimumLayoutSize.height
        expectedFrame.size.height = self.page1.minimumLayoutSize.height

        self.drag(self.page1, byXEdge: .mid, yEdge: .min, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Right
    func test_resizing_draggingRightEdgeToRightIncreasesWidth() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width += 2

        self.drag(self.page1, byXEdge: .max, yEdge: .mid, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingRightEdgeToLeftDecreasesWidth() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width -= 2

        self.drag(self.page1, byXEdge: .max, yEdge: .mid, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingRightEdgeToRightStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width += self.contentFrame.maxX - expectedFrame.maxX + self.contentBorder

        self.drag(self.page1, byXEdge: .max, yEdge: .mid, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingRightEdgeToLeftStopsAtMinimumWidth() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width = self.page1.minimumContentSize.width

        self.drag(self.page1, byXEdge: .max, yEdge: .mid, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Bottom
    func test_resizing_draggingBottomEdgeDownIncreasesHeight() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height += 2

        self.drag(self.page1, byXEdge: .mid, yEdge: .max, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomEdgeUpDecreasesHeight() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height -= 2

        self.drag(self.page1, byXEdge: .mid, yEdge: .max, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomEdgeDownStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height += self.contentFrame.maxY - expectedFrame.maxY + self.contentBorder

        self.drag(self.page1, byXEdge: .mid, yEdge: .max, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomEdgeUpStopsAtMinimumHeight() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height = self.page1.minimumLayoutSize.height

        self.drag(self.page1, byXEdge: .mid, yEdge: .max, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top Left - Regular
    func test_resizing_draggingTopLeftEdgeToTopLeftIncreasesSizeAndDecreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -3, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.drag(self.page1, byXEdge: .min, yEdge: .min, deltaX: -3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToBottomRightDecreasesSizeAndIncreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 3, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.drag(self.page1, byXEdge: .min, yEdge: .min, deltaX: 3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToTopLeftStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: expectedFrame.maxX, height: expectedFrame.maxY)
        expectedFrame.origin = CGPoint(x: self.contentBorder, y: self.contentBorder)

        self.drag(self.page1, byXEdge: .min, yEdge: .min, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToBottomRightStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: expectedFrame.width - self.page1.minimumLayoutSize.width, y: expectedFrame.height - self.page1.minimumLayoutSize.height))
        expectedFrame.size = self.page1.minimumLayoutSize
        self.drag(self.page1, byXEdge: .min, yEdge: .min, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top Right - Regular
    func test_resizing_draggingTopRightEdgeToTopRightIncreasesSizeAndDecreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.drag(self.page1, byXEdge: .max, yEdge: .min, deltaX: 3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToBottomLeftDecreasesSizeAndIncreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.drag(self.page1, byXEdge: .max, yEdge: .min, deltaX: -3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToTopRightStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: self.contentFrame.maxX - expectedFrame.minX + self.layoutEngine.configuration.contentBorder, height: expectedFrame.maxY)
        expectedFrame.origin.y = self.contentBorder

        self.drag(self.page1, byXEdge: .max, yEdge: .min, deltaX: 100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToBottomLeftStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: expectedFrame.height - self.page1.minimumLayoutSize.height))
        expectedFrame.size = self.page1.minimumLayoutSize
        self.drag(self.page1, byXEdge: .max, yEdge: .min, deltaX: -100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Bottom Right - Regular
    func test_resizing_draggingBottomRightEdgeToBottomRightIncreasesSize() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.drag(self.page1, byXEdge: .max, yEdge: .max, deltaX: 3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToTopLeftDecreasesSize() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.drag(self.page1, byXEdge: .max, yEdge: .max, deltaX: -3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToBottomRightStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: self.contentFrame.maxX - expectedFrame.minX + self.layoutEngine.configuration.contentBorder, height: self.contentFrame.maxY - expectedFrame.minY + self.layoutEngine.configuration.contentBorder)

        self.drag(self.page1, byXEdge: .max, yEdge: .max, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToTopLeftStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = self.page1.minimumLayoutSize
        self.drag(self.page1, byXEdge: .max, yEdge: .max, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top Right - Regular
    func test_resizing_draggingBottomLeftEdgeToBottomLeftIncreasesSizeAndDecreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -3, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.drag(self.page1, byXEdge: .min, yEdge: .max, deltaX: -3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToTopRightDecreasesSizeAndIncreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 3, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.drag(self.page1, byXEdge: .min, yEdge: .max, deltaX: 3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToBottomLeftStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: expectedFrame.maxX, height: self.contentFrame.maxY - expectedFrame.minY  + self.layoutEngine.configuration.contentBorder)
        expectedFrame.origin.x = self.contentBorder

        self.drag(self.page1, byXEdge: .min, yEdge: .max, deltaX: -100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToTopRightStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: expectedFrame.width - self.page1.minimumLayoutSize.width, y: 0))
        expectedFrame.size = self.page1.minimumLayoutSize
        self.drag(self.page1, byXEdge: .min, yEdge: .max, deltaX: 100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top Left - Aspect
    func test_resizing_aspect_draggingTopLeftEdgeToTopIncreasesSizeAndDecreasesOrigin() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -2, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: -4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToBottomDecreasesSizeAndIncreasesOrigin() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 2, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: 4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToLeftDoesntChangeSizeOrOrigin() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        self.drag(page, byXEdge: .min, yEdge: .min, deltaX: -4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToRightDoesntChangeSizeOrOrigin() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToTopStopsAtCanvasEdgeIfWiderThanTaller() {
        let contentMidPoint = self.layoutEngine.convertPointToPageSpace(self.contentFrame.midPoint)
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: contentMidPoint.x - 20, y: contentMidPoint.y - 10, width: 40, height: 20),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = expectedFrame.minX
        let heightChange = widthChange / page.aspectRatio
        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin = expectedFrame.origin.plus(x: -widthChange, y: -heightChange).plus(x: self.contentBorder, y: 0)

        self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToTopStopsAtCanvasEdgeIfTallerThanWider() {
        let contentMidPoint = self.layoutEngine.convertPointToPageSpace(self.contentFrame.midPoint)
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: contentMidPoint.x - 10, y: contentMidPoint.y - 20, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let heightChange = expectedFrame.minY
        let widthChange = heightChange * page.aspectRatio
        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin = expectedFrame.origin.plus(x: -widthChange, y: -heightChange).plus(x: 0, y: self.contentBorder)

        self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToBottomStopsAtMinHeightIfWiderThanTaller() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 40, height: 20),
                                    maintainAspectRatio: true,
                                    minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = page.contentFrame.width / 2
        let heightChange = page.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin = expectedFrame.origin.plus(x: widthChange, y: heightChange)

        self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToBottomStopsAtMinWidthIfTallerThanWider() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = page.contentFrame.width / 2
        let heightChange = page.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin = expectedFrame.origin.plus(x: widthChange, y: heightChange)

        self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }
    

    //Top Right - Aspect
    func test_resizing_aspect_draggingTopRightEdgeToTopIncreasesSizeAndDecreasesY() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: -4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToBottomDecreasesSizeAndIncreasesY() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: 4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToLeftDoesntChangeSizeOrOrigin() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        self.drag(page, byXEdge: .max, yEdge: .min, deltaX: -4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToRightDoesntChangeSizeOrOrigin() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToTopStopsAtCanvasEdgeIfWiderThanTaller() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 40, height: 20),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = (self.contentFrame.maxX + self.contentBorder) - expectedFrame.maxX
        let heightChange = widthChange / page.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin.y -= heightChange

        self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToTopStopsAtCanvasEdgeIfTallerThanWider() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let heightChange = expectedFrame.minY
        let widthChange = heightChange * page.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin.y = self.contentBorder

        self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToBottomStopsAtMinHeightIfWiderThanTaller() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 40, height: 20),
                                    maintainAspectRatio: true,
                                    minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = page.contentFrame.width / 2
        let heightChange = page.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin.y += heightChange

        self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToBottomStopsAtMinWidthIfTallThanWider() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = page.contentFrame.width / 2
        let heightChange = page.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin.y += heightChange

        self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    //Bottom Right - Aspect
    func test_resizing_aspect_draggingBottomRightEdgeToBottomIncreasesSize() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: 4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToTopDecreasesSize() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: -4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToLeftDoesntChangeSizeOrOrigin() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        self.drag(page, byXEdge: .max, yEdge: .max, deltaX: -4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToRightDoesntChangeSizeOrOrigin() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToBottomStopsAtCanvasEdgeIfWiderThanTaller() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 40, height: 20),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = (self.contentFrame.maxX + self.contentBorder) - expectedFrame.maxX
        let heightChange = widthChange / page.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)

        self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToBottomStopsAtCanvasEdgeIfTallerThanWider() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let heightChange = (self.contentFrame.maxY + self.contentBorder) - expectedFrame.maxY
        let widthChange = heightChange * page.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)

        self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToTopStopsAtMinHeightIfWiderThanTaller() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 40, height: 20),
                                    maintainAspectRatio: true,
                                    minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = page.contentFrame.width / 2
        let heightChange = page.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)

        self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToTopStopsAtMinWidthIfTallThanWider() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = page.contentFrame.width / 2
        let heightChange = page.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)

        self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    //Bottom Left - Aspect
    func test_resizing_aspect_draggingBottomLeftEdgeToBottomIncreasesSizeAndDecreasesX() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -2, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: 4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToTopDecreasesSizeAndIncreasesX() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 2, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: -4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToLeftDoesntChangeSizeOrOrigin() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        self.drag(page, byXEdge: .min, yEdge: .max, deltaX: -4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToRightDoesntChangeSizeOrOrigin() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToBottomStopsAtCanvasEdgeIfWiderThanTaller() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 40, height: 20),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = expectedFrame.minX
        let heightChange = widthChange / page.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin.x = self.contentBorder

        self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToTopStopsAtCanvasEdgeIfTallerThanWider() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let heightChange = (self.contentFrame.maxY + self.contentBorder) - expectedFrame.maxY
        let widthChange = heightChange * page.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin.x -= widthChange

        self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToTopStopsAtMinHeightIfWiderThanTaller() {
        let page = LayoutEnginePage(id: UUID(),
                                     contentFrame: CGRect(x: 0, y: 0, width: 40, height: 20),
                                     maintainAspectRatio: true,
                                     minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = page.contentFrame.width / 2
        let heightChange = page.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin.x += widthChange

        self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToTopStopsAtMinWidthIfTallThanWider() {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = page.contentFrame.width / 2
        let heightChange = page.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin.x += widthChange

        self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }



    //MARK: - Background
    func test_pageBackground_noPageShowsBackgroundIfMouseMovedOverCanvasAndNothingSelected() {
        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)

        self.layoutEngine.moveEvent(at: CGPoint(x: 40, y: 100))

        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)
    }

    func test_pageBackground_pageShowsBackgroundIfMouseMovesOverPage() {
        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: 3, y: 3)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertTrue(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)
    }

    func test_pageBackground_pageStillShowsBackgroundIfMouseMovesFurtherOverPage() {
        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: 3, y: 3)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertTrue(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: 5, y: 4)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertTrue(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)
    }

    func test_pageBackground_pageDoesntShowBackgroundIfMouseMovesOffPage() {
        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: 3, y: 3)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertTrue(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: -2, y: -2)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)
    }

    func test_pageBackground_pagesShowBackgroundIfSelected() {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        let clickPoint1 = self.page1.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint1)

        let clickPoint3 = self.page3.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint3, modifiers: .shift)

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)

        XCTAssertTrue(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertTrue(self.page3.showBackground)
    }

    func test_pageBackground_pageStillShowsBackgroundIfSelectedAndMouseMovesOver() {
        let clickPoint1 = self.page1.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint1)

        self.layoutEngine.moveEvent(at: clickPoint1.plus(CGPoint(x: 2, y: 3)))

        XCTAssertTrue(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)
    }

    func test_pageBackground_pageStillShowsBackgroundIfSelectedAndMouseMovesOff() {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        let clickPoint = self.page3.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint)

        self.layoutEngine.moveEvent(at: self.page3.layoutFrame.origin.minus(CGPoint(x: 10, y: 10)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertTrue(self.page3.showBackground)
    }

    func test_pageBackground_allSelectedPagesAndTheHoveredPageShowBackground() {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        let clickPoint1 = self.page1.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint1)

        let clickPoint3 = self.page3.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint3, modifiers: .shift)

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.midPoint)

        XCTAssertTrue(self.page1.showBackground)
        XCTAssertTrue(self.page2.showBackground)
        XCTAssertTrue(self.page3.showBackground)
    }

    func test_pageBackground_onlySelectedPagesShowBackgroundAfterMouseMovesOffHoveredPage() {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        let clickPoint1 = self.page1.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint1)

        let clickPoint3 = self.page3.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint3, modifiers: .shift)

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.midPoint)
        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.minus(x: 10, y: 10))

        XCTAssertTrue(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertTrue(self.page3.showBackground)
    }

    func test_pageBackground_notifiesViewWhenPageHoveredOver() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: 3, y: 3)))

        XCTAssertTrue(try XCTUnwrap(view.context?.backgroundVisibilityChanged))
    }

    func test_pageBackground_notifiesViewWhenMovedAwayFromHoveredPage() {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        view.context = nil

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.minus(x: 3, y: 3))

        XCTAssertTrue(try XCTUnwrap(view.context?.backgroundVisibilityChanged))
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOverHoveredPage() {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        view.context = nil

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 4, y: 4))

        XCTAssertNil(view.context)
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOntoSelectedPage() {
        self.page2.selected = true
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        XCTAssertNil(view.context)
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOffSelectedPageToCanvas() {
        self.page2.selected = true
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        XCTAssertNil(view.context)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.minus(x: 4, y: 4))
        XCTAssertNil(view.context)
    }

    func test_pageBackground_notifiesViewWhenMovingOffSelectedPageToOtherUnselectedPage() {
        self.page2.selected = true
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        XCTAssertNil(view.context)

        self.layoutEngine.moveEvent(at: self.page3.layoutFrame.midPoint)
        XCTAssertNil(view.context)
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOffSelectedPageToOtherSelectedPage() {
        self.page2.selected = true
        self.page3.selected = true
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        XCTAssertNil(view.context)

        self.layoutEngine.moveEvent(at: self.page3.layoutFrame.midPoint)
        XCTAssertNil(view.context)
    }



    //MARK: - Canvas Size and Offset
    func test_canvasSize_canvasSizeShouldEqualContentBoundsPlusCanvasBorderOnEachSize() {
        XCTAssertEqual(self.layoutEngine.canvasSize, self.contentFrame.insetBy(dx: -20, dy: -20).size)
    }

    func test_canvasSize_canvasSizeShouldBeBiggerThanContentBoundsPlusCanvasBorderIfViewPortFrameIsOutside() {
        let testCanvas = TestCanvasView()
        testCanvas.viewPortFrame = CGRect(x: 60, y: 60, width: 80, height: 80)
        self.layoutEngine.view = testCanvas

        self.drag(self.page1, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: 0)

        let borderedContentFrame = self.contentFrame.insetBy(dx: -20, dy: -20)
        let fullFrame = borderedContentFrame.union(testCanvas.viewPortFrame)
        XCTAssertEqual(self.layoutEngine.canvasSize, fullFrame.size)
    }

    func test_canvasSize_pageSpaceOffsetShouldChangeIfCanvasGrowsUpwards() {
        let initialOffset = self.layoutEngine.convertPointToPageSpace(.zero)

        let pageOrigin = self.page2.layoutFrame
        let startPoint = CGPoint(x: pageOrigin.midX, y: pageOrigin.minY + 3)
        let endPoint = startPoint.plus(CGPoint(x: 0, y: -20))

        self.layoutEngine.downEvent(at: startPoint)
        self.layoutEngine.draggedEvent(at: endPoint)
        self.layoutEngine.upEvent(at: endPoint)

        let newOffset = self.layoutEngine.convertPointToPageSpace(.zero)

        XCTAssertEqual(initialOffset.minus(newOffset), CGPoint(x: 0, y: 10))
    }

    func test_canvasSize_pageSpaceOffsetShouldChangeIfCanvasGrowsToLeft() {
        let initialOffset = self.layoutEngine.convertPointToPageSpace(.zero)

        let pageOrigin = self.page2.layoutFrame
        let startPoint = CGPoint(x: pageOrigin.midX, y: pageOrigin.minY + 3)
        let endPoint = startPoint.plus(CGPoint(x: -20, y: 0))

        self.layoutEngine.downEvent(at: startPoint)
        self.layoutEngine.draggedEvent(at: endPoint)
        self.layoutEngine.upEvent(at: endPoint)

        let newOffset = self.layoutEngine.convertPointToPageSpace(.zero)

        XCTAssertEqual(initialOffset.minus(newOffset), CGPoint(x: 20, y: 0))
    }

    func test_canvasSize_canvasSizeShouldUpdateWhenMovingPagesEnds() {
        let initialSize = self.layoutEngine.canvasSize
        let pageOrigin = self.page2.layoutFrame
        let startPoint = CGPoint(x: pageOrigin.midX, y: pageOrigin.minY + 3)
        let endPoint = startPoint.plus(CGPoint(x: -20, y: 0))

        self.layoutEngine.downEvent(at: startPoint)
        XCTAssertEqual(self.layoutEngine.canvasSize, initialSize)
        self.layoutEngine.draggedEvent(at: endPoint)
        XCTAssertEqual(self.layoutEngine.canvasSize, initialSize)
        self.layoutEngine.upEvent(at: endPoint)
        XCTAssertNotEqual(self.layoutEngine.canvasSize, initialSize)
    }

    func test_canvasSize_canvasSizeShouldUpdateWhenResizingPageEnds() {
        let initialSize = self.layoutEngine.canvasSize
        let pageOrigin = self.page2.layoutFrame
        let startPoint = CGPoint(x: pageOrigin.minX, y: pageOrigin.midY)
        let endPoint = startPoint.plus(CGPoint(x: -20, y: 0))

        self.layoutEngine.downEvent(at: startPoint)
        XCTAssertEqual(self.layoutEngine.canvasSize, initialSize)
        self.layoutEngine.draggedEvent(at: endPoint)
        XCTAssertEqual(self.layoutEngine.canvasSize, initialSize)
        self.layoutEngine.upEvent(at: endPoint)
        XCTAssertNotEqual(self.layoutEngine.canvasSize, initialSize)
    }

    func test_canvasSize_updatesAllPagesCanvasFrameIfCanvasResizesUpAndToTheLeft() {
        let page1Origin = self.page1.layoutFrame.origin
        let page3Origin = self.page3.layoutFrame.origin

        let pageOrigin = self.page2.layoutFrame
        let startPoint = CGPoint(x: pageOrigin.midX, y: pageOrigin.minY + 3)
        let endPoint = startPoint.plus(CGPoint(x: -10, y: -30))

        self.layoutEngine.downEvent(at: startPoint)
        self.layoutEngine.draggedEvent(at: endPoint)
        self.layoutEngine.upEvent(at: endPoint)

        XCTAssertEqual(self.page1.layoutFrame.origin, page1Origin.plus(CGPoint(x: 10, y: 20)))
        XCTAssertEqual(self.page2.layoutFrame.origin, CGPoint(x: self.layoutEngine.configuration.contentBorder, y: self.layoutEngine.configuration.contentBorder))
        XCTAssertEqual(self.page3.layoutFrame.origin, page3Origin.plus(CGPoint(x: 10, y: 20)))
    }

    func test_canvasSize_doesNOTUpdatePagesCanvasFrameIfCanvasResizesDownToTheLeft() {
        let page1Origin = self.page1.layoutFrame.origin
        let page2Origin = self.page2.layoutFrame.origin
        let page3Origin = self.page3.layoutFrame.origin

        let pageOrigin = self.page1.layoutFrame
        let startPoint = CGPoint(x: pageOrigin.midX, y: pageOrigin.minY + 3)
        let endPoint = startPoint.plus(CGPoint(x: 10, y: 20))

        self.layoutEngine.downEvent(at: startPoint)
        self.layoutEngine.draggedEvent(at: endPoint)
        self.layoutEngine.upEvent(at: endPoint)

        XCTAssertEqual(self.page1.layoutFrame.origin, page1Origin.plus(CGPoint(x: 10, y: 20)))
        XCTAssertEqual(self.page2.layoutFrame.origin, page2Origin)
        XCTAssertEqual(self.page3.layoutFrame.origin, page3Origin)
    }


    //MARK: - Keyboard Moving
    private func layoutFrames(shiftingSelectedBy delta: CGPoint = .zero) -> [CGRect] {
        var frames = [CGRect]()
        for page in [self.page1!, self.page2!, self.page3!] {
            var frame = page.layoutFrame
            if page.selected {
                frame = frame.offsetBy(dx: delta.x, dy: delta.y)
            }
            frames.append(frame)
        }
        return frames
    }

    private func performKeyboardMoveTest(keyCode: Int, downEventCount: Int = 1, expectedShift: CGPoint = .zero, modifiers: (Int) -> LayoutEventModifiers = {_ in []}) -> (actual: [CGRect], expected: [CGRect]) {
        let expectedFrames = self.layoutFrames(shiftingSelectedBy: expectedShift)

        self.layoutEngine.keyDownEvent(keyCode: UInt16(keyCode), modifiers: modifiers(0))
        (1..<downEventCount).forEach {
            self.layoutEngine.keyDownEvent(keyCode: UInt16(keyCode), modifiers: modifiers($0), isARepeat: true)
        }
        self.layoutEngine.keyUpEvent(keyCode: UInt16(keyCode), modifiers: modifiers(downEventCount))

        return (self.layoutFrames(), expectedFrames)
    }

    func test_keyboardMoving_pressingUpArrowWithNoSelectionDoesNothing() {
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow)
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingDownArrowWithNoSelectionDoesNothing() {
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow)
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingLeftArrowWithNoSelectionDoesNothing() {
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow)
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingRightArrowWithNoSelectionDoesNothing() {
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow)
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingUpArrowOnceMovesSelectionUp() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, expectedShift: CGPoint(x: 0, y: -1))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingDownArrowOnceMovesSelectionDown() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, expectedShift: CGPoint(x: 0, y: 1))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingLeftArrowOnceMovesSelectionToLeft() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, expectedShift: CGPoint(x: -1, y: 0))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingRightArrowOnceMovesSelectionToRight() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, expectedShift: CGPoint(x: 1, y: 0))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingUpArrowAndHoldingFor10EventsMovesSelection10StepsUp() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: -10))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingDownArrowAndHoldingFor10EventsMovesSelection10StepsDown() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: 10))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingLeftArrowAndHoldingFor10EventsMovesSelection10StepsToLeft() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, downEventCount: 10, expectedShift: CGPoint(x: -10, y: 0))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingRightArrowAndHoldingFor10EventsMovesSelection10StepsToRight() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, downEventCount: 10, expectedShift: CGPoint(x: 10, y: 0))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingUpArrowOnceWhileHoldingShiftMovesSelectionUp10Steps() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, expectedShift: CGPoint(x: 0, y: -10)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingDownArrowOnceWhileHoldingShiftMovesSelectionDown10Steps() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, expectedShift: CGPoint(x: 0, y: 10)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingLeftArrowOnceWhileHoldingShiftMovesSelectionLeft10Steps() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, expectedShift: CGPoint(x: -10, y: 0)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingRightArrowOnceWhileHoldingShiftMovesSelectionRight10Steps() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, expectedShift: CGPoint(x: 10, y: 0)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingUpArrowAndHoldingWhileHoldingShiftFor10EventsMovesSelection100StepsUp() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: -100)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingDownArrowAndHoldingWhileHoldingShiftFor10EventsMovesSelection100StepsDown() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: 100)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingLeftArrowAndHoldingWhileHoldingShiftFor10EventsMovesSelection100StepsToLeft() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, downEventCount: 10, expectedShift: CGPoint(x: -100, y: 0)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingRightArrowAndHoldingWhileHoldingShiftFor10EventsMovesSelection100StepsToRight() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, downEventCount: 10, expectedShift: CGPoint(x: 100, y: 0)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingUpArrowAndHoldingWhileAlternatingShiftOnAndOffFor10EventsMovesSelection55StepsUp() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: -55)) { (($0 % 2) == 0) ? .shift : [] }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingDownArrowAndHoldingWhileAlternatingShiftOnAndOffFor10EventsMovesSelection55StepsDown() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: 55)) { (($0 % 2) == 0) ? .shift : [] }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingLeftArrowAndHoldingWhileAlternatingShiftOnAndOffFor10EventsMovesSelection55StepsToLeft() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, downEventCount: 10, expectedShift: CGPoint(x: -55, y: 0)) { (($0 % 2) == 0) ? .shift : [] }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_pressingRightArrowAndHoldingWhileAlternatingShiftOnAndOffFor10EventsMovesSelection55StepsToRight() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, downEventCount: 10, expectedShift: CGPoint(x: 55, y: 0)) { (($0 % 2) == 0) ? .shift : [] }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_keyboardMoving_callsDelegateAfterMovingPages() {
        let delegate = TestLayoutDelegate()
        self.layoutEngine.delegate = delegate

        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = true
        _ = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, expectedShift: CGPoint(x: -1, y: 0))

        XCTAssertEqual(delegate.movedPages, [self.page1, self.page3])
    }


    //MARK: - Keyboard Deleting
    func test_keyboardDeletion_pressingBackspaceWithNothingSelectedDoesNothing() {
        let delegate = TestLayoutDelegate()
        self.layoutEngine.delegate = delegate

        self.layoutEngine.keyDownEvent(keyCode: UInt16(kVK_Delete))
        self.layoutEngine.keyUpEvent(keyCode: UInt16(kVK_Delete))

        XCTAssertNil(delegate.removePages)
    }

    func test_keyboardDeletion_pressingBackspaceRemovesSelectedPages() {
        let delegate = TestLayoutDelegate()
        self.layoutEngine.delegate = delegate

        self.page1.selected = true
        self.page3.selected = true

        self.layoutEngine.keyDownEvent(keyCode: UInt16(kVK_Delete))
        self.layoutEngine.keyUpEvent(keyCode: UInt16(kVK_Delete))

        XCTAssertEqual(delegate.removePages, [self.page1, self.page3])
    }

    func test_keyboardDeletion_pressingDeleteWithNothingSelectedDoesNothing() {
        let delegate = TestLayoutDelegate()
        self.layoutEngine.delegate = delegate

        self.layoutEngine.keyDownEvent(keyCode: UInt16(kVK_ForwardDelete))
        self.layoutEngine.keyUpEvent(keyCode: UInt16(kVK_ForwardDelete))

        XCTAssertNil(delegate.removePages)
    }

    func test_keyboardDeletion_pressingDeleteRemovesSelectedPages() {
        let delegate = TestLayoutDelegate()
        self.layoutEngine.delegate = delegate

        self.page1.selected = true
        self.page3.selected = true

        self.layoutEngine.keyDownEvent(keyCode: UInt16(kVK_ForwardDelete))
        self.layoutEngine.keyUpEvent(keyCode: UInt16(kVK_ForwardDelete))

        XCTAssertEqual(delegate.removePages, [self.page1, self.page3])
    }
}


private class TestLayoutDelegate: CanvasLayoutEngineDelegate {
    var movedPages: [LayoutEnginePage]?
    func moved(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine) {
        self.movedPages = pages
    }

    var removePages: [LayoutEnginePage]?
    func remove(pages: [LayoutEnginePage], from layout: CanvasLayoutEngine) {
        self.removePages = pages
    }
}

private class TestCanvasView: CanvasLayoutView {
    var context: CanvasLayoutEngine.LayoutContext?
    func layoutChanged(with context: CanvasLayoutEngine.LayoutContext) {
        self.context = context
    }
    var viewPortFrame: CGRect = .zero
}
