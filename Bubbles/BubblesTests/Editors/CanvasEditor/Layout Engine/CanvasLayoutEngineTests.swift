//
//  CanvasLayoutEngineTests.swift
//  Canvas FinalTests
//
//  Created by Martin Pilkington on 31/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

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

class TestComponentProvider: LayoutPageComponentProvider {
    func component(at point: CGPoint, in page: LayoutEnginePage) -> LayoutEnginePageComponent? {
        if (point.x == 0) {
            if (point.y == 0) {
                return .resizeTopLeft
            }
            if (point.y == page.contentFrame.size.height - 1) {
                return .resizeBottomLeft
            }
            return .resizeLeft
        }
        if (point.x == page.contentFrame.size.width - 1) {
            if (point.y == 0) {
                return .resizeTopRight
            }
            if (point.y == page.contentFrame.size.height - 1) {
                return .resizeBottomRight
            }
            return .resizeRight
        }
        if (point.y == 0) {
            return .resizeTop
        }
        if (point.y == page.contentFrame.size.height - 1) {
            return .resizeBottom
        }
        if (point.y <= 5) {
            return .titleBar
        }
        return nil
    }
}

class CanvasLayoutEngineTests: XCTestCase {

    var layoutEngine: CanvasLayoutEngine!
    var page1: LayoutEnginePage!
    var page2: LayoutEnginePage!
    var page3: LayoutEnginePage!
    var contentFrame: CGRect = .zero

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        self.layoutEngine = CanvasLayoutEngine(configuration: .init(pageTitleHeight: 5,
                                                                    pageResizeEdgeHandleSize: 1,
                                                                    pageResizeCornerHandleSize: 1,
                                                                    pageResizeHandleOffset: 0))
        self.layoutEngine.contentBorder = 20

        self.page1 = self.layoutEngine.addPage(withID: UUID(),
                                               contentFrame: CGRect(x: 40, y: 40, width: 10, height: 10),
                                               minimumContentSize: CGSize(width: 0, height: 0))
        self.page1.componentProvider = TestComponentProvider()

        self.page2 = self.layoutEngine.addPage(withID: UUID(),
                                               contentFrame: CGRect(x: -30, y: -20, width: 20, height: 40),
                                               minimumContentSize: CGSize(width: 0, height: 0))
        self.page2.componentProvider = TestComponentProvider()

        self.page3 = self.layoutEngine.addPage(withID: UUID(),
                                               contentFrame: CGRect(x: 30, y: -30, width: 30, height: 20),
                                               minimumContentSize: CGSize(width: 0, height: 0))
        self.page3.componentProvider = TestComponentProvider()

        self.contentFrame = self.page1.canvasFrame.union(self.page2.canvasFrame).union(self.page3.canvasFrame)
    }

    override func tearDown() {
        self.layoutEngine = nil
        self.page1 = nil
        self.page2 = nil
        self.page3 = nil
        self.contentFrame = .zero
    }

    //MARK: - TestLayoutEnginePage Sanity Tests
    func test_testLayoutEnginePage_sanityTests() {
        let page = self.layoutEngine.addPage(withID: UUID(),
                                             contentFrame: CGRect(x: 42, y: 31, width: 20, height: 20),
                                             minimumContentSize: CGSize(width: 0, height: 0))
        page.componentProvider = TestComponentProvider()

        XCTAssertEqual(page.component(at: CGPoint(x: 0, y: 0)), .resizeTopLeft)
        XCTAssertEqual(page.component(at: CGPoint(x: 0, y: 1)), .resizeLeft)
        XCTAssertEqual(page.component(at: CGPoint(x: 0, y: 18)), .resizeLeft)
        XCTAssertEqual(page.component(at: CGPoint(x: 0, y: 19)), .resizeBottomLeft)
        XCTAssertEqual(page.component(at: CGPoint(x: 19, y: 0)), .resizeTopRight)
        XCTAssertEqual(page.component(at: CGPoint(x: 19, y: 1)), .resizeRight)
        XCTAssertEqual(page.component(at: CGPoint(x: 19, y: 18)), .resizeRight)
        XCTAssertEqual(page.component(at: CGPoint(x: 19, y: 19)), .resizeBottomRight)
        XCTAssertEqual(page.component(at: CGPoint(x: 1, y: 0)), .resizeTop)
        XCTAssertEqual(page.component(at: CGPoint(x: 18, y: 0)), .resizeTop)
        XCTAssertEqual(page.component(at: CGPoint(x: 1, y: 19)), .resizeBottom)
        XCTAssertEqual(page.component(at: CGPoint(x: 18, y: 19)), .resizeBottom)
        XCTAssertEqual(page.component(at: CGPoint(x: 1, y: 1)), .titleBar)
        XCTAssertEqual(page.component(at: CGPoint(x: 18, y: 1)), .titleBar)
        XCTAssertEqual(page.component(at: CGPoint(x: 1, y: 5)), .titleBar)
        XCTAssertEqual(page.component(at: CGPoint(x: 18, y: 5)), .titleBar)
        XCTAssertEqual(page.component(at: CGPoint(x: 10, y: 3)), .titleBar)
    }


    //MARK: - Point Convertion
    func test_pointConversion_convertsPointFromPageSpaceToCanvasSpaceForEmptyEngine() {
        let basePoint = CGPoint(x: 10, y: 42)

        let emptyEngine = CanvasLayoutEngine(configuration: .init(pageTitleHeight: 5,
                                                                  pageResizeEdgeHandleSize: 1,
                                                                  pageResizeCornerHandleSize: 1,
                                                                  pageResizeHandleOffset: 0))
        let expectedPoint = basePoint
        XCTAssertEqual(emptyEngine.convertPointToCanvasSpace(basePoint), expectedPoint)
    }

    func test_pointConversion_convertsPointFromPageSpaceToCanvasSpace() {
        let basePoint = CGPoint(x: 10, y: 42)

        let offset = CGPoint(x: 50, y: 50)
        let expectedPoint = basePoint.plus(offset)
        XCTAssertEqual(self.layoutEngine.convertPointToCanvasSpace(basePoint), expectedPoint)
    }

    func test_pointConversion_convertsPointFromCanvasSpaceToPageSpaceForEmptyEngine() {
        let basePoint = CGPoint(x: 15, y: 31)

        let emptyEngine = CanvasLayoutEngine(configuration: .init(pageTitleHeight: 5,
                                                                  pageResizeEdgeHandleSize: 1,
                                                                  pageResizeCornerHandleSize: 1,
                                                                  pageResizeHandleOffset: 0))
        let expectedPoint = basePoint
        XCTAssertEqual(emptyEngine.convertPointToPageSpace(basePoint), expectedPoint)
    }

    func test_pointConversion_convertsPointFromCanvasSpaceToPageSpace() {
        let basePoint = CGPoint(x: 65, y: 81)

        let offset = CGPoint(x: 50, y: 50)
        let expectedPoint = basePoint.minus(offset)
        XCTAssertEqual(self.layoutEngine.convertPointToPageSpace(basePoint), expectedPoint)
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

        let clickPoint = self.page3.canvasFrame.origin.plus(.identity)
        self.layoutEngine.downEvent(at: clickPoint)

        XCTAssertTrue(self.layoutEngine.selectedPages.first === self.page3)
    }

    func test_selection_mouseDownWithNoModifiersOnUnselectedPageTitleDeselectsCurrentSelectionAndSelectsThatPage() throws {
        self.page1.selected = true
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 1)

        let clickPoint = self.page3.canvasFrame.origin.plus(.identity)
        self.layoutEngine.downEvent(at: clickPoint)
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 1)
        XCTAssertTrue(self.layoutEngine.selectedPages.first === self.page3)
    }

    func test_selection_mouseDownWithNoModifiersOnPageTitleInCurrentSelectionDoesntChangeSelection() throws {
        self.page1.selected = true
        self.page3.selected = true
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)

        let clickPoint = self.page3.canvasFrame.origin.plus(.identity)
        self.layoutEngine.downEvent(at: clickPoint)

        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertEqual(selectedPages.count, 2)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 0]) === self.page1)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 1]) === self.page3)
    }

    func test_selection_mouseDownWithShiftModifierOnPageTitleAddsThatPageToSelectionIfNotAlreadySelected() throws {
        self.page3.selected = true

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 1)
        self.layoutEngine.downEvent(at: self.page1.canvasFrame.origin.plus(.identity), modifiers: .shift)
        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(selectedPages.contains(self.page1))
        XCTAssertTrue(selectedPages.contains(self.page3))
    }

    func test_selection_mouseDownWithShiftModifierOnPageTitleRemovesThatPageFromSelectionIAlreadySelected() {
        self.page2.selected = true
        self.page3.selected = true

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)
        self.layoutEngine.downEvent(at: self.page2.canvasFrame.origin.plus(.identity), modifiers: .shift)
        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertEqual(selectedPages.count, 1)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 0]) === self.page3)
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


    //MARK: - Move Pages
    func test_moving_mouseDraggedFromPageTitleMovesThatPage() {
        let page1Point = self.page1.canvasFrame.origin

        let offset = CGPoint(x: 5, y: 3)
        self.layoutEngine.downEvent(at: page1Point.plus(.identity))
        self.layoutEngine.draggedEvent(at: page1Point.plus(.identity).plus(offset.multiplied(by: 0.5)))
        self.layoutEngine.draggedEvent(at: page1Point.plus(.identity).plus(offset))

        let expectedPoint = page1Point.plus(CGPoint(x: 5, y: 3))
        XCTAssertEqual(self.page1.canvasFrame.origin, expectedPoint)
    }

    func test_moving_mouseDraggedFromPageTitleMovesAllSelectedPages() {
        self.page2.selected = true
        self.page3.selected = true
        let page2Point = self.page2.canvasFrame.origin
        let page3Point = self.page3.canvasFrame.origin

        let offset = CGPoint(x: 7, y: 8)

        self.layoutEngine.downEvent(at: page3Point.plus(.identity))
        self.layoutEngine.draggedEvent(at: page3Point.plus(.identity).plus(offset.multiplied(by: 0.5)))
        self.layoutEngine.draggedEvent(at: page3Point.plus(.identity).plus(offset))

        let expectedPage2Point = page2Point.plus(offset)
        XCTAssertEqual(self.page2.canvasFrame.origin, expectedPage2Point)
        let expectedPage3Point = page3Point.plus(offset)
        XCTAssertEqual(self.page3.canvasFrame.origin, expectedPage3Point)
    }

    func test_moving_mouseUpInformsDelegateOfChangeToPages() throws {
        class TestDelegate: CanvasLayoutEngineDelegate {
            var movedPages: [LayoutEnginePage]?

            func moved(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine) {
                self.movedPages = pages
            }
        }

        let delegate = TestDelegate()

        self.layoutEngine.delegate = delegate

        self.page2.selected = true
        self.page3.selected = true

        let page3Point = self.page3.canvasFrame.origin

        let offset = CGPoint(x: 7, y: 8)

        self.layoutEngine.downEvent(at: page3Point.plus(.identity))
        self.layoutEngine.draggedEvent(at: page3Point.plus(.identity).plus(offset))
        self.layoutEngine.upEvent(at: page3Point.plus(.identity).plus(offset))

        XCTAssertTrue(try XCTUnwrap(delegate.movedPages?[safe: 0]) === self.page2)
        XCTAssertTrue(try XCTUnwrap(delegate.movedPages?[safe: 1]) === self.page3)
    }

    //MARK: - Resize Page

    enum TestDragEdge {
        case min
        case mid
        case max
    }

    func dragPageBy(xEdge: TestDragEdge, yEdge: TestDragEdge, deltaX: CGFloat, deltaY: CGFloat) {
        let startX: CGFloat
        switch (xEdge) {
        case .min:
            startX = self.page1.canvasFrame.minX
        case .mid:
            startX = self.page1.canvasFrame.midX
        case .max:
            startX = self.page1.canvasFrame.maxX - 1
        }

        let startY: CGFloat
        switch (yEdge) {
        case .min:
            startY = self.page1.canvasFrame.minY
        case .mid:
            startY = self.page1.canvasFrame.midY
        case .max:
            startY = self.page1.canvasFrame.maxY - 1
        }

        let startPoint = CGPoint(x: startX, y: startY)
        let endPoint = startPoint.plus(CGPoint(x: deltaX, y: deltaY))
        self.layoutEngine.downEvent(at: startPoint)
        self.layoutEngine.draggedEvent(at: endPoint)
        self.layoutEngine.upEvent(at: endPoint)
    }

    //Left
    func test_resizing_draggingLeftEdgeToLeftIncreasesWidthAndDecreasesOriginX() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin.x -= 2
        expectedFrame.size.width += 2

        self.dragPageBy(xEdge: .min, yEdge: .mid, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingLeftEdgeToRightDecreasesWidthAndIncreasesOriginX() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin.x += 2
        expectedFrame.size.width -= 2

        self.dragPageBy(xEdge: .min, yEdge: .mid, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingLeftEdgeToLeftStopsAtCanvasEdge() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size.width += expectedFrame.origin.x
        expectedFrame.origin.x = 20

        self.dragPageBy(xEdge: .min, yEdge: .mid, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingLeftEdgeToRightStopsAtMinimumWidth() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin.x += expectedFrame.width - self.page1.minimumContentSize.width
        expectedFrame.size.width = self.page1.minimumContentSize.width

        self.dragPageBy(xEdge: .min, yEdge: .mid, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    //Top
    func test_resizing_draggingTopEdgeUpIncreasesHeightAndDecreasesOriginY() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin.y -= 2
        expectedFrame.size.height += 2

        self.dragPageBy(xEdge: .mid, yEdge: .min, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingTopEdgeDownDecreasesHeightAndIncreasesOriginY() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin.y += 2
        expectedFrame.size.height -= 2

        self.dragPageBy(xEdge: .mid, yEdge: .min, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingTopEdgeUpStopsAtCanvasEdge() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size.height += expectedFrame.origin.y
        expectedFrame.origin.y = 20

        self.dragPageBy(xEdge: .mid, yEdge: .min, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingTopEdgeDownStopsAtMinimumHeight() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin.y += expectedFrame.height - self.page1.minimumContentSize.height
        expectedFrame.size.height = self.page1.minimumContentSize.height

        self.dragPageBy(xEdge: .mid, yEdge: .min, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    //Right
    func test_resizing_draggingRightEdgeToRightIncreasesWidth() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size.width += 2

        self.dragPageBy(xEdge: .max, yEdge: .mid, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingRightEdgeToLeftDecreasesWidth() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size.width -= 2

        self.dragPageBy(xEdge: .max, yEdge: .mid, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingRightEdgeToRightStopsAtCanvasEdge() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size.width += self.contentFrame.maxX - expectedFrame.maxX + self.layoutEngine.contentBorder

        self.dragPageBy(xEdge: .max, yEdge: .mid, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingRightEdgeToLeftStopsAtMinimumWidth() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size.width = self.page1.minimumContentSize.width

        self.dragPageBy(xEdge: .max, yEdge: .mid, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    //Bottom
    func test_resizing_draggingBottomEdgeDownIncreasesHeight() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size.height += 2

        self.dragPageBy(xEdge: .mid, yEdge: .max, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingBottomEdgeUpDecreasesHeight() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size.height -= 2

        self.dragPageBy(xEdge: .mid, yEdge: .max, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingBottomEdgeDownStopsAtCanvasEdge() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size.height += self.contentFrame.maxY - expectedFrame.maxY + self.layoutEngine.contentBorder

        self.dragPageBy(xEdge: .mid, yEdge: .max, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingBottomEdgeUpStopsAtMinimumHeight() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size.height = self.page1.minimumContentSize.height

        self.dragPageBy(xEdge: .mid, yEdge: .max, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    //Top Left
    func test_resizing_draggingTopLeftEdgeToTopLeftIncreasesSizeAndDecreasesOrigin() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -3, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.dragPageBy(xEdge: .min, yEdge: .min, deltaX: -3, deltaY: -4)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToBottomRightDecreasesSizeAndIncreasesOrigin() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 3, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.dragPageBy(xEdge: .min, yEdge: .min, deltaX: 3, deltaY: 4)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToTopLeftStopsAtCanvasEdge() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size = CGSize(width: expectedFrame.maxX, height: expectedFrame.maxY)
        expectedFrame.origin = CGPoint(x: 20, y: 20)

        self.dragPageBy(xEdge: .min, yEdge: .min, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToBottomRightStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: expectedFrame.width - self.page1.minimumContentSize.width, y: expectedFrame.height - self.page1.minimumContentSize.height))
        expectedFrame.size = self.page1.minimumContentSize
        self.dragPageBy(xEdge: .min, yEdge: .min, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    //Top Right
    func test_resizing_draggingTopRightEdgeToTopRightIncreasesSizeAndDecreasesOrigin() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.dragPageBy(xEdge: .max, yEdge: .min, deltaX: 3, deltaY: -4)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToBottomLeftDecreasesSizeAndIncreasesOrigin() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.dragPageBy(xEdge: .max, yEdge: .min, deltaX: -3, deltaY: 4)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToTopRightStopsAtCanvasEdge() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size = CGSize(width: self.contentFrame.maxX - expectedFrame.minX + self.layoutEngine.contentBorder, height: expectedFrame.maxY)
        expectedFrame.origin.y = 20

        self.dragPageBy(xEdge: .max, yEdge: .min, deltaX: 100, deltaY: -100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToBottomLeftStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: expectedFrame.height - self.page1.minimumContentSize.height))
        expectedFrame.size = self.page1.minimumContentSize
        self.dragPageBy(xEdge: .max, yEdge: .min, deltaX: -100, deltaY: 100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    //Bottom Right
    func test_resizing_draggingBottomRightEdgeToBottomRightIncreasesSize() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.dragPageBy(xEdge: .max, yEdge: .max, deltaX: 3, deltaY: 4)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToTopLeftDecreasesSize() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.dragPageBy(xEdge: .max, yEdge: .max, deltaX: -3, deltaY: -4)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToBottomRightStopsAtCanvasEdge() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size = CGSize(width: self.contentFrame.maxX - expectedFrame.minX + self.layoutEngine.contentBorder, height: self.contentFrame.maxY - expectedFrame.minY + self.layoutEngine.contentBorder)

        self.dragPageBy(xEdge: .max, yEdge: .max, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToTopLeftStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size = self.page1.minimumContentSize
        self.dragPageBy(xEdge: .max, yEdge: .max, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    //Top Right
    func test_resizing_draggingBottomLeftEdgeToBottomLeftIncreasesSizeAndDecreasesOrigin() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -3, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.dragPageBy(xEdge: .min, yEdge: .max, deltaX: -3, deltaY: 4)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToTopRightDecreasesSizeAndIncreasesOrigin() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 3, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.dragPageBy(xEdge: .min, yEdge: .max, deltaX: 3, deltaY: -4)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToBottomLeftStopsAtCanvasEdge() {
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.size = CGSize(width: expectedFrame.maxX, height: self.contentFrame.maxY - expectedFrame.minY  + self.layoutEngine.contentBorder)
        expectedFrame.origin.x = 20

        self.dragPageBy(xEdge: .min, yEdge: .max, deltaX: -100, deltaY: 100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToTopRightStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.canvasFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: expectedFrame.width - self.page1.minimumContentSize.width, y: 0))
        expectedFrame.size = self.page1.minimumContentSize
        self.dragPageBy(xEdge: .min, yEdge: .max, deltaX: 100, deltaY: -100)

        XCTAssertEqual(self.page1.canvasFrame, expectedFrame)
    }


    //MARK: - Canvas Size and Offset
    func test_canvasSize_canvasSizeShouldEqualContentBoundsPlusCanvasBorderOnEachSize() {
        XCTAssertEqual(self.layoutEngine.canvasSize, self.contentFrame.insetBy(dx: -20, dy: -20).size)
    }

    func test_canvasSize_canvasSizeShouldBeBiggerThanContentBoundsPlusCanvasBorderIfViewPortFrameIsOutside() {
        class TestCanvasView: CanvasLayoutView {
            func layoutChanged(with context: CanvasLayoutEngine.LayoutContext) {}
            var viewPortFrame: CGRect = .zero
        }

        let testCanvas = TestCanvasView()
        testCanvas.viewPortFrame = CGRect(x: 60, y: 60, width: 80, height: 80)
        self.layoutEngine.view = testCanvas

        self.dragPageBy(xEdge: .min, yEdge: .min, deltaX: 0, deltaY: 0)

        let borderedContentFrame = self.contentFrame.insetBy(dx: -20, dy: -20)
        let fullFrame = borderedContentFrame.union(testCanvas.viewPortFrame)
        XCTAssertEqual(self.layoutEngine.canvasSize, fullFrame.size)
    }

    func test_canvasSize_pageSpaceOffsetShouldChangeIfCanvasGrowsUpwards() {
        let initialOffset = self.layoutEngine.convertPointToPageSpace(.zero)

        let pageOrigin = self.page2.canvasFrame
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

        let pageOrigin = self.page2.canvasFrame
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
        let pageOrigin = self.page2.canvasFrame
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
        let pageOrigin = self.page2.canvasFrame
        let startPoint = CGPoint(x: pageOrigin.minX, y: pageOrigin.midY)
        let endPoint = startPoint.plus(CGPoint(x: -20, y: 0))

        self.layoutEngine.downEvent(at: startPoint)
        XCTAssertEqual(self.layoutEngine.canvasSize, initialSize)
        self.layoutEngine.draggedEvent(at: endPoint)
        XCTAssertEqual(self.layoutEngine.canvasSize, initialSize)
        self.layoutEngine.upEvent(at: endPoint)
        XCTAssertNotEqual(self.layoutEngine.canvasSize, initialSize)
    }

    func test_canvasSize_canvasSizeShouldShrinkIfNecessaryWhenScrollingEnds() {
//        XCTFail()
    }

    func test_canvasSize_updatesAllPagesCanvasFrameIfCanvasResizesUpAndToTheLeft() {
        let page1Origin = self.page1.canvasFrame.origin
        let page3Origin = self.page3.canvasFrame.origin

        let pageOrigin = self.page2.canvasFrame
        let startPoint = CGPoint(x: pageOrigin.midX, y: pageOrigin.minY + 3)
        let endPoint = startPoint.plus(CGPoint(x: -10, y: -30))

        self.layoutEngine.downEvent(at: startPoint)
        self.layoutEngine.draggedEvent(at: endPoint)
        self.layoutEngine.upEvent(at: endPoint)

        XCTAssertEqual(self.page1.canvasFrame.origin, page1Origin.plus(CGPoint(x: 10, y: 20)))
        XCTAssertEqual(self.page2.canvasFrame.origin, CGPoint(x: self.layoutEngine.contentBorder, y: self.layoutEngine.contentBorder))
        XCTAssertEqual(self.page3.canvasFrame.origin, page3Origin.plus(CGPoint(x: 10, y: 20)))
    }

    func test_canvasSize_doesNOTUpdatePagesCanvasFrameIfCanvasResizesDownToTheLeft() {
        let page1Origin = self.page1.canvasFrame.origin
        let page2Origin = self.page2.canvasFrame.origin
        let page3Origin = self.page3.canvasFrame.origin

        let pageOrigin = self.page1.canvasFrame
        let startPoint = CGPoint(x: pageOrigin.midX, y: pageOrigin.minY + 3)
        let endPoint = startPoint.plus(CGPoint(x: 10, y: 20))

        self.layoutEngine.downEvent(at: startPoint)
        self.layoutEngine.draggedEvent(at: endPoint)
        self.layoutEngine.upEvent(at: endPoint)

        XCTAssertEqual(self.page1.canvasFrame.origin, page1Origin.plus(CGPoint(x: 10, y: 20)))
        XCTAssertEqual(self.page2.canvasFrame.origin, page2Origin)
        XCTAssertEqual(self.page3.canvasFrame.origin, page3Origin)
    }

}
