//
//  CanvasLayoutEngineEventContextFactory.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 05/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest

class CanvasLayoutEngineEventContextFactory: XCTestCase {

    //MARK: - createMouseEventContext(for:in:)
    func test_createMouseEventContext_returnsCanvasSelectionContextIfNoPageAtSuppliedLocation() throws {
        XCTFail()
    }

    func test_createMouseEventContext_movesPageAtSuppliedLocationToFront() throws {
        XCTFail()
    }

    func test_createMouseEventContext_returnsSelectAndMoveContextIfPageTitleBarClicked() throws {
        XCTFail()
    }

    func test_createMouseEventContext_returnsSelectAndMoveContextIfPageContentClicked() throws {
        XCTFail()
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeLeftClicked() throws {
        XCTFail()
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeTopClicked() throws {
        XCTFail()
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeRightClicked() throws {
        XCTFail()
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeBottomClicked() throws {
        XCTFail()
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeTopLeftClicked() throws {
        XCTFail()
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeTopRightClicked() throws {
        XCTFail()
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeBottomRightClicked() throws {
        XCTFail()
    }

    func test_crateMouseEventContext_returnsResizePageEventContextIfResizeBottomLeftClicked() throws {
        XCTFail()
    }


    //MARK: - createKeyEventContext(for:in:)
    func test_createKeyEventContext_returnsNilIfNoPagesAreSelected() throws {
        XCTFail()
    }

    func test_createKeyEventContext_returnsKeyboardMovePageContextIfLeftArrowSupplied() throws {
        XCTFail()
    }

    func test_createKeyEventContext_returnsKeyboardMovePageContextIfRightArrowSupplied() throws {
        XCTFail()
    }

    func test_createKeyEventContext_returnsKeyboardMovePageContextIfUpArrowSupplied() throws {
        XCTFail()
    }

    func test_createKeyEventContext_returnsKeyboardMovePageContextIfDownArrowSupplied() throws {
        XCTFail()
    }

    func test_createKeyEventContext_returnsRemovePageContextIfDeleteKeySupplied() throws {
        XCTFail()
    }

    func test_createKeyEventContext_returnsRemovePageContextIfForwardDeleteKeySupplied() throws {
        XCTFail()
    }

    func test_createKeyEventContext_returnsNilIfOtherKeySupplied() throws {
        XCTFail()
    }
}
