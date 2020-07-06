//
//  CanvasLayoutEngineEventContextFactoryTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 05/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice
import Carbon.HIToolbox

class CanvasLayoutEngineEventContextFactoryTests: XCTestCase {

    var mockLayoutEngine: MockLayoutEngine!

    var factory: CanvasLayoutEngineEventContextFactory!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.mockLayoutEngine = MockLayoutEngine()
        self.factory = CanvasLayoutEngineEventContextFactory()
    }

    //MARK: - createMouseEventContext(for:in:)
    func test_createMouseEventContext_returnsCanvasSelectionContextIfNoPageAtSuppliedLocation() throws {
        let context = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        XCTAssertTrue(context is CanvasSelectionEventContext)
    }

    func test_createMouseEventContext_movesPageAtSuppliedLocationToFront() throws {
        let page = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page
        _ = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        XCTAssertTrue(self.mockLayoutEngine.movePageToFrontMock.wasCalled)
        XCTAssertEqual(self.mockLayoutEngine.movePageToFrontMock.arguments.first, page)
    }

    func test_createMouseEventContext_returnsNilIfNoComponentFoundForpage() throws {
        let page = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page

        let context = self.factory.createMouseEventContext(for: CGPoint(x: 0, y: 0), in: self.mockLayoutEngine)
        XCTAssertNil(context)
    }

    func test_createMouseEventContext_returnsSelectAndMoveContextIfPageTitleBarClicked() throws {
        let page = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        page.testComponent = .titleBar

        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page

        let context = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? SelectAndMoveEventContext)
        XCTAssertEqual(typedContext.page, page)
    }

    func test_createMouseEventContext_returnsSelectAndMoveContextIfPageContentClicked() throws {
        let page = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        page.testComponent = .content

        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page

        let context = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? SelectAndMoveEventContext)
        XCTAssertEqual(typedContext.page, page)
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeLeftClicked() throws {
        let page = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        page.testComponent = .resizeLeft

        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page

        let context = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? ResizePageEventContext)
        XCTAssertEqual(typedContext.page, page)
        XCTAssertEqual(typedContext.component, .resizeLeft)
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeTopClicked() throws {
        let page = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        page.testComponent = .resizeTop

        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page

        let context = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? ResizePageEventContext)
        XCTAssertEqual(typedContext.page, page)
        XCTAssertEqual(typedContext.component, .resizeTop)
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeRightClicked() throws {
        let page = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        page.testComponent = .resizeRight

        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page

        let context = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? ResizePageEventContext)
        XCTAssertEqual(typedContext.page, page)
        XCTAssertEqual(typedContext.component, .resizeRight)
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeBottomClicked() throws {
        let page = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        page.testComponent = .resizeBottom

        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page

        let context = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? ResizePageEventContext)
        XCTAssertEqual(typedContext.page, page)
        XCTAssertEqual(typedContext.component, .resizeBottom)
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeTopLeftClicked() throws {
        let page = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        page.testComponent = .resizeTopLeft

        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page

        let context = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? ResizePageEventContext)
        XCTAssertEqual(typedContext.page, page)
        XCTAssertEqual(typedContext.component, .resizeTopLeft)
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeTopRightClicked() throws {
        let page = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        page.testComponent = .resizeTopRight

        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page

        let context = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? ResizePageEventContext)
        XCTAssertEqual(typedContext.page, page)
        XCTAssertEqual(typedContext.component, .resizeTopRight)
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeBottomRightClicked() throws {
        let page = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        page.testComponent = .resizeBottomRight

        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page

        let context = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? ResizePageEventContext)
        XCTAssertEqual(typedContext.page, page)
        XCTAssertEqual(typedContext.component, .resizeBottomRight)
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeBottomLeftClicked() throws {
        let page = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        page.testComponent = .resizeBottomLeft

        self.mockLayoutEngine.pageAtCanvasPointMock.returnValue = page

        let context = self.factory.createMouseEventContext(for: CGPoint(x: 20, y: 30), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? ResizePageEventContext)
        XCTAssertEqual(typedContext.page, page)
        XCTAssertEqual(typedContext.component, .resizeBottomLeft)
    }


    //MARK: - createKeyEventContext(for:in:)
    func test_createKeyEventContext_returnsNilIfNoPagesAreSelected() throws {
        let context = self.factory.createKeyEventContext(for: UInt16(kVK_LeftArrow), in: self.mockLayoutEngine)
        XCTAssertNil(context)
    }

    func test_createKeyEventContext_returnsKeyboardMovePageContextIfLeftArrowSupplied() throws {
        let page1 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        let page2 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 120, y: 120, width: 30, height: 30))
        self.mockLayoutEngine.selectedPages = [page1, page2]

        let context = self.factory.createKeyEventContext(for: UInt16(kVK_LeftArrow), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? KeyboardMovePageEventContext)
        XCTAssertEqual(typedContext.pages, [page1, page2])
    }

    func test_createKeyEventContext_returnsKeyboardMovePageContextIfRightArrowSupplied() throws {
        let page1 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        let page2 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 120, y: 120, width: 30, height: 30))
        self.mockLayoutEngine.selectedPages = [page1, page2]

        let context = self.factory.createKeyEventContext(for: UInt16(kVK_RightArrow), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? KeyboardMovePageEventContext)
        XCTAssertEqual(typedContext.pages, [page1, page2])
    }

    func test_createKeyEventContext_returnsKeyboardMovePageContextIfUpArrowSupplied() throws {
        let page1 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        let page2 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 120, y: 120, width: 30, height: 30))
        self.mockLayoutEngine.selectedPages = [page1, page2]

        let context = self.factory.createKeyEventContext(for: UInt16(kVK_UpArrow), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? KeyboardMovePageEventContext)
        XCTAssertEqual(typedContext.pages, [page1, page2])
    }

    func test_createKeyEventContext_returnsKeyboardMovePageContextIfDownArrowSupplied() throws {
        let page1 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        let page2 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 120, y: 120, width: 30, height: 30))
        self.mockLayoutEngine.selectedPages = [page1, page2]

        let context = self.factory.createKeyEventContext(for: UInt16(kVK_DownArrow), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? KeyboardMovePageEventContext)
        XCTAssertEqual(typedContext.pages, [page1, page2])
    }

    func test_createKeyEventContext_returnsRemovePageContextIfDeleteKeySupplied() throws {
        let page1 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        let page2 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 120, y: 120, width: 30, height: 30))
        self.mockLayoutEngine.selectedPages = [page1, page2]

        let context = self.factory.createKeyEventContext(for: UInt16(kVK_Delete), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? RemovePageEventContext)
        XCTAssertEqual(typedContext.pages, [page1, page2])
    }

    func test_createKeyEventContext_returnsRemovePageContextIfForwardDeleteKeySupplied() throws {
        let page1 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        let page2 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 120, y: 120, width: 30, height: 30))
        self.mockLayoutEngine.selectedPages = [page1, page2]

        let context = self.factory.createKeyEventContext(for: UInt16(kVK_ForwardDelete), in: self.mockLayoutEngine)
        let typedContext = try XCTUnwrap(context as? RemovePageEventContext)
        XCTAssertEqual(typedContext.pages, [page1, page2])
    }

    func test_createKeyEventContext_returnsNilIfOtherKeySupplied() throws {
        let page1 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        let page2 = TestLayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 120, y: 120, width: 30, height: 30))
        self.mockLayoutEngine.selectedPages = [page1, page2]

        let context = self.factory.createKeyEventContext(for: UInt16(kVK_Space), in: self.mockLayoutEngine)
        XCTAssertNil(context)
    }
}
