//
//  ImageEditorHotspotLayoutEngineTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 25/02/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Carbon.HIToolbox
import XCTest

@testable import Coppice

class ImageEditorHotspotLayoutEngineTests: XCTestCase {
    var layoutEngine: ImageEditorHotspotLayoutEngine!
    var mockHotspot1: MockImageEditorHotspot!
    var mockHotspot2: MockImageEditorHotspot!
    var mockHotspot3: MockImageEditorHotspot!
    var delegate: MockLayoutEngineDelegate!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockHotspot1 = MockImageEditorHotspot()
        self.mockHotspot2 = MockImageEditorHotspot()
        self.mockHotspot3 = MockImageEditorHotspot()

        self.layoutEngine = ImageEditorHotspotLayoutEngine()
        self.layoutEngine.hotspots = [
            self.mockHotspot1,
            self.mockHotspot2,
            self.mockHotspot3,
        ]

        self.delegate = MockLayoutEngineDelegate()
        self.layoutEngine.delegate = self.delegate
    }

    //MARK: - selectAll()
    func test_selectAll_selectsAllHotspots() throws {
        self.mockHotspot2.isSelected = true
        self.layoutEngine.selectAll()
        XCTAssertTrue(self.mockHotspot1.isSelected)
        XCTAssertTrue(self.mockHotspot2.isSelected)
        XCTAssertTrue(self.mockHotspot3.isSelected)
    }

    func test_selectAll_callsLayoutDidChangeOnDelegateAfterSelectingHotspots() throws {
        self.layoutEngine.selectAll()
        XCTAssertTrue(self.mockHotspot1.isSelected)
        XCTAssertTrue(self.delegate.layoutDidChangeMock.wasCalled)
    }

    //MARK: - deselectAll()
    func test_deselectAll_deselectsAllHotspots() throws {
        self.mockHotspot1.isSelected = true
        self.mockHotspot3.isSelected = true
        self.layoutEngine.deselectAll()
        XCTAssertFalse(self.mockHotspot1.isSelected)
        XCTAssertFalse(self.mockHotspot2.isSelected)
        XCTAssertFalse(self.mockHotspot3.isSelected)
    }

    func test_deselectAll_callsLayoutDidChangeOnDelegateAfterDeselectingHotspots() throws {
        self.mockHotspot1.isSelected = true
        self.layoutEngine.deselectAll()
        XCTAssertFalse(self.mockHotspot1.isSelected)
        XCTAssertTrue(self.delegate.layoutDidChangeMock.wasCalled)
    }

    //MARK: - Editing Hotspot
    func test_editingHotspot_passesDownEventToLastHotspotInArrayThatPassesHitTest() throws {
        self.mockHotspot1.hitTestMock.returnValue = true
        self.mockHotspot3.hitTestMock.returnValue = true

        self.layoutEngine.downEvent(at: CGPoint(x: 12, y: 42), modifiers: .command, eventCount: 1)

        XCTAssertTrue(self.mockHotspot3.downEventMock.wasCalled)

        let arguments = try XCTUnwrap(self.mockHotspot3.downEventMock.arguments.first)
        XCTAssertEqual(arguments.0, CGPoint(x: 12, y: 42))
        XCTAssertEqual(arguments.1, .command)
        XCTAssertEqual(arguments.2, 1)
    }

    func test_editingHotspot_doesntPassDownEventToOtherEventsThatPassHitTest() throws {
        self.mockHotspot1.hitTestMock.returnValue = true
        self.mockHotspot3.hitTestMock.returnValue = true

        self.layoutEngine.downEvent(at: CGPoint(x: 12, y: 42), modifiers: .command, eventCount: 1)

        XCTAssertFalse(self.mockHotspot1.downEventMock.wasCalled)
    }

    func test_editingHotspot_passesDraggedAndUpEventsToHotspotThatWasHitWithDownEvent() throws {
        self.mockHotspot1.hitTestMock.returnValue = true
        self.mockHotspot3.hitTestMock.returnValue = true
        self.mockHotspot3.hotspotPathMock.returnValue = NSBezierPath(rect: CGRect(x: 10, y: 40, width: 20, height: 20))

        self.layoutEngine.downEvent(at: CGPoint(x: 12, y: 42), modifiers: .command, eventCount: 1)
        self.layoutEngine.draggedEvent(at: CGPoint(x: 14, y: 41), modifiers: .command, eventCount: 1)
        self.layoutEngine.draggedEvent(at: CGPoint(x: 16, y: 40), modifiers: .command, eventCount: 1)
        self.layoutEngine.upEvent(at: CGPoint(x: 18, y: 39), modifiers: .command, eventCount: 1)

        XCTAssertTrue(self.mockHotspot3.draggedEventMock.wasCalled)

        let drag1Arguments = try XCTUnwrap(self.mockHotspot3.draggedEventMock.arguments[safe: 0])
        XCTAssertEqual(drag1Arguments.0, CGPoint(x: 14, y: 41))
        XCTAssertEqual(drag1Arguments.1, .command)
        XCTAssertEqual(drag1Arguments.2, 1)

        let drag2Arguments = try XCTUnwrap(self.mockHotspot3.draggedEventMock.arguments[safe: 1])
        XCTAssertEqual(drag2Arguments.0, CGPoint(x: 16, y: 40))
        XCTAssertEqual(drag2Arguments.1, .command)
        XCTAssertEqual(drag2Arguments.2, 1)

        XCTAssertTrue(self.mockHotspot3.upEventMock.wasCalled)
        let upArguments = try XCTUnwrap(self.mockHotspot3.upEventMock.arguments.first)
        XCTAssertEqual(upArguments.0, CGPoint(x: 18, y: 39))
        XCTAssertEqual(upArguments.1, .command)
        XCTAssertEqual(upArguments.2, 1)
    }

    func test_editingHotspot_doesntPassDraggedAndUpEventsToOtherHotspots() throws {
        self.mockHotspot1.hitTestMock.returnValue = true
        self.mockHotspot3.hitTestMock.returnValue = true
        self.mockHotspot3.hotspotPathMock.returnValue = NSBezierPath(rect: CGRect(x: 10, y: 40, width: 20, height: 20))

        self.layoutEngine.downEvent(at: CGPoint(x: 12, y: 42), modifiers: .command, eventCount: 1)
        self.layoutEngine.draggedEvent(at: CGPoint(x: 14, y: 41), modifiers: .command, eventCount: 1)
        self.layoutEngine.draggedEvent(at: CGPoint(x: 16, y: 40), modifiers: .command, eventCount: 1)
        self.layoutEngine.upEvent(at: CGPoint(x: 18, y: 39), modifiers: .command, eventCount: 1)

        XCTAssertFalse(self.mockHotspot1.draggedEventMock.wasCalled)
        XCTAssertFalse(self.mockHotspot1.upEventMock.wasCalled)
    }

    func test_editingHotspot_callsLayoutDidChangeOnDownEvent() throws {
        self.layoutEngine.downEvent(at: CGPoint(x: 12, y: 42), modifiers: .command, eventCount: 1)

        XCTAssertTrue(self.delegate.layoutDidChangeMock.wasCalled)
    }

    func test_editingHotspot_callsLayoutDidChangeOnDraggedEvent() throws {
        self.layoutEngine.downEvent(at: CGPoint(x: 12, y: 42), modifiers: .command, eventCount: 1)
        self.layoutEngine.draggedEvent(at: CGPoint(x: 14, y: 41), modifiers: .command, eventCount: 1)

        XCTAssertTrue(self.delegate.layoutDidChangeMock.wasCalled)
    }

    func test_editingHotspot_callsLayoutDidChangeOnUpEvent() throws {
        self.mockHotspot3.hotspotPathMock.returnValue = NSBezierPath(rect: CGRect(x: 10, y: 40, width: 20, height: 20))
        self.layoutEngine.downEvent(at: CGPoint(x: 12, y: 42), modifiers: .command, eventCount: 1)
        self.layoutEngine.upEvent(at: CGPoint(x: 18, y: 39), modifiers: .command, eventCount: 1)

        XCTAssertTrue(self.delegate.layoutDidChangeMock.wasCalled)
    }


    //Create new rectangle hotspot down/drag/up
    //Create new polygon hotspot series of down/up


    //Delete key affects selected
    func test_deletingHotspot_keyUpWithDeleteKeyRemovesSelectedHotspots() throws {
        self.mockHotspot1.isSelected = true
        self.mockHotspot3.isSelected = true

        XCTAssertTrue(self.layoutEngine.handleKeyDown(with: UInt16(kVK_Delete), modifiers: []))
        XCTAssertTrue(self.layoutEngine.handleKeyUp(with: UInt16(kVK_Delete), modifiers: []))

        XCTAssertEqual(self.layoutEngine.hotspots.count, 1)
        XCTAssertTrue(self.layoutEngine.hotspots[0] === self.mockHotspot2)
    }

    func test_deletingHotspot_callsLayoutDidChangeOnDelegateAfterRemovingHotspots() throws {
        self.mockHotspot1.isSelected = true
        self.mockHotspot3.isSelected = true

        XCTAssertTrue(self.layoutEngine.handleKeyDown(with: UInt16(kVK_Delete), modifiers: []))
        XCTAssertTrue(self.layoutEngine.handleKeyUp(with: UInt16(kVK_Delete), modifiers: []))

        XCTAssertEqual(self.layoutEngine.hotspots.count, 1)

        XCTAssertTrue(self.delegate.layoutDidChangeMock.wasCalled)
    }

    func test_deletingHotspot_callsDidCommitEditOnDelegateAfterRemovingHotspots() throws {
        self.mockHotspot1.isSelected = true
        self.mockHotspot3.isSelected = true

        XCTAssertTrue(self.layoutEngine.handleKeyDown(with: UInt16(kVK_Delete), modifiers: []))
        XCTAssertTrue(self.layoutEngine.handleKeyUp(with: UInt16(kVK_Delete), modifiers: []))

        XCTAssertEqual(self.layoutEngine.hotspots.count, 1)

        XCTAssertTrue(self.delegate.didCommitEditMock.wasCalled)
    }
}

extension ImageEditorHotspotLayoutEngineTests {
    class MockLayoutEngineDelegate: ImageEditorHotspotLayoutEngineDelegate {
        let layoutDidChangeMock = MockDetails<ImageEditorHotspotLayoutEngine, Void>()
        func layoutDidChange(in layoutEngine: ImageEditorHotspotLayoutEngine) {
            self.layoutDidChangeMock.called(withArguments: layoutEngine)
        }

        let didCommitEditMock = MockDetails<ImageEditorHotspotLayoutEngine, Void>()
        func didCommitEdit(in layoutEngine: ImageEditorHotspotLayoutEngine) {
            self.didCommitEditMock.called(withArguments: layoutEngine)
        }
    }
}
