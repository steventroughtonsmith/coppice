//
//  ResizePageEventContext.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 03/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class ResizePageEventContextTests: EventContextTestBase {
    enum TestDragEdge {
        case min
        case mid
        case max
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupLayoutFrames()
    }

    func drag(_ component: LayoutEnginePageComponent, of page: LayoutEnginePage, deltaX: CGFloat, deltaY: CGFloat) throws {
        var componentRect = page.rectInLayoutFrame(for: component)
        componentRect.origin = componentRect.origin.plus(page.layoutFrame.origin)
        let startPoint = componentRect.midPoint
        let endPoint = startPoint.plus(CGPoint(x: deltaX, y: deltaY))

        let eventContext = ResizePageEventContext(page: page, component: component)
        eventContext.downEvent(at: startPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: endPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        eventContext.upEvent(at: endPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)

    }

    //MARK: - Left Edge
    func test_resizeLeftEdge_draggingToLeftIncreasesWidthAndDecreasesOriginX() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.x -= 2
        expectedFrame.size.width += 2

        try self.drag(.resizeLeft, of: self.page1, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeLeftEdge_draggingToRightDecreasesWidthAndIncreasesOriginX() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.x += 2
        expectedFrame.size.width -= 2

        try self.drag(.resizeLeft, of: self.page1, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeLeftEdge_draggingToLeftStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width += expectedFrame.origin.x
        expectedFrame.origin.x = 0

        try self.drag(.resizeLeft, of: self.page1, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeLeftEdge_draggingToRightStopsAtMinimumWidth() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.x += expectedFrame.width - self.page1.minimumContentSize.width
        expectedFrame.size.width = self.page1.minimumContentSize.width

        try self.drag(.resizeLeft, of: self.page1, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeLeftEdge_draggingToMinimumWidthThenBackToLeftDoesntStartResizingUntilPastLeftEdge() throws {
        XCTFail()
    }


    //MARK: - Top Edge
    func test_resizeTopEdge_draggingUpIncreasesHeightAndDecreasesOriginY() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.y -= 2
        expectedFrame.size.height += 2

        try self.drag(.resizeTop, of: self.page1, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopEdge_draggingDownDecreasesHeightAndIncreasesOriginY() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.y += 2
        expectedFrame.size.height -= 2

        try self.drag(.resizeTop, of: self.page1, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopEdge_draggingUpStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height += expectedFrame.origin.y
        expectedFrame.origin.y = 0

        try self.drag(.resizeTop, of: self.page1, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopEdge_draggingDownStopsAtMinimumHeight() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin.y += expectedFrame.height - self.page1.minimumLayoutSize.height
        expectedFrame.size.height = self.page1.minimumLayoutSize.height

        try self.drag(.resizeTop, of: self.page1, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopEdge_draggingToMinimumWidthThenBackToTopDoesntStartResizingUntilPastTopEdge() throws {
        XCTFail()
    }


    //MARK: - Right Edge
    func test_resizeRightEdge_draggingToRightIncreasesWidth() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width += 2

        try self.drag(.resizeRight, of: self.page1, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeRightEdge_draggingToLeftDecreasesWidth() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width -= 2

        try self.drag(.resizeRight, of: self.page1, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeRightEdge_draggingToRightStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width = self.mockLayoutEngine.canvasSize.width - expectedFrame.minX

        try self.drag(.resizeRight, of: self.page1, deltaX: 200, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeRightEdge_draggingToLeftStopsAtMinimumWidth() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.width = self.page1.minimumContentSize.width

        try self.drag(.resizeRight, of: self.page1, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeRightEdge_draggingToMinimumWidthThenBackToRightDoesntStartResizingUntilPastRightEdge() throws {
        XCTFail()
    }


    //MARK: - Bottom Edge
    func test_resizeBottomEdge_draggingDownIncreasesHeight() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height += 2

        try self.drag(.resizeBottom, of: self.page1, deltaX: 2, deltaY: 2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomEdge_draggingUpDecreasesHeight() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height -= 2

        try self.drag(.resizeBottom, of: self.page1, deltaX: -2, deltaY: -2)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomEdge_draggingDownStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height = self.mockLayoutEngine.canvasSize.height - expectedFrame.minY

        try self.drag(.resizeBottom, of: self.page1, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomEdge_draggingUpStopsAtMinimumHeight() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size.height = self.page1.minimumLayoutSize.height

        try self.drag(.resizeBottom, of: self.page1, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomEdge_draggingToMinimumWidthThenBackToBottomDoesntStartResizingUntilPastBottomEdge() throws {
        XCTFail()
    }
}
