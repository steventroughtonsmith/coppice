//
//  LayoutEnginePageTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 03/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class LayoutEnginePageTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_init_setsAllProperties() {
        let layoutEngine = self.layoutEngine()

        let expectedUUID = UUID()
        let expectedContentFrame = CGRect(x: 31, y: 42, width: 73, height: 37)
        let expectedMinContentSize = CGSize(width: 20, height: 30)
        let page = layoutEngine.addPage(withID: expectedUUID, contentFrame: expectedContentFrame, minimumContentSize: expectedMinContentSize)

        XCTAssertEqual(page.id, expectedUUID)
        XCTAssertEqual(page.contentFrame, expectedContentFrame)
        XCTAssertEqual(page.minimumContentSize, expectedMinContentSize)
        XCTAssertTrue(page.layoutEngine === layoutEngine)
    }

    func test_init_increasesContentSizeIfBelowMinimum() {
        let layoutEngine = self.layoutEngine()
        let page = layoutEngine.addPage(withID: UUID(),
                                        contentFrame: CGRect(x: 0, y: 0, width:20, height: 40),
                                        minimumContentSize: CGSize(width: 50, height: 60))
        XCTAssertEqual(page.contentFrame, CGRect(x: 0, y: 0, width: 50, height: 60))
    }


    //MARK: - Size Validation
    func test_validateSize_doesntChangeContentFrameIfBiggerThanMinSize() {
        let layoutEngine = self.layoutEngine()
        let page = layoutEngine.addPage(withID: UUID(),
                                        contentFrame: .zero)
        page.minimumContentSize = CGSize(width: 50, height: 100)
        page.contentFrame = CGRect(x: 0, y: 0, width: 60, height: 110)

        XCTAssertEqual(page.contentFrame, CGRect(x: 0, y: 0, width: 60, height: 110))
    }

    func test_validateSize_setsContentFrameWidthToMinimumIfSmallerThanMinSize() {
        let layoutEngine = self.layoutEngine()
        let page = layoutEngine.addPage(withID: UUID(),
                                        contentFrame: .zero)
        page.minimumContentSize = CGSize(width: 50, height: 100)
        page.contentFrame = CGRect(x: 0, y: 0, width: 20, height: 110)

        XCTAssertEqual(page.contentFrame, CGRect(x: 0, y: 0, width: 50, height: 110))
    }

    func test_validateSize_setsContentFrameHeightToMinimumIfSmallerThanMinSize() {
        let layoutEngine = self.layoutEngine()
        let page = layoutEngine.addPage(withID: UUID(),
                                        contentFrame: .zero)
        page.minimumContentSize = CGSize(width: 50, height: 100)
        page.contentFrame = CGRect(x: 0, y: 0, width: 60, height: 80)

        XCTAssertEqual(page.contentFrame, CGRect(x: 0, y: 0, width: 60, height: 100))
    }


    //MARK: - Layout Frames
    func test_minimumLayoutSize_matchesContentSizeIfConfigIsAllZeros() {
        let layoutEngine = self.layoutEngine()

        let expectedSize = CGSize(width: 120, height: 40)
        let page = layoutEngine.addPage(withID: UUID(),
                                        contentFrame: .zero,
                                        minimumContentSize: expectedSize)

        XCTAssertEqual(page.minimumLayoutSize, expectedSize)
    }

    func test_minimumLayoutSize_increasesSizeToAccountForConfig() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 30,
                                             pageResizeEdgeHandleSize: 7,
                                             pageResizeCornerHandleSize: 12,
                                             pageResizeHandleOffset: 2)

        let contentSize = CGSize(width: 120, height: 40)
        let page = layoutEngine.addPage(withID: UUID(),
                                        contentFrame: .zero,
                                        minimumContentSize:contentSize)

        let expectedSize = contentSize.plus(width: 4, height: 34)
        XCTAssertEqual(page.minimumLayoutSize, expectedSize)
    }

    func test_layoutFrame_convertsContentFrameOriginToCanvasSpaceIfConfigIsAllZeros() {
        let layoutEngine = self.layoutEngine()

        layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)

        XCTAssertEqual(page.layoutFrame.origin, CGPoint(x: 50, y: 40))
    }

    func test_layoutFrame_matchesContentFrameSizeIfConfigIsAllZeros() {
        let layoutEngine = self.layoutEngine()

        layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)

        XCTAssertEqual(page.layoutFrame.size, CGSize(width: 110, height: 220))
    }

    func test_layoutFrame_modifiesOriginAndSizeToAccountForConfig() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 10,
                                             pageResizeEdgeHandleSize: 3,
                                             pageResizeCornerHandleSize: 5,
                                             pageResizeHandleOffset: 3,
                                             contentBorder: 20)

        layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)

        XCTAssertEqual(page.layoutFrame, CGRect(x: 50, y: 40, width: 116, height: 236))
    }

    func test_layoutFrame_settingFrameConvertsOriginToPageSpaceAndSetsContentFrameIfConfigIsAllZeroes() {
        let layoutEngine = self.layoutEngine()
        layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)

        page.layoutFrame = CGRect(x: 60, y: 60, width: 130, height: 240)

        XCTAssertEqual(page.contentFrame.origin, CGPoint(x: 10, y: 20))
    }

    func test_layoutFrame_settingFrameSetsContentFrameSizeToSameIfConfigIsAllZeroes() {
        let layoutEngine = self.layoutEngine()
        layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)

        page.layoutFrame = CGRect(x: 60, y: 60, width: 130, height: 240)

        XCTAssertEqual(page.contentFrame.size, CGSize(width: 130, height: 240))
    }

    func test_layoutFrame_settingFrameModifiesFrameUsingConfigBeforeSettingToContentFrame() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 10,
                                             pageResizeEdgeHandleSize: 3,
                                             pageResizeCornerHandleSize: 5,
                                             pageResizeHandleOffset: 3,
                                             contentBorder: 20)
        layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)

        page.layoutFrame = CGRect(x: 60, y: 60, width: 130, height: 240)

        XCTAssertEqual(page.contentFrame, CGRect(x: 10, y: 20, width: 124, height: 224))
    }

    func test_layoutFrameInPageSpace_convertsTheLayoutFrameOriginToPageSpace() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 10,
                                             pageResizeEdgeHandleSize: 3,
                                             pageResizeCornerHandleSize: 5,
                                             pageResizeHandleOffset: 3,
                                             contentBorder: 20)

        layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 220, height: 110), minimumContentSize: .zero)

        XCTAssertEqual(page.layoutFrameInPageSpace, CGRect(origin: CGPoint(x: -3, y: -13), size: page.layoutFrame.size))
    }
    

    //MARK: - Component Frames
    func test_visualPageFrame_isSameSizeAsLayoutFrameAndAtPointZeroIfResizeHandleOffsetIs0() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 0,
                                             pageResizeEdgeHandleSize: 3,
                                             pageResizeCornerHandleSize: 5,
                                             pageResizeHandleOffset: 0,
                                             contentBorder: 20)

        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 110, height: 220), minimumContentSize: .zero)

        XCTAssertEqual(page.visualPageFrame, CGRect(x: 0, y: 0, width: 110, height: 220))
    }

    func test_visualPageFrame_isInsetFromLayoutFrameByResizeHandleOffset() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 0,
                                             pageResizeEdgeHandleSize: 3,
                                             pageResizeCornerHandleSize: 5,
                                             pageResizeHandleOffset: 7,
                                             contentBorder: 20)

        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 110, height: 220), minimumContentSize: .zero)

        XCTAssertEqual(page.visualPageFrame, CGRect(x: 7, y: 7, width: 110, height: 220))
    }

    func test_visualPageFrame_hasSizeIncreasedByTitleHeightIfNotZero() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 42,
                                             pageResizeEdgeHandleSize: 3,
                                             pageResizeCornerHandleSize: 5,
                                             pageResizeHandleOffset: 0,
                                             contentBorder: 20)

        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 110, height: 220), minimumContentSize: .zero)

        XCTAssertEqual(page.visualPageFrame, CGRect(x: 0, y: 0, width: 110, height: 262))
    }

    func test_titleFrame_fillsTopOfVisualPageFrameWithTitleHeight() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 42,
                                             pageResizeEdgeHandleSize: 3,
                                             pageResizeCornerHandleSize: 5,
                                             pageResizeHandleOffset: 0,
                                             contentBorder: 20)

        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 110, height: 220), minimumContentSize: .zero)

        XCTAssertEqual(page.titleBarFrame, CGRect(x: 0, y: 0, width: 110, height: 42))
    }

    func test_contentFrame_fillsBottomOfVisualPageFrameOffsetByTitleHeight() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 42,
                                             pageResizeEdgeHandleSize: 3,
                                             pageResizeCornerHandleSize: 5,
                                             pageResizeHandleOffset: 0,
                                             contentBorder: 20)

        let page = layoutEngine.addPage(withID: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 110, height: 220), minimumContentSize: .zero)

        XCTAssertEqual(page.contentFrame, CGRect(x: 0, y: 42, width: 110, height: 220))
    }


    //MARK: - component(at:)
    func performPageComponentTest(_ block: (LayoutEnginePage) throws -> Void) throws {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 10,
                                             pageResizeEdgeHandleSize: 3,
                                             pageResizeCornerHandleSize: 5,
                                             pageResizeHandleOffset: 0,
                                             contentBorder: 20)

        let page = layoutEngine.addPage(withID: UUID(),
                                        contentFrame: CGRect(x: 20, y: 40, width: 30, height: 20),
                                        minimumContentSize: .zero)
        try block(page)
    }

    func test_component_resizeLeft() throws {
        try self.performPageComponentTest { page in
            //Inside
            XCTAssertEqual(page.component(at: CGPoint(x: 0, y: 5)), .resizeLeft)
            XCTAssertEqual(page.component(at: CGPoint(x: 0, y: 24)), .resizeLeft)
            XCTAssertEqual(page.component(at: CGPoint(x: 2, y: 5)), .resizeLeft)
            XCTAssertEqual(page.component(at: CGPoint(x: 2, y: 24)), .resizeLeft)

            //Outside
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 3, y: 5))), .resizeLeft)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 3, y: 24))), .resizeLeft)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 0, y: 4))), .resizeLeft)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 0, y: 25))), .resizeLeft)
        }
    }

    func test_component_resizeTopLeft() throws {
        try self.performPageComponentTest { page in
            //Inside
            XCTAssertEqual(page.component(at: CGPoint(x: 0, y: 0)), .resizeTopLeft)
            XCTAssertEqual(page.component(at: CGPoint(x: 0, y: 4)), .resizeTopLeft)
            XCTAssertEqual(page.component(at: CGPoint(x: 4, y: 0)), .resizeTopLeft)
            XCTAssertEqual(page.component(at: CGPoint(x: 4, y: 4)), .resizeTopLeft)

            //Outside
            XCTAssertNil(page.component(at: CGPoint(x: -1, y: -1)))
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 0, y: 5))), .resizeTopLeft)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 5, y: 0))), .resizeTopLeft)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 5, y: 5))), .resizeTopLeft)
        }
    }

    func test_component_resizeTop() throws {
        try self.performPageComponentTest { page in
            //Inside
            XCTAssertEqual(page.component(at: CGPoint(x: 5, y: 0)), .resizeTop)
            XCTAssertEqual(page.component(at: CGPoint(x: 24, y: 0)), .resizeTop)
            XCTAssertEqual(page.component(at: CGPoint(x: 5, y: 2)), .resizeTop)
            XCTAssertEqual(page.component(at: CGPoint(x: 24, y: 2)), .resizeTop)

            //Outside
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 4, y: 0))), .resizeTop)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 25, y: 0))), .resizeTop)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 6, y: 3))), .resizeTop)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 25, y: 3))), .resizeTop)
        }
    }

    func test_component_resizeTopRight() throws {
        try self.performPageComponentTest { page in
            //Inside
            XCTAssertEqual(page.component(at: CGPoint(x: 25, y: 0)), .resizeTopRight)
            XCTAssertEqual(page.component(at: CGPoint(x: 29, y: 0)), .resizeTopRight)
            XCTAssertEqual(page.component(at: CGPoint(x: 25, y: 4)), .resizeTopRight)
            XCTAssertEqual(page.component(at: CGPoint(x: 29, y: 4)), .resizeTopRight)

            //Outside
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 24, y: 0))), .resizeTopRight)
            XCTAssertNil(page.component(at: CGPoint(x: 30, y: 0)))
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 24, y: 5))), .resizeTopRight)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 29, y: 5))), .resizeTopRight)
        }
    }

    func test_component_resizeRight() throws {
        try self.performPageComponentTest { page in
            //Inside
            XCTAssertEqual(page.component(at: CGPoint(x: 27, y: 5)), .resizeRight)
            XCTAssertEqual(page.component(at: CGPoint(x: 29, y: 5)), .resizeRight)
            XCTAssertEqual(page.component(at: CGPoint(x: 27, y: 24)), .resizeRight)
            XCTAssertEqual(page.component(at: CGPoint(x: 29, y: 24)), .resizeRight)

            //Outside
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 26, y: 4))), .resizeRight)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 29, y: 4))), .resizeRight)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 26, y: 24))), .resizeRight)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 29, y: 25))), .resizeRight)
        }
    }

    func test_component_resizeBottomRight() throws {
        try self.performPageComponentTest { page in
            //Inside
            XCTAssertEqual(page.component(at: CGPoint(x: 25, y: 25)), .resizeBottomRight)
            XCTAssertEqual(page.component(at: CGPoint(x: 29, y: 25)), .resizeBottomRight)
            XCTAssertEqual(page.component(at: CGPoint(x: 29, y: 29)), .resizeBottomRight)
            XCTAssertEqual(page.component(at: CGPoint(x: 25, y: 29)), .resizeBottomRight)

            //Outside
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 24, y: 24))), .resizeBottomRight)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 29, y: 24))), .resizeBottomRight)
            XCTAssertNil(page.component(at: CGPoint(x: 30, y: 30)))
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 24, y: 29))), .resizeBottomRight)
        }
    }

    func test_component_resizeBottom() throws {
        try self.performPageComponentTest { page in
            //Inside
            XCTAssertEqual(page.component(at: CGPoint(x: 5, y: 27)), .resizeBottom)
            XCTAssertEqual(page.component(at: CGPoint(x: 24, y: 27)), .resizeBottom)
            XCTAssertEqual(page.component(at: CGPoint(x: 24, y: 29)), .resizeBottom)
            XCTAssertEqual(page.component(at: CGPoint(x: 5, y: 29)), .resizeBottom)

            //Outside
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 5, y: 26))), .resizeBottom)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 24, y: 26))), .resizeBottom)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 25, y: 29))), .resizeBottom)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 4, y: 29))), .resizeBottom)
        }
    }

    func test_component_resizeBottomLeft() throws {
        try self.performPageComponentTest { page in
            //Inside
            XCTAssertEqual(page.component(at: CGPoint(x: 0, y: 25)), .resizeBottomLeft)
            XCTAssertEqual(page.component(at: CGPoint(x: 4, y: 25)), .resizeBottomLeft)
            XCTAssertEqual(page.component(at: CGPoint(x: 4, y: 29)), .resizeBottomLeft)
            XCTAssertEqual(page.component(at: CGPoint(x: 0, y: 29)), .resizeBottomLeft)

            //Outside
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 0, y: 24))), .resizeBottomLeft)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 5, y: 24))), .resizeBottomLeft)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 5, y: 29))), .resizeBottomLeft)
            XCTAssertNil(page.component(at: CGPoint(x: -1, y: 30)))
        }
    }

    func test_component_titleBar() throws {
        try self.performPageComponentTest { page in
            //Inside
            XCTAssertEqual(page.component(at: CGPoint(x: 5, y: 3)), .titleBar)
            XCTAssertEqual(page.component(at: CGPoint(x: 24, y: 3)), .titleBar)
            XCTAssertEqual(page.component(at: CGPoint(x: 24, y: 5)), .titleBar)
            XCTAssertEqual(page.component(at: CGPoint(x: 26, y: 5)), .titleBar)
            XCTAssertEqual(page.component(at: CGPoint(x: 26, y: 9)), .titleBar)
            XCTAssertEqual(page.component(at: CGPoint(x: 3, y: 9)), .titleBar)
            XCTAssertEqual(page.component(at: CGPoint(x: 3, y: 5)), .titleBar)
            XCTAssertEqual(page.component(at: CGPoint(x: 5, y: 5)), .titleBar)

            //Outside
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 3, y: 10))), .titleBar)
            XCTAssertNotEqual(try XCTUnwrap(page.component(at: CGPoint(x: 26, y: 10))), .titleBar)
        }
    }

    func test_component_content() throws {
        try self.performPageComponentTest { page in
            //Inside
            XCTAssertEqual(page.component(at: CGPoint(x: 5, y: 10)), .content)
            XCTAssertEqual(page.component(at: CGPoint(x: 24, y: 10)), .content)
            XCTAssertEqual(page.component(at: CGPoint(x: 5, y: 24)), .content)
            XCTAssertEqual(page.component(at: CGPoint(x: 24, y: 24)), .content)
        }
    }



    //MARK: - Helpers
    func layoutEngine(pageTitleHeight: CGFloat = 0,
                      pageResizeEdgeHandleSize: CGFloat = 0,
                      pageResizeCornerHandleSize: CGFloat = 0,
                      pageResizeHandleOffset: CGFloat = 0,
                      contentBorder: CGFloat = 20,
                      arrowWidth: CGFloat = 5) -> CanvasLayoutEngine {
        return CanvasLayoutEngine(configuration: .init(pageTitleHeight: pageTitleHeight,
                                                       pageResizeEdgeHandleSize: pageResizeEdgeHandleSize,
                                                       pageResizeCornerHandleSize: pageResizeCornerHandleSize,
                                                       pageResizeHandleOffset: pageResizeHandleOffset,
                                                       contentBorder: contentBorder,
                                                       arrowWidth: arrowWidth))
    }
}
