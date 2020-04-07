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
        let expectedUUID = UUID()
        let expectedContentFrame = CGRect(x: 31, y: 42, width: 73, height: 37)
        let expectedMinContentSize = CGSize(width: 20, height: 30)
        let page = LayoutEnginePage(id: expectedUUID, contentFrame: expectedContentFrame, minimumContentSize: expectedMinContentSize)

        XCTAssertEqual(page.id, expectedUUID)
        XCTAssertEqual(page.contentFrame, expectedContentFrame)
        XCTAssertEqual(page.minimumContentSize, expectedMinContentSize)
    }

    func test_init_increasesContentSizeIfBelowMinimum() {
        let layoutEngine = self.layoutEngine()
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width:20, height: 40),
                                    minimumContentSize: CGSize(width: 50, height: 60))
        layoutEngine.add([page])
        XCTAssertEqual(page.contentFrame, CGRect(x: 0, y: 0, width: 50, height: 60))
    }


    //MARK: - Size Validation
    func test_validateSize_doesntChangeContentFrameIfBiggerThanMinSize() {
        let layoutEngine = self.layoutEngine()
        let page = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        page.minimumContentSize = CGSize(width: 50, height: 100)
        page.contentFrame = CGRect(x: 0, y: 0, width: 60, height: 110)
        layoutEngine.add([page])

        XCTAssertEqual(page.contentFrame, CGRect(x: 0, y: 0, width: 60, height: 110))
    }

    func test_validateSize_setsContentFrameWidthToMinimumIfSmallerThanMinSize() {
        let layoutEngine = self.layoutEngine()
        let page = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        page.minimumContentSize = CGSize(width: 50, height: 100)
        page.contentFrame = CGRect(x: 0, y: 0, width: 20, height: 110)
        layoutEngine.add([page])

        XCTAssertEqual(page.contentFrame, CGRect(x: 0, y: 0, width: 50, height: 110))
    }

    func test_validateSize_setsContentFrameHeightToMinimumIfSmallerThanMinSize() {
        let layoutEngine = self.layoutEngine()
        let page = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        page.minimumContentSize = CGSize(width: 50, height: 100)
        page.contentFrame = CGRect(x: 0, y: 0, width: 60, height: 80)
        layoutEngine.add([page])

        XCTAssertEqual(page.contentFrame, CGRect(x: 0, y: 0, width: 60, height: 100))
    }


    //MARK: - .minimumLayoutSize
    func test_minimumLayoutSize_matchesContentSizeIfConfigIfShadowBorderAndTitleAreAllZero() {
        let layoutEngine = self.layoutEngine()

        let expectedSize = CGSize(width: 120, height: 40)
        let page = LayoutEnginePage(id: UUID(), contentFrame: .zero, minimumContentSize: expectedSize)
        layoutEngine.add([page])

        XCTAssertEqual(page.minimumLayoutSize, expectedSize)
    }

    func test_minimumLayoutSize_increasesSizeToAccountForShadowBorderAndTitle() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 30,
                                             pageBorderSize: 2,
                                             pageShadowOffset: CanvasLayoutMargins(default: 8, top: 5, bottom: 6),
                                             pageEdgeResizeHandleSize: 7,
                                             pageCornerResizeHandleSize: 12)

        let minimumContentSize = CGSize(width: 120, height: 40)
        let page = LayoutEnginePage(id: UUID(), contentFrame: .zero, minimumContentSize:minimumContentSize)
        layoutEngine.add([page])

        let expectedSize = minimumContentSize.plus(width: 20, height: 43)
        XCTAssertEqual(page.minimumLayoutSize, expectedSize)
    }


    //MARK: - .layoutFrame
    func test_layoutFrame_originMatchesContentFrameOriginIfTitleBorderAndShadowAreAllZero() {
        let layoutEngine = self.layoutEngine()

        let otherPage = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)
        layoutEngine.add([page, otherPage])

        XCTAssertEqual(page.layoutFrame.origin, CGPoint(x: 50, y: 40))
    }

    func test_layoutFrame_get_sizeMatchesContentFrameSizeIfTitleBorderAndShadowAreAllZero() {
        let layoutEngine = self.layoutEngine()

        let otherPage = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)
        layoutEngine.add([page, otherPage])

        XCTAssertEqual(page.layoutFrame.size, CGSize(width: 110, height: 220))
    }

    func test_layoutFrame_get_adjustsOriginAndSizeUsingTitleBorderAndShadow() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 10,
                                             pageBorderSize: 3,
                                             pageShadowOffset: CanvasLayoutMargins(default: 3, left: 8, bottom: 4),
                                             pageEdgeResizeHandleSize: 3,
                                             pageCornerResizeHandleSize: 5,
                                             contentBorder: 20)

        //Add page to change the offset
        let otherPage = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)
        layoutEngine.add([page, otherPage])

        XCTAssertEqual(page.layoutFrame, CGRect(x: 50, y: 40, width: 127, height: 240))
    }

    func test_layoutFrame_set_convertsOriginToPageSpaceBeforeUpdatingContentFrameIfTitleBorderAndShadowAreZero() {
        let layoutEngine = self.layoutEngine()
        let otherPage = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)
        layoutEngine.add([page, otherPage])

        page.layoutFrame = CGRect(x: 60, y: 60, width: 130, height: 240)

        XCTAssertEqual(page.contentFrame.origin, CGPoint(x: 10, y: 20))
    }

    func test_layoutFrame_set_updatesContentFrameWithSuppliedSizeIfTitleBorderAndShadowAreZero() {
        let layoutEngine = self.layoutEngine()
        let otherPage = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)
        layoutEngine.add([page, otherPage])

        page.layoutFrame = CGRect(x: 60, y: 60, width: 130, height: 240)

        XCTAssertEqual(page.contentFrame.size, CGSize(width: 130, height: 240))
    }

    func test_layoutFrame_set_modifiesFrameUsingTitleBorderAndShadowBeforeUpdatingContentFrame() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 10,
                                             pageBorderSize: 6,
                                             pageShadowOffset: CanvasLayoutMargins(default: 2, left: 3, top: 1),
                                             pageEdgeResizeHandleSize: 3,
                                             pageCornerResizeHandleSize: 5,
                                             contentBorder: 20)
        let otherPage = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 110, height: 220), minimumContentSize: .zero)
        layoutEngine.add([page, otherPage])

        page.layoutFrame = CGRect(x: 60, y: 60, width: 130, height: 240)

        XCTAssertEqual(page.contentFrame, CGRect(x: 10, y: 20, width: 113, height: 221))
    }


    //MARK: - .layoutFrameInPageSpace
    func test_layoutFrameInPageSpace_convertsTheLayoutFrameOriginToPageSpace() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 10,
                                             pageBorderSize: 9,
                                             pageShadowOffset: CanvasLayoutMargins(default: 8),
                                             pageEdgeResizeHandleSize: 3,
                                             pageCornerResizeHandleSize: 5,
                                             contentBorder: 20)

        let otherPage = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -30, y: -20, width: 10, height: 10), minimumContentSize: .zero)
        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 220, height: 110), minimumContentSize: .zero)
        layoutEngine.add([page, otherPage])

        XCTAssertEqual(page.layoutFrameInPageSpace, CGRect(origin: CGPoint(x: -17, y: -18), size: page.layoutFrame.size))
    }
    

    //MARK: - .visualPageFrame
    func test_visualPageFrame_isSameSizeAsLayoutFrameWithZeroOriginIfShadowIsZero() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 3,
                                             pageBorderSize: 5,
                                             pageEdgeResizeHandleSize: 3,
                                             pageCornerResizeHandleSize: 5,
                                             contentBorder: 20)

        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 110, height: 220), minimumContentSize: .zero)
        layoutEngine.add([page])

        XCTAssertEqual(page.visualPageFrame, CGRect(origin: .zero, size: page.layoutFrame.size))
    }

    func test_visualPageFrame_isInsetFromLayoutFrameByByShadow() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 0,
                                             pageBorderSize: 3,
                                             pageShadowOffset: CanvasLayoutMargins(left: 1, top: 2, right: 3, bottom: 4),
                                             pageEdgeResizeHandleSize: 3,
                                             pageCornerResizeHandleSize: 5,
                                             contentBorder: 20)

        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 110, height: 220), minimumContentSize: .zero)

        layoutEngine.add([page])

        XCTAssertEqual(page.visualPageFrame, CGRect(x: 1, y: 2, width: page.layoutFrame.width - 4, height: page.layoutFrame.height - 6))
    }

    func test_titleBarFrame_hasSameOriginAndWidthAsVisualFrameAndHeightFromConfig() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 42,
                                             pageBorderSize: 5,
                                             pageShadowOffset: CanvasLayoutMargins(left: 5, top: 6, right: 7, bottom: 8),
                                             pageEdgeResizeHandleSize: 3,
                                             pageCornerResizeHandleSize: 5,
                                             contentBorder: 20)

        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 110, height: 220), minimumContentSize: .zero)
        layoutEngine.add([page])

        var expectedFrame = page.visualPageFrame
        expectedFrame.size.height = 42
        XCTAssertEqual(page.titleBarFrame, expectedFrame)
    }

    func test_contentContainerFrame_originIsInsetByShadowTitleAndBorderAndSizeMatchesContentFrame() {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 42,
                                             pageBorderSize: 4,
                                             pageShadowOffset: CanvasLayoutMargins(left: 2, top: 6, right: 4, bottom: 1),
                                             pageEdgeResizeHandleSize: 3,
                                             pageCornerResizeHandleSize: 5,
                                             contentBorder: 20)

        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 110, height: 220), minimumContentSize: .zero)
        layoutEngine.add([page])

        XCTAssertEqual(page.contentContainerFrame, CGRect(x: 6, y: 48, width: 110, height: 220))
    }


    //MARK: - component(at:)
    func performPageComponentTest(_ block: (LayoutEnginePage) throws -> Void) throws {
        let layoutEngine = self.layoutEngine(pageTitleHeight: 10,
                                             pageEdgeResizeHandleSize: 3,
                                             pageCornerResizeHandleSize: 5,
//                                             pageResizeHandleOffset: 0,
                                             contentBorder: 20)

        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 40, width: 30, height: 20), minimumContentSize: .zero)
        layoutEngine.add([page])
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


    //MARK: - addChild(_:)
    func test_addChild_setsParentOfSuppliedChildToReceiver() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 100, height: 200), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 30, width: 50, height: 60), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertEqual(child.parent, root)
    }

    func test_addChild_assignsChildLeftDirectionIfCenterInsideLeftOfParentRect() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -5, y: -5, width: 20, height: 20), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .left).contains(child))
    }

    func test_addChild_assignsChildRightDirectionifCenterInsideRightOfParentRect() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 40, width: 15, height: 15), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .right).contains(child))
    }

    func test_addChild_assignsChildLeftDirectionIfCenterWithinTopAndBottomOfParentAndToLeft() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -40, y: -10, width: 20, height: 30), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .left).contains(child))
    }

    func test_addChild_assignsChildRightDirectionIfCenterWithinTopAndBottomOfParentAndToRight() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 40, y: 50, width: 10, height: 20), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .right).contains(child))
    }

    func test_addChild_assignsChildTopDirectionIfCenterWithinLeftAndRightOfParentAndToTop() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -5, y: -30, width: 15, height: 20), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .top).contains(child))
    }

    func test_addChild_assignsChildBottomDirectionifCenterWithinLeftAndRightOfParentAndToBottom() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 70, width: 15, height: 30), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .bottom).contains(child))
    }

    func test_addChild_assignsChildLeftDirectionIfCenterIsToTopLeftButBelowDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -7, y: -6, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .left).contains(child))
    }

    func test_addChild_assignsChildLeftDirectionIfCenterIsToTopLeftAndOnDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -7, y: -7, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .left).contains(child))
    }

    func test_addChild_assignsChildTopDirectionIfCenterIsToTopLeftAndAboveDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -7, y: -8, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .top).contains(child))
    }

    func test_addChild_assignsChildTopDirectionIfCenterIsToTopRightAndAboveDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 27, y: -8, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .top).contains(child))
    }

    func test_addChild_assignsChildTopDirectionIfCenterIsToTopRightAndOnDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 27, y: -7, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .top).contains(child))
    }

    func test_addChild_assignsChildRightDirectionIfCenterIsToTopRightAndBelowDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 27, y: -6, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .right).contains(child))
    }

    func test_addChild_assignsChildRightDirectionIfCenterIsToBottomRightAndAboveDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 27, y: 56, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .right).contains(child))
    }

    func test_addChild_assignsChildRightDirctionIfCenterIsToBottomRightAndOnDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 27, y: 57, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .right).contains(child))
    }

    func test_addChild_assignsChildBottomDirectionIfCenterIsToBottomRightAndBelowDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 27, y: 58, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .bottom).contains(child))
    }

    func test_addChild_assignsChildBottomDirectionIfCenterIsToBottomLeftAndBelowDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -7, y: 58, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .bottom).contains(child))
    }

    func test_addChild_assignChildBottomDirectionIfCenterIsToBottomLeftAndOnDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -7, y: 57, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .bottom).contains(child))
    }

    func test_addChild_assignChildLeftDirectionIfCenterIsToBottomLeftAndAboveDiagonal() {
        let layoutEngine = self.layoutEngine()
        let root = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 30, height: 60), minimumContentSize: .zero)
        let child = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: -7, y: 56, width: 10, height: 10), minimumContentSize: .zero)
        root.addChild(child)
        layoutEngine.add([root, child])

        XCTAssertTrue(root.children(for: .left).contains(child))
    }


    //MARK: - .allDescendents
    func test_allDesecendents_returnsEmptyArrayIfSuppliedPageHasNoChildren() {
        let layoutEngine = self.layoutEngine()
        let page1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let page2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        //Add child to other page just to be sure
        let otherPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)

        layoutEngine.add([page1, page2, otherPage])
        XCTAssertEqual(page2.allDescendants, [])
    }

    func test_allDesecendents_returnsPagesThatHaveSuppliedPageAsParentID() {
        let layoutEngine = self.layoutEngine()
        let page1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let page2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        //Add child to other page just to be sure
        let otherPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        page2.addChild(otherPage)

        let child1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let child2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        page1.addChild(child1)
        page1.addChild(child2)

        layoutEngine.add([page1, page2, otherPage, child1, child2])

        let children = page1.allDescendants
        XCTAssertEqual(children.count, 2)
        XCTAssertTrue(children.contains(child1))
        XCTAssertTrue(children.contains(child2))
    }

    func test_allDesecendents_returnsAllChildrenGrandChildrenEtcOfSuppliedPage() {
        let layoutEngine = self.layoutEngine()
        let page1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let page2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let page3 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        //Add child to other page just to be sure
        let otherPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        page2.addChild(otherPage)

        let child1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        page3.addChild(child1)
        let child2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        page3.addChild(child2)
        let grandchild1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        child1.addChild(grandchild1)
        let grandchild2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        child2.addChild(grandchild2)
        let grandchild3 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        child2.addChild(grandchild3)
        let greatGrandchild1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        grandchild1.addChild(greatGrandchild1)
        let greatGrandchild2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        grandchild1.addChild(greatGrandchild2)

        layoutEngine.add([page1, page2, page3, otherPage, child1, child2, grandchild1, grandchild2, grandchild3, greatGrandchild1, greatGrandchild2])

        let children = page3.allDescendants
        XCTAssertEqual(children.count, 7)
        XCTAssertTrue(children.contains(child1))
        XCTAssertTrue(children.contains(child2))
        XCTAssertTrue(children.contains(grandchild1))
        XCTAssertTrue(children.contains(grandchild2))
        XCTAssertTrue(children.contains(grandchild3))
        XCTAssertTrue(children.contains(greatGrandchild1))
        XCTAssertTrue(children.contains(greatGrandchild2))
    }



    //MARK: - Helpers
    func layoutEngine(pageTitleHeight: CGFloat = 0,
                      pageBorderSize: CGFloat = 0,
                      pageShadowOffset: CanvasLayoutMargins = .zero,
                      pageEdgeResizeHandleSize: CGFloat = 0,
                      pageCornerResizeHandleSize: CGFloat = 0,
                      contentBorder: CGFloat = 20,
                      arrowHeadSize: CGFloat = 5) -> CanvasLayoutEngine {
        return CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: pageTitleHeight,
                                                                   borderSize: pageBorderSize,
                                                                   shadowOffset: pageShadowOffset,
                                                                   edgeResizeHandleSize: pageEdgeResizeHandleSize,
                                                                   cornerResizeHandleSize: pageCornerResizeHandleSize),
                                                       contentBorder: contentBorder,
                                                       arrow: .standard))
    }
}
