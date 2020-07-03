//
//  CanvasSelectionEventContext.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 03/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class CanvasSelectionEventContextTests: EventContextTestBase {

    func test_selection_mouseUpOnCanvasDeselectsAllPagesIfMouseNotMoved() {
//        self.page1.selected = true
//        self.page2.selected = true
//        self.page3.selected = false
//
//        let eventContext = CanvasSelectionEventContext()
//
//        eventContext.downEvent(at: CGPoint(x: 50, y: 50), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
//        eventContext.upEvent(at: CGPoint(x: 50, y: 50), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
//        XCTAssertTrue(self.mockLayoutEngine.deselectAllMock.wasCalled)
    }

//    func test_selectionRect_clickingAndDraggingOnCanvasCreatesASelectionRect() throws {
//        XCTAssertNil(self.layoutEngine.selectionRect)
//
//        self.layoutEngine.downEvent(at: CGPoint(x: 50, y: 50))
//        self.layoutEngine.draggedEvent(at: CGPoint(x: 53, y: 53))
//        let rect = try XCTUnwrap(self.layoutEngine.selectionRect)
//        XCTAssertEqual(rect, CGRect(x: 50, y: 50, width: 3, height: 3))
//    }
//
//    func test_selectionRect_drawingSelectionRectOverPagesSelectsThosePages() throws {
//        XCTAssertNil(self.layoutEngine.selectionRect)
//
//        self.layoutEngine.downEvent(at: CGPoint(x: 10, y: 10))
//        self.layoutEngine.draggedEvent(at: CGPoint(x: 85, y: 35))
//
//        let selectedPages = self.layoutEngine.selectedPages
//        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 0]) === self.page2)
//        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 1]) === self.page3)
//    }
//
//    func test_selectionRect_draggingSelectionRectBackOffPageDeselectsThatPage() {
//        XCTAssertNil(self.layoutEngine.selectionRect)
//
//        self.layoutEngine.downEvent(at: CGPoint(x: 10, y: 10))
//        self.layoutEngine.draggedEvent(at: CGPoint(x: 85, y: 35))
//
//        let initialSelectedPages = self.layoutEngine.selectedPages
//        XCTAssertTrue(try XCTUnwrap(initialSelectedPages[safe: 0]) === self.page2)
//        XCTAssertTrue(try XCTUnwrap(initialSelectedPages[safe: 1]) === self.page3)
//
//        self.layoutEngine.draggedEvent(at: CGPoint(x: 45, y: 35))
//        let finalSelectedPages = self.layoutEngine.selectedPages
//        XCTAssertTrue(try XCTUnwrap(finalSelectedPages[safe: 0]) === self.page2)
//    }
//
//    func test_selectionRect_drawingSelectionRectOverPagesWithShiftModifierTogglesSelectionOnThosePages() throws {
//        XCTAssertNil(self.layoutEngine.selectionRect)
//
//        self.layoutEngine.downEvent(at: CGPoint(x: 10, y: 10), modifiers: .shift)
//        self.layoutEngine.draggedEvent(at: CGPoint(x: 85, y: 35), modifiers: .shift)
//
//        let initialSelectedPages = self.layoutEngine.selectedPages
//        XCTAssertTrue(try XCTUnwrap(initialSelectedPages[safe: 0]) === self.page2)
//        XCTAssertTrue(try XCTUnwrap(initialSelectedPages[safe: 1]) === self.page3)
//
//        self.layoutEngine.draggedEvent(at: CGPoint(x: 45, y: 35))
//        let finalSelectedPages = self.layoutEngine.selectedPages
//        XCTAssertTrue(try XCTUnwrap(finalSelectedPages[safe: 0]) === self.page2)
//    }
//
//    func test_selectionRect_drawingSelectionRectOverSelectedPageWithShiftModifierTogglesDeselectsPageAndDraggingOffReselectsPage() throws {
//        XCTAssertNil(self.layoutEngine.selectionRect)
//
//        self.page2.selected = true
//
//        self.layoutEngine.downEvent(at: CGPoint(x: 10, y: 10), modifiers: .shift)
//        self.layoutEngine.draggedEvent(at: CGPoint(x: 85, y: 35), modifiers: .shift)
//
//        let initialSelectedPages = self.layoutEngine.selectedPages
//        XCTAssertTrue(try XCTUnwrap(initialSelectedPages[safe: 0]) === self.page3)
//
//        self.layoutEngine.draggedEvent(at: CGPoint(x: 45, y: 35))
//        let finalSelectedPages = self.layoutEngine.selectedPages
//        XCTAssertTrue(try XCTUnwrap(finalSelectedPages[safe: 0]) === self.page2)
//    }

}
