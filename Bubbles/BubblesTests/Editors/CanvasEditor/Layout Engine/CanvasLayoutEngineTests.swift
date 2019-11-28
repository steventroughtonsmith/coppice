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

class CanvasLayoutEngineTests: XCTestCase {

    var layoutEngine: CanvasLayoutEngine!
    var page1: LayoutEnginePage!
    var page2: LayoutEnginePage!
    var page3: LayoutEnginePage!
    var contentFrame: CGRect = .zero
    var expectedOffset: CGPoint!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        self.layoutEngine = CanvasLayoutEngine(configuration: .init(pageTitleHeight: 5,
                                                                    pageResizeEdgeHandleSize: 1,
                                                                    pageResizeCornerHandleSize: 1,
                                                                    pageResizeHandleOffset: 0,
                                                                    contentBorder: 20,
                                                                    arrowWidth: 5))

        self.page1 = self.layoutEngine.addPage(withID: UUID(),
                                               contentFrame: CGRect(x: 40, y: 40, width: 10, height: 10),
                                               minimumContentSize: CGSize(width: 0, height: 0))

        self.page2 = self.layoutEngine.addPage(withID: UUID(),
                                               contentFrame: CGRect(x: -30, y: -20, width: 20, height: 40),
                                               minimumContentSize: CGSize(width: 0, height: 0))

        self.page3 = self.layoutEngine.addPage(withID: UUID(),
                                               contentFrame: CGRect(x: 30, y: -30, width: 30, height: 20),
                                               minimumContentSize: CGSize(width: 0, height: 0))

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
        let page = self.layoutEngine.addPage(withID: UUID(),
                                             contentFrame: CGRect(x: 0, y: 1, width: 2, height: 3),
                                             minimumContentSize: CGSize(width: 4, height: 5),
                                             parentID: UUID())
        XCTAssertTrue(self.layoutEngine.pages.contains(page))
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
        class TestCanvasView: CanvasLayoutView {
            var context: CanvasLayoutEngine.LayoutContext?
            func layoutChanged(with context: CanvasLayoutEngine.LayoutContext) {
                self.context = context
            }
            var viewPortFrame: CGRect = CGRect(x: 50, y: 50, width: 10, height: 10)
        }

        let view = TestCanvasView()
        self.layoutEngine.view = view
        self.layoutEngine.updateContentFrame(CGRect(x: -20, y: -10, width: 20, height: 40), ofPageWithID: self.page2.id)

        let expectedContext = CanvasLayoutEngine.LayoutContext(sizeChanged: true, pageOffsetChange: CGPoint(x: -10, y: 0))
        XCTAssertEqual(view.context, expectedContext)
    }

    func test_updateFrame_doesntUpdateLayoutIfFrameHasNotChanged() {
        class TestCanvasView: CanvasLayoutView {
            var context: CanvasLayoutEngine.LayoutContext?
            func layoutChanged(with context: CanvasLayoutEngine.LayoutContext) {
                self.context = context
            }
            var viewPortFrame: CGRect = CGRect(x: 50, y: 50, width: 10, height: 10)
        }

        let view = TestCanvasView()
        self.layoutEngine.view = view
        self.layoutEngine.updateContentFrame(CGRect(x: -30, y: -20, width: 20, height: 40), ofPageWithID: self.page2.id)

        XCTAssertNil(view.context)
    }


    //MARK: - Page Children
    func test_allChildren_returnsEmptyArrayIfSuppliedPageHasNoChildren() {
        //Add child to other page just to be sure
        self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: self.page1.id)
        XCTAssertEqual(self.layoutEngine.allChildren(of: self.page2), [])
    }

    func test_allChildren_returnsPagesThatHaveSuppliedPageAsParentID() {
        //Add child to other page just to be sure
        self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: self.page2.id)

        let child1 = self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: self.page1.id)
        let child2 = self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: self.page1.id)

        let children = self.layoutEngine.allChildren(of: self.page1)
        XCTAssertEqual(children.count, 2)
        XCTAssertTrue(children.contains(child1))
        XCTAssertTrue(children.contains(child2))
    }

    func test_allChildren_returnsAllChildrenGrandChildrenEtcOfSuppliedPage() {
        //Add child to other page just to be sure
        self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: self.page2.id)

        let child1 = self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: self.page3.id)
        let child2 = self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: self.page3.id)
        let grandchild1 = self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: child1.id)
        let grandchild2 = self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: child2.id)
        let grandchild3 = self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: child2.id)
        let greatGrandchild1 = self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: grandchild1.id)
        let greatGrandchild2 = self.layoutEngine.addPage(withID: UUID(), contentFrame: .zero, minimumContentSize: .zero, parentID: grandchild1.id)

        let children = self.layoutEngine.allChildren(of: self.page3)
        XCTAssertEqual(children.count, 7)
        XCTAssertTrue(children.contains(child1))
        XCTAssertTrue(children.contains(child2))
        XCTAssertTrue(children.contains(grandchild1))
        XCTAssertTrue(children.contains(grandchild2))
        XCTAssertTrue(children.contains(grandchild3))
        XCTAssertTrue(children.contains(greatGrandchild1))
        XCTAssertTrue(children.contains(greatGrandchild2))
    }


    //MARK: - Point Conversion
    func test_pointConversion_convertsPointFromPageSpaceToCanvasSpaceForEmptyEngine() {
        let basePoint = CGPoint(x: 10, y: 42)

        let emptyEngine = CanvasLayoutEngine(configuration: .init(pageTitleHeight: 5,
                                                                  pageResizeEdgeHandleSize: 1,
                                                                  pageResizeCornerHandleSize: 1,
                                                                  pageResizeHandleOffset: 0,
                                                                  contentBorder: 20,
                                                                  arrowWidth: 5))
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

        let emptyEngine = CanvasLayoutEngine(configuration: .init(pageTitleHeight: 5,
                                                                  pageResizeEdgeHandleSize: 1,
                                                                  pageResizeCornerHandleSize: 1,
                                                                  pageResizeHandleOffset: 0,
                                                                  contentBorder: 20,
                                                                  arrowWidth: 5))
        let expectedPoint = basePoint
        XCTAssertEqual(emptyEngine.convertPointToPageSpace(basePoint), expectedPoint)
    }

    func test_pointConversion_convertsPointFromCanvasSpaceToPageSpace() {
        let basePoint = CGPoint(x: 65, y: 81)

        let expectedPoint = basePoint.minus(self.expectedOffset)
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
        class TestCanvasView: CanvasLayoutView {
            var selectionChanged: Bool?
            func layoutChanged(with context: CanvasLayoutEngine.LayoutContext) {
                self.selectionChanged = context.selectionChanged
            }
            var viewPortFrame: CGRect = .zero
        }

        let testCanvas = TestCanvasView()
        self.layoutEngine.view = testCanvas

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)
        self.layoutEngine.downEvent(at: self.page1.layoutFrame.origin.plus(.identity))
        XCTAssertFalse(try XCTUnwrap(testCanvas.selectionChanged))
        self.layoutEngine.draggedEvent(at: self.page1.layoutFrame.origin.plus(.identity))
        XCTAssertFalse(try XCTUnwrap(testCanvas.selectionChanged))
        self.layoutEngine.upEvent(at: self.page1.layoutFrame.origin.plus(.identity))
        XCTAssertTrue(try XCTUnwrap(testCanvas.selectionChanged))
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
        class TestCanvasView: CanvasLayoutView {
            var selectionChanged: Bool?
            func layoutChanged(with context: CanvasLayoutEngine.LayoutContext) {
                self.selectionChanged = context.selectionChanged
            }
            var viewPortFrame: CGRect = .zero
        }

        let testCanvas = TestCanvasView()
        self.layoutEngine.view = testCanvas

        self.layoutEngine.downEvent(at: CGPoint(x: 10, y: 10))
        XCTAssertFalse(try XCTUnwrap(testCanvas.selectionChanged))
        self.layoutEngine.draggedEvent(at: CGPoint(x: 85, y: 35))
        XCTAssertFalse(try XCTUnwrap(testCanvas.selectionChanged))
        self.layoutEngine.upEvent(at: CGPoint(x: 85, y: 35))
        XCTAssertTrue(try XCTUnwrap(testCanvas.selectionChanged))
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

        let page3Point = self.page3.layoutFrame.origin

        let offset = CGPoint(x: 7, y: 8)

        self.layoutEngine.downEvent(at: page3Point.plus(.identity))
        self.layoutEngine.draggedEvent(at: page3Point.plus(.identity).plus(offset))
        self.layoutEngine.upEvent(at: page3Point.plus(.identity).plus(offset))

        XCTAssertTrue(try XCTUnwrap(delegate.movedPages?[safe: 0]) === self.page2)
        XCTAssertTrue(try XCTUnwrap(delegate.movedPages?[safe: 1]) === self.page3)
    }

    func test_moving_downEventWithCount2SelectsAllChildPages() {
        let child1 = self.layoutEngine.addPage(withID: UUID(),
                                               contentFrame: CGRect(x: 120, y: 120, width: 30, height: 30),
                                               minimumContentSize: .zero,
                                               parentID: self.page1.id)
        let child2 = self.layoutEngine.addPage(withID: UUID(),
                                               contentFrame: CGRect(x: 150, y: 180, width: 30, height: 30),
                                               minimumContentSize: .zero,
                                               parentID: self.page1.id)

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

    func dragPageBy(xEdge: TestDragEdge, yEdge: TestDragEdge, deltaX: CGFloat, deltaY: CGFloat) {
        let startX: CGFloat
        switch (xEdge) {
        case .min:
            startX = self.page1.layoutFrame.minX
        case .mid:
            startX = self.page1.layoutFrame.midX
        case .max:
            startX = self.page1.layoutFrame.maxX - 1
        }

        let startY: CGFloat
        switch (yEdge) {
        case .min:
            startY = self.page1.layoutFrame.minY
        case .mid:
            startY = self.page1.layoutFrame.midY
        case .max:
            startY = self.page1.layoutFrame.maxY - 1
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

        self.dragPageBy(xEdge: .min, yEdge: .mid, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingLeftEdgeToRightDecreasesWidthAndIncreasesOriginX() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.x += 2
        expectedFrame.size.width -= 2

        self.dragPageBy(xEdge: .min, yEdge: .mid, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingLeftEdgeToLeftStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width += expectedFrame.origin.x
        expectedFrame.origin.x = 20

        self.dragPageBy(xEdge: .min, yEdge: .mid, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingLeftEdgeToRightStopsAtMinimumWidth() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.x += expectedFrame.width - self.page1.minimumContentSize.width
        expectedFrame.size.width = self.page1.minimumContentSize.width

        self.dragPageBy(xEdge: .min, yEdge: .mid, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top
    func test_resizing_draggingTopEdgeUpIncreasesHeightAndDecreasesOriginY() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.y -= 2
        expectedFrame.size.height += 2

        self.dragPageBy(xEdge: .mid, yEdge: .min, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopEdgeDownDecreasesHeightAndIncreasesOriginY() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.y += 2
        expectedFrame.size.height -= 2

        self.dragPageBy(xEdge: .mid, yEdge: .min, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopEdgeUpStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height += expectedFrame.origin.y
        expectedFrame.origin.y = 20

        self.dragPageBy(xEdge: .mid, yEdge: .min, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopEdgeDownStopsAtMinimumHeight() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.y += expectedFrame.height - self.page1.minimumLayoutSize.height
        expectedFrame.size.height = self.page1.minimumLayoutSize.height

        self.dragPageBy(xEdge: .mid, yEdge: .min, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Right
    func test_resizing_draggingRightEdgeToRightIncreasesWidth() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width += 2

        self.dragPageBy(xEdge: .max, yEdge: .mid, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingRightEdgeToLeftDecreasesWidth() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width -= 2

        self.dragPageBy(xEdge: .max, yEdge: .mid, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingRightEdgeToRightStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width += self.contentFrame.maxX - expectedFrame.maxX + self.layoutEngine.configuration.contentBorder

        self.dragPageBy(xEdge: .max, yEdge: .mid, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingRightEdgeToLeftStopsAtMinimumWidth() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width = self.page1.minimumContentSize.width

        self.dragPageBy(xEdge: .max, yEdge: .mid, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Bottom
    func test_resizing_draggingBottomEdgeDownIncreasesHeight() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height += 2

        self.dragPageBy(xEdge: .mid, yEdge: .max, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomEdgeUpDecreasesHeight() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height -= 2

        self.dragPageBy(xEdge: .mid, yEdge: .max, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomEdgeDownStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height += self.contentFrame.maxY - expectedFrame.maxY + self.layoutEngine.configuration.contentBorder

        self.dragPageBy(xEdge: .mid, yEdge: .max, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomEdgeUpStopsAtMinimumHeight() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height = self.page1.minimumLayoutSize.height

        self.dragPageBy(xEdge: .mid, yEdge: .max, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top Left
    func test_resizing_draggingTopLeftEdgeToTopLeftIncreasesSizeAndDecreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -3, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.dragPageBy(xEdge: .min, yEdge: .min, deltaX: -3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToBottomRightDecreasesSizeAndIncreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 3, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.dragPageBy(xEdge: .min, yEdge: .min, deltaX: 3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToTopLeftStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: expectedFrame.maxX, height: expectedFrame.maxY)
        expectedFrame.origin = CGPoint(x: 20, y: 20)

        self.dragPageBy(xEdge: .min, yEdge: .min, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToBottomRightStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: expectedFrame.width - self.page1.minimumLayoutSize.width, y: expectedFrame.height - self.page1.minimumLayoutSize.height))
        expectedFrame.size = self.page1.minimumLayoutSize
        self.dragPageBy(xEdge: .min, yEdge: .min, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top Right
    func test_resizing_draggingTopRightEdgeToTopRightIncreasesSizeAndDecreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.dragPageBy(xEdge: .max, yEdge: .min, deltaX: 3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToBottomLeftDecreasesSizeAndIncreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.dragPageBy(xEdge: .max, yEdge: .min, deltaX: -3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToTopRightStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: self.contentFrame.maxX - expectedFrame.minX + self.layoutEngine.configuration.contentBorder, height: expectedFrame.maxY)
        expectedFrame.origin.y = 20

        self.dragPageBy(xEdge: .max, yEdge: .min, deltaX: 100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToBottomLeftStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: expectedFrame.height - self.page1.minimumLayoutSize.height))
        expectedFrame.size = self.page1.minimumLayoutSize
        self.dragPageBy(xEdge: .max, yEdge: .min, deltaX: -100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Bottom Right
    func test_resizing_draggingBottomRightEdgeToBottomRightIncreasesSize() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.dragPageBy(xEdge: .max, yEdge: .max, deltaX: 3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToTopLeftDecreasesSize() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.dragPageBy(xEdge: .max, yEdge: .max, deltaX: -3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToBottomRightStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: self.contentFrame.maxX - expectedFrame.minX + self.layoutEngine.configuration.contentBorder, height: self.contentFrame.maxY - expectedFrame.minY + self.layoutEngine.configuration.contentBorder)

        self.dragPageBy(xEdge: .max, yEdge: .max, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToTopLeftStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = self.page1.minimumLayoutSize
        self.dragPageBy(xEdge: .max, yEdge: .max, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top Right
    func test_resizing_draggingBottomLeftEdgeToBottomLeftIncreasesSizeAndDecreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -3, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        self.dragPageBy(xEdge: .min, yEdge: .max, deltaX: -3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToTopRightDecreasesSizeAndIncreasesOrigin() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 3, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        self.dragPageBy(xEdge: .min, yEdge: .max, deltaX: 3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToBottomLeftStopsAtCanvasEdge() {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: expectedFrame.maxX, height: self.contentFrame.maxY - expectedFrame.minY  + self.layoutEngine.configuration.contentBorder)
        expectedFrame.origin.x = 20

        self.dragPageBy(xEdge: .min, yEdge: .max, deltaX: -100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToTopRightStopsAtMinimumSize() {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: expectedFrame.width - self.page1.minimumLayoutSize.width, y: 0))
        expectedFrame.size = self.page1.minimumLayoutSize
        self.dragPageBy(xEdge: .min, yEdge: .max, deltaX: 100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
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


    //MARK: - Config
    func test_config_increasesLayoutFrameOffsetFromContentForTitleHeight() {
        let config = CanvasLayoutEngine.Configuration(pageTitleHeight: 15,
                                                      pageResizeEdgeHandleSize: 0,
                                                      pageResizeCornerHandleSize: 0,
                                                      pageResizeHandleOffset: 0,
                                                      contentBorder: 20,
                                                      arrowWidth: 5)
        XCTAssertEqual(config.layoutFrameOffsetFromContent, .init(left: 0, top: 15, right: 0, bottom: 0))
    }

    func test_config_doesntIncreaseMarginsForResizeHandlesIfOffset0() {
        let config = CanvasLayoutEngine.Configuration(pageTitleHeight: 0,
                                                      pageResizeEdgeHandleSize: 4,
                                                      pageResizeCornerHandleSize: 4,
                                                      pageResizeHandleOffset: 0,
                                                      contentBorder: 20,
                                                      arrowWidth: 5)
        XCTAssertEqual(config.layoutFrameOffsetFromContent, .zero)
    }

    func test_config_increasesLayoutFrameOffsetFromContentForResizeHandlesByOffset() {
        let config = CanvasLayoutEngine.Configuration(pageTitleHeight: 0,
                                                      pageResizeEdgeHandleSize: 4,
                                                      pageResizeCornerHandleSize: 8,
                                                      pageResizeHandleOffset: 3,
                                                      contentBorder: 20,
                                                      arrowWidth: 5)
        XCTAssertEqual(config.layoutFrameOffsetFromContent, .init(left: 3, top: 3, right: 3, bottom: 3))
    }

    func test_config_increaseLayoutFrameOffsetFromContentToAccountForTitleAndResizeHandleOffset() {
        let config = CanvasLayoutEngine.Configuration(pageTitleHeight: 42,
                                                      pageResizeEdgeHandleSize: 16,
                                                      pageResizeCornerHandleSize: 31,
                                                      pageResizeHandleOffset: 8,
                                                      contentBorder: 20,
                                                      arrowWidth: 5)
        XCTAssertEqual(config.layoutFrameOffsetFromContent, .init(left: 8, top: 50, right: 8, bottom: 8))
    }

    func test_config_visibleFrameInsetsIsZeroIfHandleOffsetIsZero() {
        let config = CanvasLayoutEngine.Configuration(pageTitleHeight: 12,
                                                      pageResizeEdgeHandleSize: 13,
                                                      pageResizeCornerHandleSize: 14,
                                                      pageResizeHandleOffset: 0,
                                                      contentBorder: 20,
                                                      arrowWidth: 5)
        XCTAssertEqual(config.visibleFrameInset, .zero)
    }

    func test_config_visibleFrameInsetOnlyTakesResizeHandleOffsetIntoAccountRegardlessOfTitleHeight() {
        let config = CanvasLayoutEngine.Configuration(pageTitleHeight: 31,
                                                      pageResizeEdgeHandleSize: 32,
                                                      pageResizeCornerHandleSize: 33,
                                                      pageResizeHandleOffset: 16,
                                                      contentBorder: 20,
                                                      arrowWidth: 5)
        XCTAssertEqual(config.visibleFrameInset, .init(left: 16, top: 16, right: 16, bottom: 16))
    }


    //MARK: - Arrows
    func arrowBetweenPage(at page1Origin: CGPoint, andPageAt page2Origin: CGPoint, arrowWidth: CGFloat) -> LayoutEngineArrow? {
        let layoutEngine = CanvasLayoutEngine(configuration: .init(pageTitleHeight: 0,
                                                                   pageResizeEdgeHandleSize: 0,
                                                                   pageResizeCornerHandleSize: 0,
                                                                   pageResizeHandleOffset: 0,
                                                                   contentBorder: 0,
                                                                   arrowWidth: arrowWidth))

        let page1 = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(origin: page1Origin, size: CGSize(width: 20, height: 20)), minimumContentSize: .zero)
        layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(origin: page2Origin, size: CGSize(width: 20, height: 20)), minimumContentSize: .zero, parentID: page1.id)
        return layoutEngine.arrows.first
    }


    func test_arrows_addingPageWithParentAddsArrowBetweenPages() throws {
        XCTAssertEqual(self.layoutEngine.arrows.count, 0)
        let page = self.layoutEngine.addPage(withID: UUID(),
                                             contentFrame: CGRect(x: 0, y: 0, width: 20, height: 20),
                                             minimumContentSize: .zero,
                                             parentID: self.page1.id)

        XCTAssertEqual(self.layoutEngine.arrows.count, 1)
        let arrow = try XCTUnwrap(self.layoutEngine.arrows.first)
        XCTAssertEqual(arrow.childID, page.id)
        XCTAssertEqual(arrow.parentID, self.page1.id)

    }

    func test_arrows_childDirectlyToRightOfParentHasStraightLineOfArrowWidthSizeBetweenCentres() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: 40, y: 0), arrowWidth: 5))
        //We remove 2 from the centre as our 5pt line is centred on 10, 10, so we want to start (width-1)/2 away. Same for increasing the width
        XCTAssertEqual(arrow.frame, CGRect(x: 8, y: 8, width: 44, height: 5))
    }

    func test_arrows_childDirectlyToRightOfParentHasMaxHorizontalAndMinVerticalDirections() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: 40, y: 0), arrowWidth: 5))
        XCTAssertEqual(arrow.horizontalDirection, .maxEdge)
        XCTAssertEqual(arrow.verticalDirection, .minEdge)
    }

    func test_arrows_childDirectlyToLeftOfParentHasStraightLineOfArrowWidthSizeBetweenCentres() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: -40, y: 0), arrowWidth: 5))
        //Our frame origin is the same as above as time the whole canvas has grown to the left
        XCTAssertEqual(arrow.frame, CGRect(x: 8, y: 8, width: 44, height: 5))
    }

    func test_arrows_childDirectlyToLeftOfParentHasMinHorizontalAndVerticalDirections() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: -40, y: 0), arrowWidth: 5))
        XCTAssertEqual(arrow.horizontalDirection, .minEdge)
        XCTAssertEqual(arrow.verticalDirection, .minEdge)
    }

    func test_arrows_childDirectlyAboveParentHasStraightLineOfArrowWidthSizeBetweenCentres() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: 0, y: -50), arrowWidth: 7))
        XCTAssertEqual(arrow.frame, CGRect(x: 7, y: 7, width: 7, height: 56))
    }

    func test_arrows_childDirectlyAboveParentHasMinHorizontalAndVerticalDirections() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: 0, y: -50), arrowWidth: 7))
        XCTAssertEqual(arrow.horizontalDirection, .minEdge)
        XCTAssertEqual(arrow.verticalDirection, .minEdge)
    }

    func test_arrows_childDirectlyBelowParentHasStraightLineOfArrowWidthSizeBetweenCentres() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: 0, y: 50), arrowWidth: 7))
        XCTAssertEqual(arrow.frame, CGRect(x: 7, y: 7, width: 7, height: 56))
    }

    func test_arrows_childDirectlyBelowParentHasMinHorizontalAndMaxVerticalDirections() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: 0, y: 50), arrowWidth: 7))
        XCTAssertEqual(arrow.horizontalDirection, .minEdge)
        XCTAssertEqual(arrow.verticalDirection, .maxEdge)
    }

    func test_arrows_childToTopLeftOfParentHasFrameContainingBothCentres() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: -60, y: -60), arrowWidth: 3))
        XCTAssertEqual(arrow.frame, CGRect(x: 9, y: 9, width: 62, height: 62))
    }

    func test_arrows_childToTopLeftOfParentHasMinHorizontalAndVerticalDirections() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: -60, y: -60), arrowWidth: 3))
        XCTAssertEqual(arrow.horizontalDirection, .minEdge)
        XCTAssertEqual(arrow.verticalDirection, .minEdge)
    }

    func test_arrows_childToTopRightOfParentHasFrameContainingBothCentres() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: 50, y: -60), arrowWidth: 3))
        XCTAssertEqual(arrow.frame, CGRect(x: 9, y: 9, width: 52, height: 62))
    }

    func test_arrows_childToTopRightOfParentHasMaxHorizontalAndMinVerticalDirections() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: 50, y: -60), arrowWidth: 3))
        XCTAssertEqual(arrow.horizontalDirection, .maxEdge)
        XCTAssertEqual(arrow.verticalDirection, .minEdge)
    }

    func test_arrows_childToBottomLeftOfParentHasFrameContainingBothCentres() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: -30, y: 40), arrowWidth: 3))
        XCTAssertEqual(arrow.frame, CGRect(x: 9, y: 9, width: 32, height: 42))
    }

    func test_arrows_childToBottomLeftOfParentHasMinHorizontalAndMaxVerticalDirections() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: -30, y: 40), arrowWidth: 3))
        XCTAssertEqual(arrow.horizontalDirection, .minEdge)
        XCTAssertEqual(arrow.verticalDirection, .maxEdge)
    }

    func test_arrows_childToBottomRightOfParentHasFrameContainingBothCentres() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: 45, y: 54), arrowWidth: 3))
        XCTAssertEqual(arrow.frame, CGRect(x: 9, y: 9, width: 47, height: 56))
    }

    func test_arrows_childToBottomRightOfParentHasMaxHorizontalAndVerticalDirections() throws {
        let arrow = try XCTUnwrap(self.arrowBetweenPage(at: CGPoint(x: 0, y: 0), andPageAt: CGPoint(x: 45, y: 54), arrowWidth: 3))
        XCTAssertEqual(arrow.horizontalDirection, .maxEdge)
        XCTAssertEqual(arrow.verticalDirection, .maxEdge)
    }


    //MARK: - Arrow Moving & Resizing

    func createInitialArrowModificationTestPages() -> (CanvasLayoutEngine, LayoutEnginePage, [LayoutEnginePage]) {
        let config = CanvasLayoutEngine.Configuration(pageTitleHeight: 10,
                                                      pageResizeEdgeHandleSize: 1,
                                                      pageResizeCornerHandleSize: 1,
                                                      pageResizeHandleOffset: 0,
                                                      contentBorder: 20,
                                                      arrowWidth: 5)
        let layoutEngine = CanvasLayoutEngine(configuration: config)
        let parent = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 20, height: 20), minimumContentSize: .zero, parentID: nil)
        let child1 = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 40, y: -30, width: 20, height: 20), minimumContentSize: .zero, parentID: parent.id)
        let child2 = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 30, y: 30, width: 20, height: 20), minimumContentSize: .zero, parentID: parent.id)

        return (layoutEngine, parent, [child1, child2])
    }

    func test_arrows_movingChildResizesArrow() {
        let (engine, _, children) = self.createInitialArrowModificationTestPages()

        guard let oldChild2Arrow = engine.arrows.first(where: { $0.childID == children[1].id }) else {
            XCTFail("No Arrow found for child 1")
            return
        }

        engine.downEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 35, y: 25)))
        engine.draggedEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 40, y: 20)))

        let arrowFrame = engine.arrows.first(where: { $0.childID == children[1].id })?.frame

        XCTAssertEqual(arrowFrame?.minX, oldChild2Arrow.frame.minX)
        XCTAssertEqual(arrowFrame?.minY, oldChild2Arrow.frame.minY)
        XCTAssertEqual(arrowFrame?.width, oldChild2Arrow.frame.width + 5)
        XCTAssertEqual(arrowFrame?.height, oldChild2Arrow.frame.height - 5)

        engine.upEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 40, y: 20)))
    }

    func test_arrows_movingParentResizesAllChildArrows() {
        let (engine, _, children) = self.createInitialArrowModificationTestPages()

        guard let oldChild1ArrowFrame = engine.arrows.first(where: { $0.childID == children[0].id })?.frame,
            let oldChild2ArrowFrame = engine.arrows.first(where: { $0.childID == children[1].id })?.frame else {
            XCTFail("No Arrows found for children")
                return
        }

        engine.downEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 5, y: -5)))
        engine.draggedEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 0, y: 0)))

        let child1ArrowFrame = engine.arrows.first(where: { $0.childID == children[0].id })?.frame
        XCTAssertEqual(child1ArrowFrame?.minX, oldChild1ArrowFrame.minX - 5)
        XCTAssertEqual(child1ArrowFrame?.minY, oldChild1ArrowFrame.minY)
        XCTAssertEqual(child1ArrowFrame?.width, oldChild1ArrowFrame.width + 5)
        XCTAssertEqual(child1ArrowFrame?.height, oldChild1ArrowFrame.height + 5)

        let child2ArrowFrame = engine.arrows.first(where: { $0.childID == children[1].id })?.frame
        XCTAssertEqual(child2ArrowFrame?.minX, oldChild2ArrowFrame.minX - 5)
        XCTAssertEqual(child2ArrowFrame?.minY, oldChild2ArrowFrame.minY + 5)
        XCTAssertEqual(child2ArrowFrame?.width, oldChild2ArrowFrame.width + 5)
        XCTAssertEqual(child2ArrowFrame?.height, oldChild2ArrowFrame.height - 5)

        engine.upEvent(at: engine.convertPointToCanvasSpace(.zero))
    }

    func test_arrows_resizingChildOnArrowEdgeResizesArrow() {
        let (engine, _, children) = self.createInitialArrowModificationTestPages()

        guard let oldArrowFrame = engine.arrows.first(where: { $0.childID == children[0].id }) else {
            XCTFail("No Arrow found for child 1")
            return
        }

        engine.downEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 40, y: -25)))
        engine.draggedEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 35, y: -20)))

        let arrowFrame = engine.arrows.first(where: { $0.childID == children[0].id })?.frame

        XCTAssertEqual(arrowFrame?.minX, oldArrowFrame.frame.minX)
        XCTAssertEqual(arrowFrame?.minY, oldArrowFrame.frame.minY)
        XCTAssertEqual(arrowFrame?.width, oldArrowFrame.frame.width - 2.5)
        XCTAssertEqual(arrowFrame?.height, oldArrowFrame.frame.height)

        engine.upEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 35, y: -20)))
    }

    func test_arrows_resizingChildOnNonArrowEdgeResizesArrow() {
        let (engine, _, children) = self.createInitialArrowModificationTestPages()

        guard let oldArrowFrame = engine.arrows.first(where: { $0.childID == children[1].id })?.frame else {
            XCTFail("No Arrow found for child 2")
            return
        }

        engine.downEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 49, y: 35)))
        engine.draggedEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 59, y: 30)))

        let arrowFrame = engine.arrows.first(where: { $0.childID == children[1].id })?.frame

        XCTAssertEqual(arrowFrame?.minX, oldArrowFrame.minX)
        XCTAssertEqual(arrowFrame?.minY, oldArrowFrame.minY)
        XCTAssertEqual(arrowFrame?.width, oldArrowFrame.width + 5)
        XCTAssertEqual(arrowFrame?.height, oldArrowFrame.height)

        engine.upEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 60, y: 30)))
    }

    func test_arrows_resizingParentOnArrowEdgeResizesArrow() {
        let (engine, _, children) = self.createInitialArrowModificationTestPages()

        guard let oldChild1ArrowFrame = engine.arrows.first(where: { $0.childID == children[0].id })?.frame,
            let oldChild2ArrowFrame = engine.arrows.first(where: { $0.childID == children[1].id })?.frame else {
            XCTFail("No Arrows found for children")
                return
        }

        engine.downEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 19, y: 5)))
        engine.draggedEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 24, y: 10)))

        let child1ArrowFrame = engine.arrows.first(where: { $0.childID == children[0].id })?.frame
        XCTAssertEqual(child1ArrowFrame?.minX, oldChild1ArrowFrame.minX + 2.5)
        XCTAssertEqual(child1ArrowFrame?.minY, oldChild1ArrowFrame.minY)
        XCTAssertEqual(child1ArrowFrame?.width, oldChild1ArrowFrame.width - 2.5)
        XCTAssertEqual(child1ArrowFrame?.height, oldChild1ArrowFrame.height)

        let child2ArrowFrame = engine.arrows.first(where: { $0.childID == children[1].id })?.frame
        XCTAssertEqual(child2ArrowFrame?.minX, oldChild2ArrowFrame.minX + 2.5)
        XCTAssertEqual(child2ArrowFrame?.minY, oldChild2ArrowFrame.minY)
        XCTAssertEqual(child2ArrowFrame?.width, oldChild2ArrowFrame.width - 2.5)
        XCTAssertEqual(child2ArrowFrame?.height, oldChild2ArrowFrame.height)

        engine.upEvent(at: engine.convertPointToCanvasSpace(.zero))
    }

    func test_arrows_resizingParentOnNonArrowEdgeResizesArrow() {
        let (engine, _, children) = self.createInitialArrowModificationTestPages()

        guard let oldChild1ArrowFrame = engine.arrows.first(where: { $0.childID == children[0].id })?.frame,
            let oldChild2ArrowFrame = engine.arrows.first(where: { $0.childID == children[1].id })?.frame else {
            XCTFail("No Arrows found for children")
                return
        }

        engine.downEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: 0, y: 5)))
        engine.draggedEvent(at: engine.convertPointToCanvasSpace(CGPoint(x: -10, y: 10)))

        let child1ArrowFrame = engine.arrows.first(where: { $0.childID == children[0].id })?.frame
        XCTAssertEqual(child1ArrowFrame?.minX, oldChild1ArrowFrame.minX - 5)
        XCTAssertEqual(child1ArrowFrame?.minY, oldChild1ArrowFrame.minY)
        XCTAssertEqual(child1ArrowFrame?.width, oldChild1ArrowFrame.width + 5)
        XCTAssertEqual(child1ArrowFrame?.height, oldChild1ArrowFrame.height)

        let child2ArrowFrame = engine.arrows.first(where: { $0.childID == children[1].id })?.frame
        XCTAssertEqual(child2ArrowFrame?.minX, oldChild2ArrowFrame.minX - 5)
        XCTAssertEqual(child2ArrowFrame?.minY, oldChild2ArrowFrame.minY)
        XCTAssertEqual(child2ArrowFrame?.width, oldChild2ArrowFrame.width + 5)
        XCTAssertEqual(child2ArrowFrame?.height, oldChild2ArrowFrame.height)

        engine.upEvent(at: engine.convertPointToCanvasSpace(.zero))
    }
}
