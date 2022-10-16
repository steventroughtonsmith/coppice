//
//  CanvasSelectionEventContext.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 03/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

class CanvasSelectionEventContextTests: EventContextTestBase {
    //MARK: - Draw selection rect
    func test_drawSelectionRect_setsLayoutsSelectionRectOnDraggedEvent() throws {
        let eventContext = CanvasSelectionEventContext()

        eventContext.downEvent(at: CGPoint(x: 100, y: 100), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: CGPoint(x: 110, y: 120), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)

        XCTAssertEqual(self.mockLayoutEngine.selectionRect, CGRect(x: 100, y: 100, width: 10, height: 20))
    }

    func test_drawSelectionRect_setsLayoutsSelectionRectToNilOnUpEvent() throws {
        let eventContext = CanvasSelectionEventContext()

        eventContext.downEvent(at: CGPoint(x: 100, y: 100), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: CGPoint(x: 110, y: 120), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        XCTAssertNotNil(self.mockLayoutEngine.selectionRect)
        eventContext.upEvent(at: CGPoint(x: 110, y: 120), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        XCTAssertNil(self.mockLayoutEngine.selectionRect)
    }


    //MARK: - Simple Select
    func test_simpleSelect_deselectsAllOnDownEvent() throws {
        self.mockLayoutEngine.selectedItems = [self.page1, self.page3]
        let eventContext = CanvasSelectionEventContext()

        eventContext.downEvent(at: CGPoint(x: 100, y: 100), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)

        XCTAssertTrue(self.mockLayoutEngine.deselectAllMock.wasCalled)
    }

    func test_simpleSelect_draggingSelectionRectOverPagesTellsLayoutToSelectPagesInRect() throws {
        self.mockLayoutEngine.selectedItems = [self.page2]

        let eventContext = CanvasSelectionEventContext()
        eventContext.downEvent(at: self.page1.titlePoint.minus(x: 10, y: 10), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = []
        eventContext.draggedEvent(at: self.page1.titlePoint.minus(x: 5, y: 5), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = [self.page1, self.page2]
        eventContext.draggedEvent(at: self.page2.contentPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)

        let (pages, expand) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.last)
        XCTAssertEqual(pages, [self.page1, self.page2])
        XCTAssertFalse(expand)
    }

    func test_simpleSelect_draggingSelectionRectOffPageTellsLayoutToSelectJustPagesUnderRect() throws {
        self.mockLayoutEngine.selectedItems = [self.page2]

        let eventContext = CanvasSelectionEventContext()
        eventContext.downEvent(at: self.page1.titlePoint.minus(x: 10, y: 10), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = []
        eventContext.draggedEvent(at: self.page1.titlePoint.minus(x: 5, y: 5), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = [self.page1, self.page2]
        eventContext.draggedEvent(at: self.page2.contentPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = [self.page1]
        eventContext.draggedEvent(at: self.page1.contentPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)

        let (pages, expand) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.last)
        XCTAssertEqual(pages, [self.page1])
        XCTAssertFalse(expand)
    }


    //MARK: - Shift Select
    func test_shiftSelect_doesntDeselectAllOnDownEvent() throws {
        self.mockLayoutEngine.selectedItems = [self.page1, self.page3]
        let eventContext = CanvasSelectionEventContext()

        eventContext.downEvent(at: CGPoint(x: 100, y: 100), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)

        XCTAssertFalse(self.mockLayoutEngine.deselectAllMock.wasCalled)
    }

    func test_shiftSelect_draggingSelectionRectOverUnselectedPagesTellsLayoutToSelectPagesInRectPlusAnyExistingSelectedPagesOutside() throws {
        self.mockLayoutEngine.selectedItems = [self.page3]

        let eventContext = CanvasSelectionEventContext()
        eventContext.downEvent(at: self.page1.titlePoint.minus(x: 10, y: 10), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = []
        eventContext.draggedEvent(at: self.page1.titlePoint.minus(x: 5, y: 5), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = [self.page1, self.page2]
        eventContext.draggedEvent(at: self.page2.contentPoint, modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)

        let (pages, expand) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.last)
        XCTAssertEqual(pages, [self.page1, self.page2, self.page3])
        XCTAssertFalse(expand)
    }

    func test_shiftSelect_draggingSelectionRectOffPreviouslyUnselectedPageTellsLayoutToSelectOnlyPagesInRectPlusAnyExistingSelectedPagesOutside() throws {
        self.mockLayoutEngine.selectedItems = [self.page3]

        let eventContext = CanvasSelectionEventContext()
        eventContext.downEvent(at: self.page1.titlePoint.minus(x: 10, y: 10), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = []
        eventContext.draggedEvent(at: self.page1.titlePoint.minus(x: 5, y: 5), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = [self.page1, self.page2]
        eventContext.draggedEvent(at: self.page2.contentPoint, modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = [self.page1]
        eventContext.draggedEvent(at: self.page1.contentPoint, modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)

        let (pages, expand) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.last)
        XCTAssertEqual(pages, [self.page1, self.page3])
        XCTAssertFalse(expand)
    }

    func test_shiftSelect_draggingSelectionRectOverAlreadySelectedPageDoesntIncludePageInSelection() throws {
        self.mockLayoutEngine.selectedItems = [self.page2, self.page3]

        let eventContext = CanvasSelectionEventContext()
        eventContext.downEvent(at: self.page1.titlePoint.minus(x: 10, y: 10), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = []
        eventContext.draggedEvent(at: self.page1.titlePoint.minus(x: 5, y: 5), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = [self.page1, self.page2]
        eventContext.draggedEvent(at: self.page2.contentPoint, modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)

        let (pages, expand) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.last)
        XCTAssertEqual(pages, [self.page1, self.page3])
        XCTAssertFalse(expand)
    }

    func test_shiftSelect_draggingSelectionRectOffPreviouslySelectedPageIncludesPageInSelection() throws {
        self.mockLayoutEngine.selectedItems = [self.page2, self.page3]

        let eventContext = CanvasSelectionEventContext()
        eventContext.downEvent(at: self.page1.titlePoint.minus(x: 10, y: 10), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = []
        eventContext.draggedEvent(at: self.page1.titlePoint.minus(x: 5, y: 5), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = [self.page1, self.page2]
        eventContext.draggedEvent(at: self.page2.contentPoint, modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = [self.page1]
        eventContext.draggedEvent(at: self.page1.contentPoint, modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)

        let (pages, expand) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.last)
        XCTAssertEqual(pages, [self.page1, self.page2, self.page3])
        XCTAssertFalse(expand)
    }

    func test_shiftSelect_dragOverMultiplePagesAtOnceInvertsSelection() throws {
        self.mockLayoutEngine.selectedItems = [self.page2]

        let eventContext = CanvasSelectionEventContext()
        eventContext.downEvent(at: self.page1.titlePoint.minus(x: 0, y: 10), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = []
        eventContext.draggedEvent(at: self.page3.titlePoint.minus(x: 0, y: 10), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = [self.page1, self.page2, self.page3]
        eventContext.draggedEvent(at: self.page3.contentPoint, modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)

        let (pages, expand) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.last)
        XCTAssertEqual(pages, [self.page1, self.page3])
        XCTAssertFalse(expand)
    }

    func test_shiftSelect_dragOffMultiplePagesAtOnceRestoresInitialSelection() throws {
        self.mockLayoutEngine.selectedItems = [self.page2]

        let eventContext = CanvasSelectionEventContext()
        eventContext.downEvent(at: self.page1.titlePoint.minus(x: 0, y: 10), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = []
        eventContext.draggedEvent(at: self.page3.titlePoint.minus(x: 0, y: 10), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = [self.page1, self.page2, self.page3]
        eventContext.draggedEvent(at: self.page3.contentPoint, modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)
        self.mockLayoutEngine.itemsInCanvasRectMock.returnValue = []
        eventContext.draggedEvent(at: self.page3.titlePoint.minus(x: 0, y: 10), modifiers: .shift, eventCount: 1, in: self.mockLayoutEngine)

        let (pages, expand) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.last)
        XCTAssertEqual(pages, [self.page2])
        XCTAssertFalse(expand)
    }


    //MARK: - Editability
    func test_editability_tellsLayoutEngineToStopEditingPagesOnMouseDown() throws {
        let eventContext = CanvasSelectionEventContext()

        eventContext.downEvent(at: CGPoint(x: 100, y: 100), modifiers: [], eventCount: 1, in: self.mockLayoutEngine)

        XCTAssertTrue(self.mockLayoutEngine.stopEditingPagesMock.wasCalled)
    }



//    func test_selection_mouseUpOnCanvasDeselectsAllPagesIfMouseNotMoved() {
//        self.page1.selected = true
//        self.page2.selected = true
//        self.page3.selected = false
//
//        let eventContext = CanvasSelectionEventContext()
//
//        eventContext.downEvent(at: CGPoint(x: 50, y: 50), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
//        eventContext.upEvent(at: CGPoint(x: 50, y: 50), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
//        XCTAssertTrue(self.mockLayoutEngine.deselectAllMock.wasCalled)
//    }

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
