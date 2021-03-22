//
//  ResizePageEventContext.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 03/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

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

    func drag(_ component: LayoutEnginePageComponent, of page: LayoutEnginePage, deltaX: CGFloat, deltaY: CGFloat, returnToStart: Bool = false) throws {
        var componentRect = page.rectInLayoutFrame(for: component)
        componentRect.origin = componentRect.origin.plus(page.layoutFrame.origin)
        let startPoint = componentRect.midPoint
        let endPoint = startPoint.plus(CGPoint(x: deltaX, y: deltaY))

        let eventContext = ResizePageEventContext(page: page, component: component)
        eventContext.downEvent(at: startPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: endPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        if (returnToStart) {
            eventContext.draggedEvent(at: startPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        }
        eventContext.upEvent(at: (returnToStart ? startPoint : endPoint), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
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

    func test_resizeLeftEdge_draggingBeyondMinimumWidthThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        let expectedFrame = self.page1.layoutFrame

        try self.drag(.resizeLeft, of: self.page1, deltaX: 100, deltaY: 100, returnToStart: true)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
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

    func test_resizeTopEdge_draggingBeyondMinimumWidthThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        let expectedFrame = self.page1.layoutFrame

        try self.drag(.resizeTop, of: self.page1, deltaX: 100, deltaY: 100, returnToStart: true)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
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

    func test_resizeRightEdge_draggingBeyondMinimumWidthThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        let expectedFrame = self.page1.layoutFrame

        try self.drag(.resizeRight, of: self.page1, deltaX: -100, deltaY: -100, returnToStart: true)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
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

    func test_resizeBottomEdge_draggingBeyondMinimumWidthThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        let expectedFrame = self.page1.layoutFrame

        try self.drag(.resizeBottom, of: self.page1, deltaX: -100, deltaY: -100, returnToStart: true)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }


    //MARK: - Top Left Corner
    func test_resizeTopLeftCorner_draggingToTopLeftIncreasesSizeAndDecreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -3, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        try self.drag(.resizeTopLeft, of: self.page1, deltaX: -3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopLeftCorner_draggingToBottomRightDecreasesSizeAndIncreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 3, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        try self.drag(.resizeTopLeft, of: self.page1, deltaX: 3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopLeftCorner_draggingToTopLeftStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: expectedFrame.maxX, height: expectedFrame.maxY)
        expectedFrame.origin = .zero

        try self.drag(.resizeTopLeft, of: self.page1, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopLeftCorner_draggingToBottomRightStopsAtMinimumSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: expectedFrame.width - self.page1.minimumLayoutSize.width, y: expectedFrame.height - self.page1.minimumLayoutSize.height))
        expectedFrame.size = self.page1.minimumLayoutSize
        try self.drag(.resizeTopLeft, of: self.page1, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopLeftCorner_draggingBeyondMinimumSizeThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        let expectedFrame = self.page1.layoutFrame

        try self.drag(.resizeTopLeft, of: self.page1, deltaX: 100, deltaY: 100, returnToStart: true)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }


    //MARK: - Top Right Corner
    func test_resizeTopRightCorner_draggingToTopRightIncreasesSizeAndDecreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        try self.drag(.resizeTopRight, of: self.page1, deltaX: 3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopRightCorner_draggingToBottomLeftDecreasesSizeAndIncreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        try self.drag(.resizeTopRight, of: self.page1, deltaX: -3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopRightCorner_draggingToTopRightStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: self.mockLayoutEngine.canvasSize.width - expectedFrame.minX, height: expectedFrame.maxY)
        expectedFrame.origin.y = 0

        try self.drag(.resizeTopRight, of: self.page1, deltaX: 100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopRightCorner_draggingToBottomLeftStopsAtMinimumSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: expectedFrame.height - self.page1.minimumLayoutSize.height))
        expectedFrame.size = self.page1.minimumLayoutSize
        try self.drag(.resizeTopRight, of: self.page1, deltaX: -100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeTopRightCorner_draggingBeyondMinimumSizeThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        let expectedFrame = self.page1.layoutFrame

        try self.drag(.resizeTopRight, of: self.page1, deltaX: -100, deltaY: 100, returnToStart: true)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }


    //MARK: - Bottom Right Corner
    func test_resizeBottomRightCorner_draggingToBottomRightIncreasesSize() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        try self.drag(.resizeBottomRight, of: self.page1, deltaX: 3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomRightCorner_draggingToTopLeftDecreasesSize() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        try self.drag(.resizeBottomRight, of: self.page1, deltaX: -3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomRightCorner_draggingToBottomRightStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: self.mockLayoutEngine.canvasSize.width - expectedFrame.minX, height: self.mockLayoutEngine.canvasSize.height - expectedFrame.minY)

        try self.drag(.resizeBottomRight, of: self.page1, deltaX: 100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomRightCorner_draggingToTopLeftStopsAtMinimumSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = self.page1.minimumLayoutSize
        try self.drag(.resizeBottomRight, of: self.page1, deltaX: -100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomRightCorner_draggingBeyondMinimumSizeThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        let expectedFrame = self.page1.layoutFrame

        try self.drag(.resizeBottomRight, of: self.page1, deltaX: -100, deltaY: -100, returnToStart: true)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }


    //MARK: - Bottom Left Corner
    func test_resizeBottomLeftCorner_draggingToBottomLeftIncreasesSizeAndDecreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -3, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 3, height: 4))

        try self.drag(.resizeBottomLeft, of: self.page1, deltaX: -3, deltaY: 4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomLeftCorner_draggingToTopRightDecreasesSizeAndIncreasesOrigin() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 3, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -3, height: -4))

        try self.drag(.resizeBottomLeft, of: self.page1, deltaX: 3, deltaY: -4)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomLeftCorner_draggingToBottomLeftStopsAtCanvasEdge() throws {
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.size = CGSize(width: expectedFrame.maxX, height: self.mockLayoutEngine.canvasSize.height - expectedFrame.minY)
        expectedFrame.origin.x = 0

        try self.drag(.resizeBottomLeft, of: self.page1, deltaX: -100, deltaY: 100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomLeftCorner_draggingToTopRightStopsAtMinimumSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        var expectedFrame = self.page1.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: expectedFrame.width - self.page1.minimumLayoutSize.width, y: 0))
        expectedFrame.size = self.page1.minimumLayoutSize
        try self.drag(.resizeBottomLeft, of: self.page1, deltaX: 100, deltaY: -100)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }

    func test_resizeBottomLeftCorner_draggingBeyondMinimumSizeThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page1.minimumContentSize = CGSize(width: 5, height: 5)
        let expectedFrame = self.page1.layoutFrame

        try self.drag(.resizeBottomLeft, of: self.page1, deltaX: 100, deltaY: -100, returnToStart: true)

        XCTAssertEqual(self.page1.layoutFrame, expectedFrame)
    }


    //MARK: - Aspect Top Left Corner
    func test_aspectResizeTopLeftCorner_draggingToTopIncreasesSizeAndDecreasesOrigin() throws {
        var expectedFrame = self.page3.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -2, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        try self.drag(.resizeTopLeft, of: self.page3, deltaX: 0, deltaY: -4)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopLeftCorner_draggingToBottomDecreasesSizeAndIncreasesOrigin() throws {
        var expectedFrame = self.page3.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 2, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        try self.drag(.resizeTopLeft, of: self.page3, deltaX: 0, deltaY: 4)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopLeftCorner_draggingToLeftDoesntChangeSizeOrOrigin() throws {
        let expectedFrame = self.page3.layoutFrame
        try self.drag(.resizeTopLeft, of: self.page3, deltaX: -4, deltaY: 0)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopLeftCorner_draggingToRightDoesntChangeSizeOrOrigin() throws {
        let expectedFrame = self.page3.layoutFrame
        try self.drag(.resizeTopLeft, of: self.page3, deltaX: 4, deltaY: 0)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopLeftCorner_draggingToTopStopsAtCanvasEdgeIfWiderThanTaller() throws {
        let contentMidPoint = self.mockLayoutEngine.canvasSize.toRect().midPoint
        self.page3Wide.testLayoutFrame?.origin = contentMidPoint.minus(x: 20, y: 10)

        var expectedFrame = self.page3Wide.layoutFrame
        let widthChange = expectedFrame.minX
        let heightChange = widthChange / self.page3Wide.aspectRatio
        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin = expectedFrame.origin.plus(x: -widthChange, y: -heightChange)

        try self.drag(.resizeTopLeft, of: self.page3Wide, deltaX: 0, deltaY: -100)

        XCTAssertEqual(self.page3Wide.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopLeftCorner_draggingToTopStopsAtCanvasEdgeIfTallerThanWider() throws {
        let contentMidPoint = self.mockLayoutEngine.canvasSize.toRect().midPoint.minus(self.contentOffset)
        self.page3.contentFrame = CGRect(x: contentMidPoint.x - 10, y: contentMidPoint.y - 20, width: 20, height: 40)

        var expectedFrame = self.page3.layoutFrame
        let heightChange = expectedFrame.minY
        let widthChange = heightChange * self.page3.aspectRatio
        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin = expectedFrame.origin.plus(x: -widthChange, y: -heightChange)

        try self.drag(.resizeTopLeft, of: self.page3, deltaX: 0, deltaY: -100)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopLeftCorner_draggingToBottomStopsAtMinHeightIfWiderThanTaller() throws {
        self.page3Wide.minimumContentSize = CGSize(width: 20, height: 10)
        var expectedFrame = self.page3Wide.layoutFrame
        let widthChange = self.page3Wide.contentFrame.width / 2
        let heightChange = self.page3Wide.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin = expectedFrame.origin.plus(x: widthChange, y: heightChange)

        try self.drag(.resizeTopLeft, of: self.page3Wide, deltaX: 0, deltaY: 100)

        XCTAssertEqual(self.page3Wide.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopLeftCorner_draggingToBottomStopsAtMinWidthIfTallerThanWider() throws {
        self.page3.minimumContentSize = CGSize(width: 10, height: 20)
        var expectedFrame = self.page3.layoutFrame
        let widthChange = self.page3.contentFrame.width / 2
        let heightChange = self.page3.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin = expectedFrame.origin.plus(x: widthChange, y: heightChange)

        try self.drag(.resizeTopLeft, of: self.page3, deltaX: 0, deltaY: 100)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopLeftCorner_draggingBeyondMinimumSizeThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page3.minimumContentSize = CGSize(width: 10, height: 20)
        let expectedFrame = self.page3.layoutFrame

        try self.drag(.resizeTopLeft, of: self.page3, deltaX: 0, deltaY: 100, returnToStart: true)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }


    //MARK: - Aspect Top Right Corner
    func test_aspectResizeTopRightCorner_draggingToTopIncreasesSizeAndDecreasesY() throws {
        var expectedFrame = self.page3.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: -4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        try self.drag(.resizeTopRight, of: self.page3, deltaX: 0, deltaY: -4)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopRightCorner_draggingToBottomDecreasesSizeAndIncreasesY() throws {
        var expectedFrame = self.page3.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 0, y: 4))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        try self.drag(.resizeTopRight, of: self.page3, deltaX: 0, deltaY: 4)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopRightCorner_draggingToLeftDoesntChangeSizeOrOrigin() throws {
        let expectedFrame = self.page3.layoutFrame
        try self.drag(.resizeTopRight, of: self.page3, deltaX: -4, deltaY: 0)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopRightCorner_draggingToRightDoesntChangeSizeOrOrigin() throws {
        let expectedFrame = self.page3.layoutFrame
        try self.drag(.resizeTopRight, of: self.page3, deltaX: 4, deltaY: 0)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopRightCorner_draggingToTopStopsAtCanvasEdgeIfWiderThanTaller() throws {
        let contentMidPoint = self.mockLayoutEngine.canvasSize.toRect().midPoint
        self.page3Wide.testLayoutFrame?.origin = contentMidPoint.minus(x: 20, y: 10)

        var expectedFrame = self.page3Wide.layoutFrame
        let widthChange = self.mockLayoutEngine.canvasSize.width - expectedFrame.maxX
        let heightChange = widthChange / self.page3Wide.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin.y -= heightChange

        try self.drag(.resizeTopRight, of: self.page3Wide, deltaX: 0, deltaY: -100)

        XCTAssertEqual(self.page3Wide.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopRightCorner_draggingToTopStopsAtCanvasEdgeIfTallerThanWider() throws {
        let contentMidPoint = self.mockLayoutEngine.canvasSize.toRect().midPoint.minus(self.contentOffset)
        self.page3.contentFrame = CGRect(x: contentMidPoint.x - 10, y: contentMidPoint.y - 20, width: 20, height: 40)

        var expectedFrame = self.page3.layoutFrame
        let heightChange = expectedFrame.minY
        let widthChange = heightChange * self.page3.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin.y = 0

        try self.drag(.resizeTopRight, of: self.page3, deltaX: 0, deltaY: -100)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopRightCorner_draggingToBottomStopsAtMinHeightIfWiderThanTaller() throws {
        self.page3Wide.minimumContentSize = CGSize(width: 20, height: 10)
        var expectedFrame = self.page3Wide.layoutFrame
        let widthChange = self.page3Wide.contentFrame.width / 2
        let heightChange = self.page3Wide.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin.y += heightChange

        try self.drag(.resizeTopRight, of: self.page3Wide, deltaX: 0, deltaY: 100)

        XCTAssertEqual(self.page3Wide.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopRightCorner_draggingToBottomStopsAtMinWidthIfTallThanWider() throws {
        self.page3.minimumContentSize = CGSize(width: 10, height: 20)
        var expectedFrame = self.page3.layoutFrame
        let widthChange = self.page3.contentFrame.width / 2
        let heightChange = self.page3.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin.y += heightChange

        try self.drag(.resizeTopRight, of: self.page3, deltaX: 0, deltaY: 100)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeTopRightCorner_draggingBeyondMinimumSizeThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page3.minimumContentSize = CGSize(width: 10, height: 20)
        let expectedFrame = self.page3.layoutFrame

        try self.drag(.resizeTopRight, of: self.page3, deltaX: 0, deltaY: 100, returnToStart: true)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }


    //MARK: - Aspect Bottom Right Corner
    func test_aspectResizeBottomRightCorner_draggingToBottomIncreasesSize() throws {
        var expectedFrame = self.page3.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        try self.drag(.resizeBottomRight, of: self.page3, deltaX: 0, deltaY: 4)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomRightCorner_draggingToTopDecreasesSize() throws {
        var expectedFrame = self.page3.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        try self.drag(.resizeBottomRight, of: self.page3, deltaX: 0, deltaY: -4)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomRightCorner_draggingToLeftDoesntChangeSizeOrOrigin() throws {
        let expectedFrame = self.page3.layoutFrame
        try self.drag(.resizeBottomRight, of: self.page3, deltaX: -4, deltaY: 0)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomRightCorner_draggingToRightDoesntChangeSizeOrOrigin() throws {
        let expectedFrame = self.page3.layoutFrame
        try self.drag(.resizeBottomRight, of: self.page3, deltaX: 4, deltaY: 0)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomRightCorner_draggingToBottomStopsAtCanvasEdgeIfWiderThanTaller() throws {
        let contentMidPoint = self.mockLayoutEngine.canvasSize.toRect().midPoint
        self.page3Wide.testLayoutFrame?.origin = contentMidPoint.minus(x: 20, y: 10)

        var expectedFrame = self.page3Wide.layoutFrame
        let widthChange = self.mockLayoutEngine.canvasSize.width - expectedFrame.maxX
        let heightChange = widthChange / self.page3Wide.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)

        try self.drag(.resizeBottomRight, of: self.page3Wide, deltaX: 0, deltaY: 100)

        XCTAssertEqual(self.page3Wide.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomRightCorner_draggingToBottomStopsAtCanvasEdgeIfTallerThanWider() throws {
        let contentMidPoint = self.mockLayoutEngine.canvasSize.toRect().midPoint.minus(self.contentOffset)
        self.page3.contentFrame = CGRect(x: contentMidPoint.x - 10, y: contentMidPoint.y - 20, width: 20, height: 40)

        var expectedFrame = self.page3.layoutFrame
        let heightChange = self.mockLayoutEngine.canvasSize.height - expectedFrame.maxY
        let widthChange = heightChange * self.page3.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)

        try self.drag(.resizeBottomRight, of: self.page3, deltaX: 0, deltaY: 100)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomRightCorner_draggingToTopStopsAtMinHeightIfWiderThanTaller() throws {
        self.page3Wide.minimumContentSize = CGSize(width: 20, height: 10)
        var expectedFrame = self.page3Wide.layoutFrame
        let widthChange = self.page3Wide.contentFrame.width / 2
        let heightChange = self.page3Wide.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)

        try self.drag(.resizeBottomRight, of: self.page3Wide, deltaX: 0, deltaY: -100)

        XCTAssertEqual(self.page3Wide.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomRightCorner_draggingToTopStopsAtMinWidthIfTallThanWider() throws {
        self.page3.minimumContentSize = CGSize(width: 10, height: 20)
        var expectedFrame = self.page3.layoutFrame
        let widthChange = self.page3.contentFrame.width / 2
        let heightChange = self.page3.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)

        try self.drag(.resizeBottomRight, of: self.page3, deltaX: 0, deltaY: -100)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomRightCorner_draggingBeyondMinimumSizeThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page3.minimumContentSize = CGSize(width: 10, height: 20)
        let expectedFrame = self.page3.layoutFrame

        try self.drag(.resizeBottomRight, of: self.page3, deltaX: 0, deltaY: -100, returnToStart: true)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }


    //MARK: - Aspect Bottom Left Corner
    func test_aspectResizeBottomLeftCorner_draggingToBottomIncreasesSizeAndDecreasesX() throws {
        var expectedFrame = self.page3.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: -2, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: 2, height: 4))

        try self.drag(.resizeBottomLeft, of: self.page3, deltaX: 0, deltaY: 4)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomLeftCorner_draggingToTopDecreasesSizeAndIncreasesX() throws {
        var expectedFrame = self.page3.layoutFrame
        expectedFrame.origin = expectedFrame.origin.plus(CGPoint(x: 2, y: 0))
        expectedFrame.size = expectedFrame.size.plus(CGSize(width: -2, height: -4))

        try self.drag(.resizeBottomLeft, of: self.page3, deltaX: 0, deltaY: -4)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomLeftCorner_draggingToLeftDoesntChangeSizeOrOrigin() throws {
        let expectedFrame = self.page3.layoutFrame
        try self.drag(.resizeBottomLeft, of: self.page3, deltaX: -4, deltaY: 0)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomLeftCorner_draggingToRightDoesntChangeSizeOrOrigin() throws {
        let expectedFrame = self.page3.layoutFrame
        try self.drag(.resizeBottomLeft, of: self.page3, deltaX: 4, deltaY: 0)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomLeftCorner_draggingToBottomStopsAtCanvasEdgeIfWiderThanTaller() throws {
        let contentMidPoint = self.mockLayoutEngine.canvasSize.toRect().midPoint
        self.page3Wide.testLayoutFrame?.origin = contentMidPoint.minus(x: 20, y: 10)

        var expectedFrame = self.page3Wide.layoutFrame
        let widthChange = expectedFrame.minX
        let heightChange = widthChange / self.page3Wide.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin.x = 0

        try self.drag(.resizeBottomLeft, of: self.page3Wide, deltaX: 0, deltaY: 100)

        XCTAssertEqual(self.page3Wide.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomLeftCorner_draggingToTopStopsAtCanvasEdgeIfTallerThanWider() throws {
        let contentMidPoint = self.mockLayoutEngine.canvasSize.toRect().midPoint.minus(self.contentOffset)
        self.page3.contentFrame = CGRect(x: contentMidPoint.x - 10, y: contentMidPoint.y - 20, width: 20, height: 40)

        var expectedFrame = self.page3.layoutFrame
        let heightChange = self.mockLayoutEngine.canvasSize.height - expectedFrame.maxY
        let widthChange = heightChange * self.page3.aspectRatio

        expectedFrame.size = expectedFrame.size.plus(width: widthChange, height: heightChange)
        expectedFrame.origin.x -= widthChange

        try self.drag(.resizeBottomLeft, of: self.page3, deltaX: 0, deltaY: 100)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomLeftCorner_draggingToTopStopsAtMinHeightIfWiderThanTaller() throws {
        self.page3Wide.minimumContentSize = CGSize(width: 20, height: 10)
        var expectedFrame = self.page3Wide.layoutFrame
        let widthChange = self.page3Wide.contentFrame.width / 2
        let heightChange = self.page3Wide.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin.x += widthChange

        try self.drag(.resizeBottomLeft, of: self.page3Wide, deltaX: 0, deltaY: -100)

        XCTAssertEqual(self.page3Wide.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomLeftCorner_draggingToTopStopsAtMinWidthIfTallThanWider() throws {
        self.page3.minimumContentSize = CGSize(width: 10, height: 20)
        var expectedFrame = self.page3.layoutFrame
        let widthChange = self.page3.contentFrame.width / 2
        let heightChange = self.page3.contentFrame.height / 2
        expectedFrame.size = expectedFrame.size.plus(width: -widthChange, height: -heightChange)
        expectedFrame.origin.x += widthChange

        try self.drag(.resizeBottomLeft, of: self.page3, deltaX: 0, deltaY: -100)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }

    func test_aspectResizeBottomLeftCorner_draggingBeyondMinimumSizeThenBackToOriginalPointResizesBackToOriginalSize() throws {
        self.page3.minimumContentSize = CGSize(width: 10, height: 20)
        let expectedFrame = self.page3.layoutFrame

        try self.drag(.resizeBottomLeft, of: self.page3, deltaX: 0, deltaY: -100, returnToStart: true)

        XCTAssertEqual(self.page3.layoutFrame, expectedFrame)
    }
}
