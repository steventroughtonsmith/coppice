//
//  LayoutEngineArrowTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 26/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class LayoutEngineArrowTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }


    //MARK: - betweenSamePages(as:)
    func test_betweenSamePages_returnsTrueIfPointsAreEqualBetweenArrows() {
        let id1 = UUID()
        let id2 = UUID()
        let arrow1 = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 1, y: 1), edge: .top, pageID: id1),
                                       endPoint: ArrowPoint(point: CGPoint(x: 99, y: 99), edge: .bottom, pageID: id2))
        let arrow2 = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 1, y: 1), edge: .top, pageID: id1),
                                       endPoint: ArrowPoint(point: CGPoint(x: 99, y: 99), edge: .bottom, pageID: id2))
        XCTAssertTrue(arrow1.betweenSamePages(as: arrow2))
    }

    func test_betweenSamePages_returnsTrueIfUUIDsAreEqualButOtherArrowPropertiesAreNot() {
        let id1 = UUID()
        let id2 = UUID()
        let arrow1 = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 1, y: 1), edge: .top, pageID: id1),
                                       endPoint: ArrowPoint(point: CGPoint(x: 99, y: 99), edge: .bottom, pageID: id2))
        let arrow2 = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 2, y: 2), edge: .left, pageID: id1),
                                       endPoint: ArrowPoint(point: CGPoint(x: 1010, y: 1010), edge: .right, pageID: id2))
        XCTAssertTrue(arrow1.betweenSamePages(as: arrow2))
    }

    func test_betweenSamePages_returnsFalseIfUUIDsArentEqualButOtherPropertiesAre() {
        let arrow1 = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 1, y: 1), edge: .top, pageID: UUID()),
                                       endPoint: ArrowPoint(point: CGPoint(x: 99, y: 99), edge: .bottom, pageID: UUID()))
        let arrow2 = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 1, y: 1), edge: .top, pageID: UUID()),
                                       endPoint: ArrowPoint(point: CGPoint(x: 99, y: 99), edge: .bottom, pageID: UUID()))
        XCTAssertFalse(arrow1.betweenSamePages(as: arrow2))
    }


    //MARK: - .layoutFrame
    func test_layoutFrame_returnsFrameBoundingStartAndEndPointsIfLayoutEngineNotSet() {
        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 42, y: 6), edge: .top, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 13, y: 28), edge: .bottom, pageID: UUID()))

        let expectedFrame = CGRect(x: 13, y: 6, width: 29, height: 22)
        XCTAssertEqual(arrow.layoutFrame, expectedFrame)
    }

    func test_layoutFrame_increasesHeightByArrowHeadForHorizontalArrows() {
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 0, borderSize: 0, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 0,
                                                                                cornerSize: 0,
                                                                                arrowHeadSize: 8,
                                                                                lineWidth: 0)))
        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 42, y: 6), edge: .right, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 13, y: 28), edge: .left, pageID: UUID()),
                                      layoutEngine: layoutEngine)

        let expectedFrame = CGRect(x: 13, y: 2, width: 29, height: 30)
        XCTAssertEqual(arrow.layoutFrame, expectedFrame)
    }

    func test_layoutFrame_increasesWidthByArrowHeadForVerticalArrows() {
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 0, borderSize: 0, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 0,
                                                                                cornerSize: 0,
                                                                                arrowHeadSize: 12,
                                                                                lineWidth: 0)))
        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 42, y: 6), edge: .top, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 13, y: 28), edge: .bottom, pageID: UUID()),
                                      layoutEngine: layoutEngine)

        let expectedFrame = CGRect(x: 7, y: 6, width: 41, height: 22)
        XCTAssertEqual(arrow.layoutFrame, expectedFrame)
    }

    func test_layoutFrame_increasesWidthToAccountForEndLength_CornerSizeAndLineWidthForHorizontalArrows() {
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 24, borderSize: 0, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 2,
                                                                                cornerSize: 22,
                                                                                arrowHeadSize: 0,
                                                                                lineWidth: 5)))
        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 42, y: 6), edge: .right, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 13, y: 28), edge: .left, pageID: UUID()),
                                      layoutEngine: layoutEngine)

        let expectedFrame = CGRect(x: -4, y: 1, width: 63, height: 32)
        XCTAssertEqual(arrow.layoutFrame, expectedFrame)
    }

    func test_layoutFrame_increasesHeightToAccountForEndLength_CornerSize_LineWidthAndPageTitleHeightForVerticalArrows() {
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 24, borderSize: 0, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 4,
                                                                                cornerSize: 15,
                                                                                arrowHeadSize: 0,
                                                                                lineWidth: 9)))
        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 42, y: 6), edge: .bottom, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 13, y: 28), edge: .top, pageID: UUID()),
                                      layoutEngine: layoutEngine)

        let expectedFrame = CGRect(x: 4, y: -36.5, width: 47, height: 107)
        XCTAssertEqual(arrow.layoutFrame, expectedFrame)
    }


    //MARK: - .startPointInLayoutFrame
    func test_startPointInLayoutFrame_offsetsPointFromStartOfLayoutFrame() {
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 24, borderSize: 0, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 4, cornerSize: 16, arrowHeadSize: 6, lineWidth: 9)))

        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 50, y: 40), edge: .bottom, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 90, y: 60), edge: .top, pageID: UUID()),
                                      layoutEngine: layoutEngine)

        //layout frame = 38, -3, 64, 106
        let expectedStartPoint = CGPoint(x: 12, y: 43)
        XCTAssertEqual(arrow.startPointInLayoutFrame.point, expectedStartPoint)
    }


    //MARK: - .endPointInLayoutFrame
    func test_endPointInLayoutFrame_offsetsPointFromStartOfLayoutFrame() {
        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 50, y: 40), edge: .bottom, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 90, y: 60), edge: .top, pageID: UUID()),
                                      layoutEngine: nil)

        //layout frame = 38, -3, 64, 106
        let expectedEndPoint = CGPoint(x: 40, y: 20)
        XCTAssertEqual(arrow.endPointInLayoutFrame.point, expectedEndPoint)
    }

    func test_endPointInLayoutFrame_shiftsLeftPointToLeftToAccountForLineWidth() {
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 0, borderSize: 0, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 0, cornerSize: 0, arrowHeadSize: 0, lineWidth: 3)))

        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 50, y: 40), edge: .right, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 90, y: 60), edge: .left, pageID: UUID()),
                                      layoutEngine: layoutEngine)

        //layout frame = 47, 37, 46, 26
        let expectedEndPoint = CGPoint(x: 40, y: 23)
        XCTAssertEqual(arrow.endPointInLayoutFrame.point, expectedEndPoint)
    }

    func test_endPointInLayoutFrame_shiftsTopPointToTopToAccountForLineWidth() {
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 0, borderSize: 0, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 0, cornerSize: 0, arrowHeadSize: 0, lineWidth: 3)))

        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 50, y: 40), edge: .bottom, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 90, y: 60), edge: .top, pageID: UUID()),
                                      layoutEngine: layoutEngine)

        //layout frame = 47, 37, 46, 26
        let expectedEndPoint = CGPoint(x: 43, y: 20)
        XCTAssertEqual(arrow.endPointInLayoutFrame.point, expectedEndPoint)
    }

    func test_endPointInLayoutFrame_shiftsRightPointToRightToAccountForLineWidth() {
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 0, borderSize: 0, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 0, cornerSize: 0, arrowHeadSize: 0, lineWidth: 3)))

        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 50, y: 40), edge: .left, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 90, y: 60), edge: .right, pageID: UUID()),
                                      layoutEngine: layoutEngine)

        //layout frame = 47, 37, 46, 26
        let expectedEndPoint = CGPoint(x: 46, y: 23)
        XCTAssertEqual(arrow.endPointInLayoutFrame.point, expectedEndPoint)
    }

    func test_endPointInLayoutFrame_shiftsBottomPointToBottomToAccountForLineWidth() {
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 0, borderSize: 0, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 0, cornerSize: 0, arrowHeadSize: 0, lineWidth: 3)))

        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 50, y: 40), edge: .top, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 90, y: 60), edge: .bottom, pageID: UUID()),
                                      layoutEngine: layoutEngine)

        //layout frame = 47, 37, 46, 26
        let expectedEndPoint = CGPoint(x: 43, y: 26)
        XCTAssertEqual(arrow.endPointInLayoutFrame.point, expectedEndPoint)
    }

    func test_endPointInLayoutFrame_shiftsPointLeftFurtherToLeftToAccountForBorderIfPageBackgroundVisible() {
        let endPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        endPage.selected = true
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 0, borderSize: 4, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 0, cornerSize: 0, arrowHeadSize: 0, lineWidth: 3)))
        layoutEngine.add([endPage])

        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 50, y: 40), edge: .right, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 90, y: 60), edge: .left, pageID: endPage.id),
                                      layoutEngine: layoutEngine)

        //layout frame = 47, 37, 46, 26
        let expectedEndPoint = CGPoint(x: 36, y: 23)
        XCTAssertEqual(arrow.endPointInLayoutFrame.point, expectedEndPoint)
    }

    func test_endPointInLayoutFrame_shiftsPointTopFurtherToTopToAccountForTitleIfPageBackgroundVisible() {
        let endPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        endPage.selected = true
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 15, borderSize: 5, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 0, cornerSize: 0, arrowHeadSize: 0, lineWidth: 3)))
        layoutEngine.add([endPage])

        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 50, y: 40), edge: .bottom, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 90, y: 60), edge: .top, pageID: endPage.id),
                                      layoutEngine: layoutEngine)

        //layout frame = 47, 22, 46, 56
        let expectedEndPoint = CGPoint(x: 43, y: 20)
        XCTAssertEqual(arrow.endPointInLayoutFrame.point, expectedEndPoint)
    }

    func test_endPointInLayoutFrame_shiftsPointRightFurtherToRightToAccountForBorderIfPageBackgroundVisible() {
        let endPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        endPage.selected = true
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 0, borderSize: 5, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 0, cornerSize: 0, arrowHeadSize: 0, lineWidth: 3)))
        layoutEngine.add([endPage])

        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 50, y: 40), edge: .left, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 90, y: 60), edge: .right, pageID: endPage.id),
                                      layoutEngine: layoutEngine)

        //layout frame = 47, 37, 46, 26
        let expectedEndPoint = CGPoint(x: 51, y: 23)
        XCTAssertEqual(arrow.endPointInLayoutFrame.point, expectedEndPoint)
    }

    func test_endPointInLayoutFrame_shiftsPointBottomFurtherToBottomToAccountForBorderIfPageBackgroundVisible() {
        let endPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        endPage.selected = true
        let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 0, borderSize: 2, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                                   contentBorder: 0,
                                                                   arrow: .init(endLength: 0, cornerSize: 0, arrowHeadSize: 0, lineWidth: 3)))
        layoutEngine.add([endPage])

        let arrow = LayoutEngineArrow(startPoint: ArrowPoint(point: CGPoint(x: 50, y: 40), edge: .top, pageID: UUID()),
                                      endPoint: ArrowPoint(point: CGPoint(x: 90, y: 60), edge: .bottom, pageID: endPage.id),
                                      layoutEngine: layoutEngine)

        //layout frame = 47, 37, 46, 26
        let expectedEndPoint = CGPoint(x: 43, y: 28)
        XCTAssertEqual(arrow.endPointInLayoutFrame.point, expectedEndPoint)
    }
}
