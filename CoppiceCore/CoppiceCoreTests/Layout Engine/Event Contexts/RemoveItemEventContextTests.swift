//
//  RemovePageEventContextTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 02/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Carbon.HIToolbox
@testable import CoppiceCore
import XCTest

//TODO: Rename

class RemoveItemEventContextTests: XCTestCase {
    func test_keyUp_pressingBackspaceWithNothingSelectedDoesNothing() {
        let event = RemoveItemEventContext(items: [])
        let mockEngine = MockLayoutEngine()

        event.keyDown(withCode: UInt16(kVK_Delete), modifiers: [], isARepeat: false, in: mockEngine)
        event.keyUp(withCode: UInt16(kVK_Delete), modifiers: [], in: mockEngine)

        XCTAssertFalse(mockEngine.tellDelegateToRemoveMock.wasCalled)
    }

    func test_keyUp_pressingBackspaceRemovesSelectedLinksPages() {
        let page1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let page2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let link = LayoutEngineLink(id: UUID(), pageLink: nil, sourcePageID: UUID(), destinationPageID: UUID())

        let event = RemoveItemEventContext(items: [page1, page2, link])
        let mockEngine = MockLayoutEngine()

        event.keyDown(withCode: UInt16(kVK_Delete), modifiers: [], isARepeat: false, in: mockEngine)
        event.keyUp(withCode: UInt16(kVK_Delete), modifiers: [], in: mockEngine)

        XCTAssertEqual(mockEngine.tellDelegateToRemoveMock.arguments.first, [page1, page2, link])
    }

    func test_keyUp_pressingDeleteWithNothingSelectedDoesNothing() {
        let event = RemoveItemEventContext(items: [])
        let mockEngine = MockLayoutEngine()

        event.keyDown(withCode: UInt16(kVK_ForwardDelete), modifiers: [], isARepeat: false, in: mockEngine)
        event.keyUp(withCode: UInt16(kVK_ForwardDelete), modifiers: [], in: mockEngine)

        XCTAssertFalse(mockEngine.tellDelegateToRemoveMock.wasCalled)
    }

    func test_keyUp_pressingDeleteRemovesSelectedLinksAndPages() {
        let page1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let page2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let link = LayoutEngineLink(id: UUID(), pageLink: nil, sourcePageID: UUID(), destinationPageID: UUID())

        let event = RemoveItemEventContext(items: [page1, page2, link])
        let mockEngine = MockLayoutEngine()

        event.keyDown(withCode: UInt16(kVK_ForwardDelete), modifiers: [], isARepeat: false, in: mockEngine)
        event.keyUp(withCode: UInt16(kVK_ForwardDelete), modifiers: [], in: mockEngine)

        XCTAssertEqual(mockEngine.tellDelegateToRemoveMock.arguments.first, [page1, page2, link])
    }

    func test_keyUp_pressingAnotherKeyDoesNothing() {
        let page1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let page2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)

        let event = RemoveItemEventContext(items: [page1, page2])
        let mockEngine = MockLayoutEngine()

        event.keyDown(withCode: UInt16(kVK_Space), modifiers: [], isARepeat: false, in: mockEngine)
        event.keyUp(withCode: UInt16(kVK_Space), modifiers: [], in: mockEngine)

        XCTAssertFalse(mockEngine.tellDelegateToRemoveMock.wasCalled)
    }
}
