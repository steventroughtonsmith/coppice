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

//Need to move events out one by one
//Need to add new tests that check layout engine calls eventContextFactory
//Need to add new tests that check layout engine calls context returned from context factory
//Need to add new test case that tests the standard factory



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
    func test_addPage_addsPageWithSuppliedValuesToPagesArray() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 1, width: 2, height: 3),
                                    minimumContentSize: CGSize(width: 4, height: 5))
        self.layoutEngine.add([page])
        XCTAssertTrue(self.layoutEngine.pages.contains(page))
    }

    func test_addPage_setsLayoutEngineOfSuppliedPages() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 1, width: 2, height: 3),
                                    minimumContentSize: CGSize(width: 4, height: 5))
        self.layoutEngine.add([page])
        XCTAssertTrue(page.layoutEngine === self.layoutEngine)
    }

    func test_removePages_removesSuppliedPagesFromPagesArray() throws {
        XCTAssertTrue(self.layoutEngine.pages.contains(self.page1))
        XCTAssertTrue(self.layoutEngine.pages.contains(self.page3))

        self.layoutEngine.remove([self.page1, self.page3])

        XCTAssertFalse(self.layoutEngine.pages.contains(self.page1))
        XCTAssertTrue(self.layoutEngine.pages.contains(self.page2))
        XCTAssertFalse(self.layoutEngine.pages.contains(self.page3))
    }


    //MARK: - Updating Pages
    func test_updateFrame_updatesTheFrameOfPageWithSuppliedUUID() throws {
        let expectedContentFrame = CGRect(x: 35, y: 35, width: 20, height: 20)
        self.layoutEngine.updateContentFrame(expectedContentFrame, ofPageWithID: self.page1.id)
        XCTAssertEqual(self.page1.contentFrame, expectedContentFrame)
    }

    func test_updateFrame_updatesCanvasSizeIfNewFrameChangesSize() throws {
        let expectedCanvasSize = self.layoutEngine.canvasSize.plus(CGSize(width: 10, height: 10))
        self.layoutEngine.updateContentFrame(CGRect(x: 30, y: -40, width: 40, height: 20), ofPageWithID: self.page3.id)
        XCTAssertEqual(self.layoutEngine.canvasSize, expectedCanvasSize)
    }

    func test_updateFrame_notifiesViewOfLayoutChange() throws {
        let view = TestCanvasView()
        view.viewPortFrame = CGRect(x: 50, y: 50, width: 10, height: 10)
        self.layoutEngine.view = view
        self.layoutEngine.updateContentFrame(CGRect(x: -20, y: -10, width: 20, height: 40), ofPageWithID: self.page2.id)

        let expectedContext = CanvasLayoutEngine.LayoutContext(sizeChanged: true, pageOffsetChange: CGPoint(x: -10, y: 0))
        XCTAssertEqual(view.context, expectedContext)
    }

    func test_updateFrame_doesntUpdateLayoutIfFrameHasNotChanged() throws {
        let view = TestCanvasView()
        view.viewPortFrame = CGRect(x: 50, y: 50, width: 10, height: 10)
        self.layoutEngine.view = view
        self.layoutEngine.updateContentFrame(CGRect(x: -30, y: -20, width: 20, height: 40), ofPageWithID: self.page2.id)

        XCTAssertNil(view.context)
    }


    //MARK: - Point Conversion
    func test_pointConversion_convertsPointFromPageSpaceToCanvasSpaceForEmptyEngine() throws {
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

    func test_pointConversion_convertsPointFromPageSpaceToCanvasSpace() throws {
        let basePoint = CGPoint(x: 10, y: 42)

        let expectedPoint = basePoint.plus(self.expectedOffset)
        XCTAssertEqual(self.layoutEngine.convertPointToCanvasSpace(basePoint), expectedPoint)
    }

    func test_pointConversion_convertsPointFromCanvasSpaceToPageSpaceForEmptyEngine() throws {
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

    func test_pointConversion_convertsPointFromCanvasSpaceToPageSpace() throws {
        let basePoint = CGPoint(x: 65, y: 81)

        let expectedPoint = basePoint.minus(self.expectedOffset)
        XCTAssertEqual(self.layoutEngine.convertPointToPageSpace(basePoint), expectedPoint)
    }


    //MARK: - selectAll()
    func test_selectAll_selectsAllPagesIfNoneWereSelected() throws {
        self.layoutEngine.selectAll()
        XCTAssertTrue(self.page1.selected)
        XCTAssertTrue(self.page2.selected)
        XCTAssertTrue(self.page3.selected)
    }

    func test_selectAll_selectsAllPagesEvenIfSomeWereAlreadySelected() throws {
        self.page2.selected = true
        self.layoutEngine.selectAll()
        XCTAssertTrue(self.page1.selected)
        XCTAssertTrue(self.page2.selected)
        XCTAssertTrue(self.page3.selected)
    }

    func test_selectAll_doesntChangeSelectionIfAllWereAlreadySelected() throws {
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.selectAll()
        XCTAssertTrue(self.page1.selected)
        XCTAssertTrue(self.page2.selected)
        XCTAssertTrue(self.page3.selected)
    }

    func test_selectAll_updatesTheEnabledPage() throws {
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
    func test_deselectAll_deselectsAllPagesIfAllWereSelected() throws {
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.deselectAll()
        XCTAssertFalse(self.page1.selected)
        XCTAssertFalse(self.page2.selected)
        XCTAssertFalse(self.page3.selected)
    }

    func test_deselectAll_deselectsAllPagesIfSomeWereSelected() throws {
        self.page1.selected = true
        self.page3.selected = true
        self.layoutEngine.deselectAll()
        XCTAssertFalse(self.page1.selected)
        XCTAssertFalse(self.page2.selected)
        XCTAssertFalse(self.page3.selected)
    }

    func test_deselectAll_doesntChangeSelectionIfNoneWereAlreadySelected() throws {
        self.layoutEngine.deselectAll()
        XCTAssertFalse(self.page1.selected)
        XCTAssertFalse(self.page2.selected)
        XCTAssertFalse(self.page3.selected)
    }

    func test_deselectAll_updatesTheEnabledPage() throws {
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
    func test_enabledPage_isNilWhenNoPageSelected() throws {
        self.layoutEngine.finishedModifying([])

        XCTAssertNil(self.layoutEngine.enabledPage)
    }

    func test_enabledPage_isSetToSelectedPageIfSinglePageSelected() throws {
        self.page2.selected = true
        self.layoutEngine.finishedModifying([])

        XCTAssertEqual(self.layoutEngine.enabledPage, self.page2)
    }

    func test_enabledPage_isNilIfMultiplePagesSelected() throws {
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.finishedModifying([])

        XCTAssertNil(self.layoutEngine.enabledPage)
    }

    func test_enabledPage_isSetToSelectedPageIfAllOtherPagesAreDeselected() throws {
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.finishedModifying([])
        XCTAssertNil(self.layoutEngine.enabledPage)

        self.page2.selected = false
        self.layoutEngine.finishedModifying([])
        XCTAssertEqual(self.layoutEngine.enabledPage, self.page3)
    }


    //MARK: - Move Pages




    //MARK: - Resize Page

    enum TestDragEdge {
        case min
        case mid
        case max
    }




    //MARK: - Accessibility Resize
    func test_accessibilityResize_topLeft_regularUnboundedResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -5, y: 0), on: .resizeTopLeft, expectingFrameChange: (-5, 0, 5, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -5, y: 0))
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 5, y: 0), on: .resizeTopLeft, expectingFrameChange: (5, 0, -5, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 5, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -5), on: .resizeTopLeft, expectingFrameChange: (0, -5, 0, 5))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -5))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 5), on: .resizeTopLeft, expectingFrameChange: (0, 5, 0, -5))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 5))
    }

    func test_accessibilityResize_topLeft_regularMinResize() throws {
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 20, y: 0), on: .resizeTopLeft, expectingFrameChange: (10, 0, -10, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 10, y: 0))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 40), on: .resizeTopLeft, expectingFrameChange: (0, 30, 0, -30))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 30))
    }

    func test_accessibilityResize_topRight_regularUnboundedResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -5, y: 0), on: .resizeTopRight, expectingFrameChange: (0, 0, -5, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -5, y: 0))
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 5, y: 0), on: .resizeTopRight, expectingFrameChange: (0, 0, 5, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 5, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -5), on: .resizeTopRight, expectingFrameChange: (0, -5, 0, 5))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -5))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 5), on: .resizeTopRight, expectingFrameChange: (0, 5, 0, -5))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 5))
    }

    func test_accessibilityResize_topRight_regularMinResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -20, y: 0), on: .resizeTopRight, expectingFrameChange: (0, 0, -10, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -10, y: 0))

        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 40), on: .resizeTopRight, expectingFrameChange: (0, 30, 0, -30))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 30))
    }

    func test_accessibilityResize_bottomRight_regularUnboundedResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -5, y: 0), on: .resizeBottomRight, expectingFrameChange: (0, 0, -5, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -5, y: 0))
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 5, y: 0), on: .resizeBottomRight, expectingFrameChange: (0, 0, 5, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 5, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -5), on: .resizeBottomRight, expectingFrameChange: (0, 0, 0, -5))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -5))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 5), on: .resizeBottomRight, expectingFrameChange: (0, 0, 0, 5))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 5))
    }

    func test_accessibilityResize_bottomRight_regularMinResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -20, y: 0), on: .resizeBottomRight, expectingFrameChange: (0, 0, -10, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -10, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -40), on: .resizeBottomRight, expectingFrameChange: (0, 0, 0, -30))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -30))
    }

    func test_accessibilityResize_bottomLeft_regularUnboundedResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -5, y: 0), on: .resizeBottomLeft, expectingFrameChange: (-5, 0, 5, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -5, y: 0))
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 5, y: 0), on: .resizeBottomLeft, expectingFrameChange: (5, 0, -5, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 5, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -5), on: .resizeBottomLeft, expectingFrameChange: (0, 0, 0, -5))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -5))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 5), on: .resizeBottomLeft, expectingFrameChange: (0, 0, 0, 5))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 5))
    }

    func test_accessibilityResize_bottomLeft_regularMinResize() throws {
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 20, y: 0), on: .resizeBottomLeft, expectingFrameChange: (10, 0, -10, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 10, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -40), on: .resizeBottomLeft, expectingFrameChange: (0, 0, 0, -30))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -30))
    }

    func test_accessibilityResize_topLeft_aspectUnboundedResize() throws {
        //Aspect doesn't resize horizontally
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -4, y: 0), on: .resizeTopLeft, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(minusXPoint, .zero)
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 4, y: 0), on: .resizeTopLeft, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(plusXPoint, .zero)
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -4), on: .resizeTopLeft, maintainAspectRatio: true, expectingFrameChange: (-2, -4, 2, 4))
        XCTAssertEqual(minusYPoint, CGPoint(x: -2, y: -4))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 4), on: .resizeTopLeft, maintainAspectRatio: true, expectingFrameChange: (2, 4, -2, -4))
        XCTAssertEqual(plusYPoint, CGPoint(x: 2, y: 4))
    }

    func test_accessibilityResize_topLeft_aspectMinResize() throws {
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 40), on: .resizeTopLeft, maintainAspectRatio: true, expectingFrameChange: (10, 20, -10, -20))
        XCTAssertEqual(plusYPoint, CGPoint(x: 10, y: 20))
    }

    func test_accessibilityResize_topRight_aspectUnboundedResize() throws {
        //Aspect doesn't resize horizontally
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -4, y: 0), on: .resizeTopRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(minusXPoint, .zero)
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 4, y: 0), on: .resizeTopRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(plusXPoint, .zero)
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -4), on: .resizeTopRight, maintainAspectRatio: true, expectingFrameChange: (0, -4, 2, 4))
        XCTAssertEqual(minusYPoint, CGPoint(x: 2, y: -4))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 4), on: .resizeTopRight, maintainAspectRatio: true, expectingFrameChange: (0, 4, -2, -4))
        XCTAssertEqual(plusYPoint, CGPoint(x: -2, y: 4))
    }

    func test_accessibilityResize_topRight_aspectMinResize() throws {
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 40), on: .resizeTopRight, maintainAspectRatio: true, expectingFrameChange: (0, 20, -10, -20))
        XCTAssertEqual(plusYPoint, CGPoint(x: -10, y: 20))
    }

    func test_accessibilityResize_bottomRight_aspectUnboundedResize() throws {
        //Aspect doesn't resize horizontally
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -4, y: 0), on: .resizeBottomRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(minusXPoint, .zero)
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 4, y: 0), on: .resizeBottomRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(plusXPoint, .zero)
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -4), on: .resizeBottomRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, -2, -4))
        XCTAssertEqual(minusYPoint, CGPoint(x: -2, y: -4))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 4), on: .resizeBottomRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, 2, 4))
        XCTAssertEqual(plusYPoint, CGPoint(x: 2, y: 4))
    }

    func test_accessibilityResize_bottomRight_aspectMinResize() throws {
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -40), on: .resizeBottomRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, -10, -20))
        XCTAssertEqual(minusYPoint, CGPoint(x: -10, y: -20))
    }

    func test_accessibilityResize_bottomLeft_aspectUnboundedResize() throws {
        //Aspect doesn't resize horizontally
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -4, y: 0), on: .resizeBottomLeft, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(minusXPoint, .zero)
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 4, y: 0), on: .resizeBottomLeft, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(plusXPoint, .zero)
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -4), on: .resizeBottomLeft, maintainAspectRatio: true, expectingFrameChange: (2, 0, -2, -4))
        XCTAssertEqual(minusYPoint, CGPoint(x: 2, y: -4))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 4), on: .resizeBottomLeft, maintainAspectRatio: true, expectingFrameChange: (-2, 0, 2, 4))
        XCTAssertEqual(plusYPoint, CGPoint(x: -2, y: 4))
    }

    func test_accessibilityResize_bottomLeft_aspectMinResize() throws {
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -40), on: .resizeBottomLeft, maintainAspectRatio: true, expectingFrameChange: (10, 0, -10, -20))
        XCTAssertEqual(minusYPoint, CGPoint(x: 10, y: -20))
    }


    private func performAccessibilityResize(withDelta delta: CGPoint, on component: LayoutEnginePageComponent, maintainAspectRatio: Bool = false, expectingFrameChange change: (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)) -> CGPoint? {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: maintainAspectRatio,
                                    minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(width: change.width, height: change.height)
        expectedFrame.origin = expectedFrame.origin.plus(x: change.x, y: change.y)

        let returnedDelta = self.layoutEngine.accessibilityResize(component, of: page, by: delta)

        guard page.layoutFrame == expectedFrame else {
            XCTFail("\(page.layoutFrame) not equal to \(expectedFrame)")
            return nil
        }

        return returnedDelta
    }



    //MARK: - Background
    func test_pageBackground_noPageShowsBackgroundIfMouseMovedOverCanvasAndNothingSelected() throws {
        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)

        self.layoutEngine.moveEvent(at: CGPoint(x: 40, y: 100))

        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)
    }

    func test_pageBackground_pageShowsBackgroundIfMouseMovesOverPage() throws {
        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: 3, y: 3)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertTrue(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)
    }

    func test_pageBackground_pageStillShowsBackgroundIfMouseMovesFurtherOverPage() throws {
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

    func test_pageBackground_pageDoesntShowBackgroundIfMouseMovesOffPage() throws {
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

    func test_pageBackground_pagesShowBackgroundIfSelected() throws {
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

    func test_pageBackground_pageStillShowsBackgroundIfSelectedAndMouseMovesOver() throws {
        let clickPoint1 = self.page1.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint1)

        self.layoutEngine.moveEvent(at: clickPoint1.plus(CGPoint(x: 2, y: 3)))

        XCTAssertTrue(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)
    }

    func test_pageBackground_pageStillShowsBackgroundIfSelectedAndMouseMovesOff() throws {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        let clickPoint = self.page3.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint)

        self.layoutEngine.moveEvent(at: self.page3.layoutFrame.origin.minus(CGPoint(x: 10, y: 10)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertTrue(self.page3.showBackground)
    }

    func test_pageBackground_allSelectedPagesAndTheHoveredPageShowBackground() throws {
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

    func test_pageBackground_onlySelectedPagesShowBackgroundAfterMouseMovesOffHoveredPage() throws {
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

    func test_pageBackground_notifiesViewWhenMovedAwayFromHoveredPage() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        view.context = nil

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.minus(x: 3, y: 3))

        XCTAssertTrue(try XCTUnwrap(view.context?.backgroundVisibilityChanged))
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOverHoveredPage() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        view.context = nil

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 4, y: 4))

        XCTAssertNil(view.context)
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOntoSelectedPage() throws {
        self.page2.selected = true
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        XCTAssertNil(view.context)
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOffSelectedPageToCanvas() throws {
        self.page2.selected = true
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        XCTAssertNil(view.context)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.minus(x: 4, y: 4))
        XCTAssertNil(view.context)
    }

    func test_pageBackground_notifiesViewWhenMovingOffSelectedPageToOtherUnselectedPage() throws {
        self.page2.selected = true
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        XCTAssertNil(view.context)

        self.layoutEngine.moveEvent(at: self.page3.layoutFrame.midPoint)
        XCTAssertNil(view.context)
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOffSelectedPageToOtherSelectedPage() throws {
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
    func test_canvasSize_canvasSizeShouldEqualContentBoundsPlusCanvasBorderOnEachSize() throws {
        XCTAssertEqual(self.layoutEngine.canvasSize, self.contentFrame.insetBy(dx: -20, dy: -20).size)
    }

    func test_canvasSize_canvasSizeShouldBeBiggerThanContentBoundsPlusCanvasBorderIfViewPortFrameIsOutside() throws {
        let testCanvas = TestCanvasView()
        testCanvas.viewPortFrame = CGRect(x: 60, y: 60, width: 80, height: 80)
        self.layoutEngine.view = testCanvas

        try self.drag(self.page1, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: 0)

        let borderedContentFrame = self.contentFrame.insetBy(dx: -20, dy: -20)
        let fullFrame = borderedContentFrame.union(testCanvas.viewPortFrame)
        XCTAssertEqual(self.layoutEngine.canvasSize, fullFrame.size)
    }

    func test_canvasSize_pageSpaceOffsetShouldChangeIfCanvasGrowsUpwards() throws {
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

    func test_canvasSize_pageSpaceOffsetShouldChangeIfCanvasGrowsToLeft() throws {
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

    func test_canvasSize_canvasSizeShouldUpdateWhenMovingPagesEnds() throws {
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

    func test_canvasSize_canvasSizeShouldUpdateWhenResizingPageEnds() throws {
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

    func test_canvasSize_updatesAllPagesCanvasFrameIfCanvasResizesUpAndToTheLeft() throws {
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

    func test_canvasSize_doesNOTUpdatePagesCanvasFrameIfCanvasResizesDownToTheLeft() throws {
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


    func test_keyboardMoving_callsDelegateAfterMovingPages() throws {
        let delegate = TestLayoutDelegate()
        self.layoutEngine.delegate = delegate

        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = true
//        _ = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, expectedShift: CGPoint(x: -1, y: 0))
        XCTFail()

        XCTAssertEqual(delegate.movedPages, [self.page1, self.page3])
    }


    //MARK: - Keyboard Deleting

}


private class TestCanvasView: CanvasLayoutView {
    var context: CanvasLayoutEngine.LayoutContext?
    func layoutChanged(with context: CanvasLayoutEngine.LayoutContext) {
        self.context = context
    }
    var viewPortFrame: CGRect = .zero
}



//Resize
extension CanvasLayoutEngineTests {
    func drag(_ page: LayoutEnginePage, byXEdge xEdge: TestDragEdge, yEdge: TestDragEdge, deltaX: CGFloat, deltaY: CGFloat) throws {
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


    //Top Left - Regular
    func test_resizing_draggingTopLeftEdgeToTopLeftIncreasesSizeAndDecreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -3, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        try self.drag(self.page1, byXEdge: .min, yEdge: .min, deltaX: -3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToBottomRightDecreasesSizeAndIncreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 3, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        try self.drag(self.page1, byXEdge: .min, yEdge: .min, deltaX: 3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToTopLeftStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: expectedFrame.maxX, height: expectedFrame.maxY)
        expectedFrame.origin = CGPoint(x: self.contentBorder, y: self.contentBorder)

        try self.drag(self.page1, byXEdge: .min, yEdge: .min, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopLeftEdgeToBottomRightStopsAtMinimumSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: expectedFrame.width - self.page1.minimumLayoutSize.width, y: expectedFrame.height - self.page1.minimumLayoutSize.height))
        expectedFrame.size = self.page1.minimumLayoutSize
        try self.drag(self.page1, byXEdge: .min, yEdge: .min, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top Right - Regular
    func test_resizing_draggingTopRightEdgeToTopRightIncreasesSizeAndDecreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        try self.drag(self.page1, byXEdge: .max, yEdge: .min, deltaX: 3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToBottomLeftDecreasesSizeAndIncreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        try self.drag(self.page1, byXEdge: .max, yEdge: .min, deltaX: -3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToTopRightStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: self.contentFrame.maxX - expectedFrame.minX + self.layoutEngine.configuration.contentBorder, height: expectedFrame.maxY)
        expectedFrame.origin.y = self.contentBorder

        try self.drag(self.page1, byXEdge: .max, yEdge: .min, deltaX: 100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingTopRightEdgeToBottomLeftStopsAtMinimumSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: expectedFrame.height - self.page1.minimumLayoutSize.height))
        expectedFrame.size = self.page1.minimumLayoutSize
        try self.drag(self.page1, byXEdge: .max, yEdge: .min, deltaX: -100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Bottom Right - Regular
    func test_resizing_draggingBottomRightEdgeToBottomRightIncreasesSize() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        try self.drag(self.page1, byXEdge: .max, yEdge: .max, deltaX: 3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToTopLeftDecreasesSize() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        try self.drag(self.page1, byXEdge: .max, yEdge: .max, deltaX: -3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToBottomRightStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: self.contentFrame.maxX - expectedFrame.minX + self.layoutEngine.configuration.contentBorder, height: self.contentFrame.maxY - expectedFrame.minY + self.layoutEngine.configuration.contentBorder)

        try self.drag(self.page1, byXEdge: .max, yEdge: .max, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomRightEdgeToTopLeftStopsAtMinimumSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = self.page1.minimumLayoutSize
        try self.drag(self.page1, byXEdge: .max, yEdge: .max, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top Right - Regular
    func test_resizing_draggingBottomLeftEdgeToBottomLeftIncreasesSizeAndDecreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -3, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        try self.drag(self.page1, byXEdge: .min, yEdge: .max, deltaX: -3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToTopRightDecreasesSizeAndIncreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 3, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        try self.drag(self.page1, byXEdge: .min, yEdge: .max, deltaX: 3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToBottomLeftStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: expectedFrame.maxX, height: self.contentFrame.maxY - expectedFrame.minY  + self.layoutEngine.configuration.contentBorder)
        expectedFrame.origin.x = self.contentBorder

        try self.drag(self.page1, byXEdge: .min, yEdge: .max, deltaX: -100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizing_draggingBottomLeftEdgeToTopRightStopsAtMinimumSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: expectedFrame.width - self.page1.minimumLayoutSize.width, y: 0))
        expectedFrame.size = self.page1.minimumLayoutSize
        try self.drag(self.page1, byXEdge: .min, yEdge: .max, deltaX: 100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    //Top Left - Aspect
    func test_resizing_aspect_draggingTopLeftEdgeToTopIncreasesSizeAndDecreasesOrigin() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -2, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        try self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: -4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToBottomDecreasesSizeAndIncreasesOrigin() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 2, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        try self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: 4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToLeftDoesntChangeSizeOrOrigin() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        try self.drag(page, byXEdge: .min, yEdge: .min, deltaX: -4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToRightDoesntChangeSizeOrOrigin() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        try self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToTopStopsAtCanvasEdgeIfWiderThanTaller() throws {
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

        try self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToTopStopsAtCanvasEdgeIfTallerThanWider() throws {
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

        try self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToBottomStopsAtMinHeightIfWiderThanTaller() throws {
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

        try self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopLeftEdgeToBottomStopsAtMinWidthIfTallerThanWider() throws {
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

        try self.drag(page, byXEdge: .min, yEdge: .min, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }


    //Top Right - Aspect
    func test_resizing_aspect_draggingTopRightEdgeToTopIncreasesSizeAndDecreasesY() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        try self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: -4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToBottomDecreasesSizeAndIncreasesY() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        try self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: 4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToLeftDoesntChangeSizeOrOrigin() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        try self.drag(page, byXEdge: .max, yEdge: .min, deltaX: -4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToRightDoesntChangeSizeOrOrigin() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        try self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToTopStopsAtCanvasEdgeIfWiderThanTaller() throws {
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

        try self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToTopStopsAtCanvasEdgeIfTallerThanWider() throws {
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

        try self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToBottomStopsAtMinHeightIfWiderThanTaller() throws {
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

        try self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingTopRightEdgeToBottomStopsAtMinWidthIfTallThanWider() throws {
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

        try self.drag(page, byXEdge: .max, yEdge: .min, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    //Bottom Right - Aspect
    func test_resizing_aspect_draggingBottomRightEdgeToBottomIncreasesSize() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        try self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: 4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToTopDecreasesSize() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        try self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: -4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToLeftDoesntChangeSizeOrOrigin() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        try self.drag(page, byXEdge: .max, yEdge: .max, deltaX: -4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToRightDoesntChangeSizeOrOrigin() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        try self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToBottomStopsAtCanvasEdgeIfWiderThanTaller() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 40, height: 20),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = (self.contentFrame.maxX + self.contentBorder) - expectedFrame.maxX
        let heightChange = widthChange / page.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)

        try self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToBottomStopsAtCanvasEdgeIfTallerThanWider() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let heightChange = (self.contentFrame.maxY + self.contentBorder) - expectedFrame.maxY
        let widthChange = heightChange * page.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)

        try self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToTopStopsAtMinHeightIfWiderThanTaller() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 40, height: 20),
                                    maintainAspectRatio: true,
                                    minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = page.contentFrame.width / 2
        let heightChange = page.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)

        try self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomRightEdgeToTopStopsAtMinWidthIfTallThanWider() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        let widthChange = page.contentFrame.width / 2
        let heightChange = page.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)

        try self.drag(page, byXEdge: .max, yEdge: .max, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    //Bottom Left - Aspect
    func test_resizing_aspect_draggingBottomLeftEdgeToBottomIncreasesSizeAndDecreasesX() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -2, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        try self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: 4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToTopDecreasesSizeAndIncreasesX() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        var expectedFrame = page.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 2, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        try self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: -4)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToLeftDoesntChangeSizeOrOrigin() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        try self.drag(page, byXEdge: .min, yEdge: .max, deltaX: -4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToRightDoesntChangeSizeOrOrigin() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: true,
                                    minimumContentSize: .zero)
        self.layoutEngine.add([page])
        let expectedFrame = page.layoutFrame
        try self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 4, deltaY: 0)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToBottomStopsAtCanvasEdgeIfWiderThanTaller() throws {
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

        try self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToTopStopsAtCanvasEdgeIfTallerThanWider() throws {
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

        try self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: 100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToTopStopsAtMinHeightIfWiderThanTaller() throws {
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

        try self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }

    func test_resizing_aspect_draggingBottomLeftEdgeToTopStopsAtMinWidthIfTallThanWider() throws {
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

        try self.drag(page, byXEdge: .min, yEdge: .max, deltaX: 0, deltaY: -100)

        XCTAssertEqual(page.layoutFrame, expectedFrame)
    }
}
