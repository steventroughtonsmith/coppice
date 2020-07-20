//
//  RemovePageEventContextTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 02/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice
@testable import CoppiceCore
import Carbon.HIToolbox

class RemovePageEventContextTests: XCTestCase {
    func test_keyUp_pressingBackspaceWithNothingSelectedDoesNothing() {
        let event = RemovePageEventContext(pages: [])
        let mockEngine = MockLayoutEngine()

        event.keyDown(withCode: UInt16(kVK_Delete), modifiers: [], isARepeat: false, in: mockEngine)
        event.keyUp(withCode: UInt16(kVK_Delete), modifiers: [], in: mockEngine)

        XCTAssertFalse(mockEngine.tellDelegateToRemoveMock.wasCalled)
    }

    func test_keyUp_pressingBackspaceRemovesSelectedPages() {
        let page1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let page2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)

        let event = RemovePageEventContext(pages: [page1, page2])
        let mockEngine = MockLayoutEngine()

        event.keyDown(withCode: UInt16(kVK_Delete), modifiers: [], isARepeat: false, in: mockEngine)
        event.keyUp(withCode: UInt16(kVK_Delete), modifiers: [], in: mockEngine)

        XCTAssertEqual(mockEngine.tellDelegateToRemoveMock.arguments.first, [page1, page2])
    }

    func test_keyUp_pressingDeleteWithNothingSelectedDoesNothing() {
        let event = RemovePageEventContext(pages: [])
        let mockEngine = MockLayoutEngine()

        event.keyDown(withCode: UInt16(kVK_ForwardDelete), modifiers: [], isARepeat: false, in: mockEngine)
        event.keyUp(withCode: UInt16(kVK_ForwardDelete), modifiers: [], in: mockEngine)

        XCTAssertFalse(mockEngine.tellDelegateToRemoveMock.wasCalled)
    }

    func test_keyUp_pressingDeleteRemovesSelectedPages() {
        let page1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let page2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)

        let event = RemovePageEventContext(pages: [page1, page2])
        let mockEngine = MockLayoutEngine()

        event.keyDown(withCode: UInt16(kVK_ForwardDelete), modifiers: [], isARepeat: false, in: mockEngine)
        event.keyUp(withCode: UInt16(kVK_ForwardDelete), modifiers: [], in: mockEngine)

        XCTAssertEqual(mockEngine.tellDelegateToRemoveMock.arguments.first, [page1, page2])
    }

    func test_keyUp_pressingAnotherKeyDoesNothing() {
        let page1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let page2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)

        let event = RemovePageEventContext(pages: [page1, page2])
        let mockEngine = MockLayoutEngine()

        event.keyDown(withCode: UInt16(kVK_Space), modifiers: [], isARepeat: false, in: mockEngine)
        event.keyUp(withCode: UInt16(kVK_Space), modifiers: [], in: mockEngine)

        XCTAssertFalse(mockEngine.tellDelegateToRemoveMock.wasCalled)
    }
}
