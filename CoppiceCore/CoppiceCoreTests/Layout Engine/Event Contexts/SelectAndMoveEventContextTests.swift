//
//  SelectAndMoveEventContext.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 03/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

class SelectAndMoveEventContextTests: EventContextTestBase {
    //MARK: - Single selection
    func test_singleSelection_clickingOnUnselectedPagesTitleTellsLayoutToSelectJustThatPageOnDownEvent() throws {
        let eventContext = SelectAndMoveEventContext(page: self.page3, editable: true, component: .titleBar)

        let clickPoint = self.page3.titlePoint
        eventContext.downEvent(at: clickPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)

        XCTAssertTrue(self.mockLayoutEngine.selectItemsMock.wasCalled)
        let (pages, extending) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.first)
        XCTAssertEqual(pages, [self.page3])
        XCTAssertFalse(extending)
    }

    func test_singleSelection_clickingOnUnselectedPagesContentTellsLayoutToSelectJustThatPageOnDownEvent() throws {
        let eventContext = SelectAndMoveEventContext(page: self.page3, editable: true, component: .content)

        let clickPoint = self.page3.contentPoint
        eventContext.downEvent(at: clickPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)

        XCTAssertTrue(self.mockLayoutEngine.selectItemsMock.wasCalled)
        let (pages, extending) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.first)
        XCTAssertEqual(pages, [self.page3])
        XCTAssertFalse(extending)
    }

    func test_singleSelection_clickingOnSelectedPagesTitleTellsLayoutToSelectJustThatPageOnUpEvent() throws {
        self.mockLayoutEngine.selectedItems = [self.page1, self.page3]
        let eventContext = SelectAndMoveEventContext(page: self.page3, editable: true, component: .titleBar)

        let clickPoint = self.page3.titlePoint
        eventContext.downEvent(at: clickPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        XCTAssertFalse(self.mockLayoutEngine.selectItemsMock.wasCalled)

        eventContext.upEvent(at: clickPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        let (pages, extending) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.first)
        XCTAssertEqual(pages, [self.page3])
        XCTAssertFalse(extending)
    }

    func test_singleSelection_clickingOnSelectedPagesContentTellsLayoutToSelectJustThatPageOnUpEvent() throws {
        self.mockLayoutEngine.selectedItems = [self.page1, self.page3]
        let eventContext = SelectAndMoveEventContext(page: self.page3, editable: true, component: .content)

        let clickPoint = self.page3.contentPoint
        eventContext.downEvent(at: clickPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        XCTAssertFalse(self.mockLayoutEngine.selectItemsMock.wasCalled)

        eventContext.upEvent(at: clickPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        let (pages, extending) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.first)
        XCTAssertEqual(pages, [self.page3])
        XCTAssertFalse(extending)
    }

    func test_singleSelection_clickingOnSelectedPagesTitleDoesntTellLayoutToSelectPagesIfUpEventLocationDifferent() throws {
        self.page1.selected = true
        self.page3.selected = true
        let eventContext = SelectAndMoveEventContext(page: self.page3, editable: true, component: .titleBar)

        let clickPoint = self.page3.titlePoint
        eventContext.downEvent(at: clickPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        XCTAssertFalse(self.mockLayoutEngine.selectItemsMock.wasCalled)

        eventContext.upEvent(at: clickPoint.plus(.identity), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        XCTAssertFalse(self.mockLayoutEngine.selectItemsMock.wasCalled)
    }

    func test_singleSelection_clickingOnSelectedPagesContentDoesntTellLayoutToSelectPagesIfUpEventLocationDifferent() throws {
        self.page1.selected = true
        self.page3.selected = true
        let eventContext = SelectAndMoveEventContext(page: self.page3, editable: true, component: .content)

        let clickPoint = self.page3.contentPoint
        eventContext.downEvent(at: clickPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        XCTAssertFalse(self.mockLayoutEngine.selectItemsMock.wasCalled)

        eventContext.upEvent(at: clickPoint.plus(.identity), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        XCTAssertFalse(self.mockLayoutEngine.selectItemsMock.wasCalled)
    }


    //MARK: - Invoke Link
    func test_invokeLink_tellsPageToOpenLinkIfDownLocationIsLinkAndPageIsEditable() throws {
        let mockView = MockLayoutEnginePageView()
        mockView.linkAtContentPointMock.returnValue = URL(string: "https://coppiceapp.com")
        self.page1.view = mockView

        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .content)

        eventContext.downEvent(at: .zero, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        XCTAssertTrue(mockView.openLinkMock.wasCalled)
        eventContext.upEvent(at: .zero, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
    }

    func test_invokeLink_doesntTellPageToOpenLinkIfDownLocationIsLinkButPageIsNotEditable() throws {
        let mockView = MockLayoutEnginePageView()
        mockView.linkAtContentPointMock.returnValue = URL(string: "https://coppiceapp.com")
        self.page1.view = mockView

        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: false, component: .content)

        eventContext.downEvent(at: .zero, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        XCTAssertFalse(mockView.openLinkMock.wasCalled)
        eventContext.upEvent(at: .zero, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
    }


    //MARK: - Shift Selection
    func test_shiftSelection_clickingOnUnselectedPagesTitleTellsLayoutToAddPageToSelectionOnDownEvent() throws {
        let clickPoint = self.page1.titlePoint
        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .titleBar)
        eventContext.downEvent(at: clickPoint, modifiers: .shift, eventCount: 0, in: self.mockLayoutEngine)

        XCTAssertTrue(self.mockLayoutEngine.selectItemsMock.wasCalled)
        let (pages, extending) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.first)
        XCTAssertEqual(pages, [self.page1])
        XCTAssertTrue(extending)
    }

    func test_shiftSelection_clickingOnUnselectedPagesContentTellsLayoutToAddPageToSelectionOnDownEvent() throws {
        let clickPoint = self.page1.contentPoint
        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .content)
        eventContext.downEvent(at: clickPoint, modifiers: .shift, eventCount: 0, in: self.mockLayoutEngine)

        XCTAssertTrue(self.mockLayoutEngine.selectItemsMock.wasCalled)
        let (pages, extending) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.first)
        XCTAssertEqual(pages, [self.page1])
        XCTAssertTrue(extending)
    }

    func test_shiftSelection_clickingOnSelectedPagesTitleTellsLayoutToDeselectPageOnDownEvent() throws {
        self.page1.selected = true
        let clickPoint = self.page1.titlePoint
        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .titleBar)
        eventContext.downEvent(at: clickPoint, modifiers: .shift, eventCount: 0, in: self.mockLayoutEngine)

        XCTAssertTrue(self.mockLayoutEngine.deselectItemMock.wasCalled)
        let pages = try XCTUnwrap(self.mockLayoutEngine.deselectItemMock.arguments.first)
        XCTAssertEqual(pages, [self.page1])
    }

    func test_shiftSelection_clickingOnSelectedPagesContentTellsLayoutToDeselectPageOnDownEvent() throws {
        self.page1.selected = true
        let clickPoint = self.page1.contentPoint
        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .content)
        eventContext.downEvent(at: clickPoint, modifiers: .shift, eventCount: 0, in: self.mockLayoutEngine)

        XCTAssertTrue(self.mockLayoutEngine.deselectItemMock.wasCalled)
        let pages = try XCTUnwrap(self.mockLayoutEngine.deselectItemMock.arguments.first)
        XCTAssertEqual(pages, [self.page1])
    }

    func test_shiftSelection_clickingOnPagesTitleTellsDoesntTellLayoutToSelectOnUpEvent() throws {
        let clickPoint = self.page1.titlePoint
        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .titleBar)

        eventContext.downEvent(at: clickPoint, modifiers: .shift, eventCount: 0, in: self.mockLayoutEngine)
        let selectCallCount = self.mockLayoutEngine.selectItemsMock.arguments.count

        eventContext.upEvent(at: clickPoint, modifiers: .shift, eventCount: 0, in: self.mockLayoutEngine)
        XCTAssertEqual(self.mockLayoutEngine.selectItemsMock.arguments.count, selectCallCount)
    }

    func test_shiftSelection_clickingOnPagesContentTellsDoesntTellLayoutToSelectOnUpEvent() throws {
        let clickPoint = self.page1.contentPoint
        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .content)

        eventContext.downEvent(at: clickPoint, modifiers: .shift, eventCount: 0, in: self.mockLayoutEngine)
        let selectCallCount = self.mockLayoutEngine.selectItemsMock.arguments.count

        eventContext.upEvent(at: clickPoint, modifiers: .shift, eventCount: 0, in: self.mockLayoutEngine)
        XCTAssertEqual(self.mockLayoutEngine.selectItemsMock.arguments.count, selectCallCount)
    }


    //MARK: - Move
    func test_moving_draggingByPageTitleMovesThatPage() {
        let page1Point = self.page1.layoutFrame.origin
        self.mockLayoutEngine.selectedItems = [self.page1]

        let offset = CGPoint(x: 5, y: 3)

        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .titleBar)

        let startPoint = page1Point.plus(.identity)
        eventContext.downEvent(at: startPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset.multiplied(by: 0.5)), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)

        let expectedPoint = page1Point.plus(offset)
        XCTAssertEqual(self.page1.layoutFrame.origin, expectedPoint)
    }

    func test_moving_draggingByPageContentMovesThatPage() {
        let page1Point = self.page1.layoutFrame.origin
        self.mockLayoutEngine.selectedItems = [self.page1]

        let offset = CGPoint(x: 5, y: 3)

        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .content)

        let startPoint = self.page1.contentPoint
        eventContext.downEvent(at: startPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset.multiplied(by: 0.5)), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)

        let expectedPoint = page1Point.plus(offset)
        XCTAssertEqual(self.page1.layoutFrame.origin, expectedPoint)
    }

    func test_moving_draggingByPageTitleMovesAllSelectedPages() {
        self.mockLayoutEngine.selectedItems = [self.page2, self.page3]
        let page2Point = self.page2.layoutFrame.origin
        let page3Point = self.page3.layoutFrame.origin

        let offset = CGPoint(x: 7, y: 8)

        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .titleBar)

        let startPoint = page3Point.plus(.identity)
        eventContext.downEvent(at: startPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset.multiplied(by: 0.5)), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)

        let expectedPage2Point = page2Point.plus(offset)
        XCTAssertEqual(self.page2.layoutFrame.origin, expectedPage2Point)
        let expectedPage3Point = page3Point.plus(offset)
        XCTAssertEqual(self.page3.layoutFrame.origin, expectedPage3Point)
    }

    func test_moving_draggingByPageContentMovesAllSelectedPages() {
        self.mockLayoutEngine.selectedItems = [self.page2, self.page3]
        let page2Point = self.page2.layoutFrame.origin
        let page3Point = self.page3.layoutFrame.origin

        let offset = CGPoint(x: 7, y: 8)

        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .content)

        let startPoint = self.page3.contentPoint
        eventContext.downEvent(at: startPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset.multiplied(by: 0.5)), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)

        let expectedPage2Point = page2Point.plus(offset)
        XCTAssertEqual(self.page2.layoutFrame.origin, expectedPage2Point)
        let expectedPage3Point = page3Point.plus(offset)
        XCTAssertEqual(self.page3.layoutFrame.origin, expectedPage3Point)
    }


    //MARK: - Modifying
    func test_modifyEvents_draggingTellsLayoutSelectedPagesWereModified() throws {
        self.mockLayoutEngine.selectedItems = [self.page2, self.page3]

        let offset = CGPoint(x: 7, y: 8)

        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .content)

        let startPoint = self.page3.contentPoint
        eventContext.downEvent(at: startPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset.multiplied(by: 0.5)), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)

        XCTAssertEqual(self.mockLayoutEngine.modifiedItemsMock.arguments.count, 2)
        XCTAssertEqual(self.mockLayoutEngine.modifiedItemsMock.arguments.first, [self.page2, self.page3])
    }

    func test_modifyingEvents_upEventTellsLayoutSelectedPagesWereFinishedModifying() throws {
        self.mockLayoutEngine.selectedItems = [self.page2, self.page3]

        let offset = CGPoint(x: 7, y: 8)

        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .content)

        let startPoint = self.page3.contentPoint
        eventContext.downEvent(at: startPoint, modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset.multiplied(by: 0.5)), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.draggedEvent(at: startPoint.plus(offset), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)
        eventContext.upEvent(at: startPoint.plus(offset), modifiers: [], eventCount: 0, in: self.mockLayoutEngine)

        XCTAssertEqual(self.mockLayoutEngine.finishedModifyingMock.arguments.count, 1)
        XCTAssertEqual(self.mockLayoutEngine.finishedModifyingMock.arguments.first, [self.page2, self.page3])
    }


    //MARK: - Double Click
    func test_doubleClick_downEventWithCount2OnPageTitleSelectsAllChildPages() throws {
        let child1 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 120, y: 120, width: 30, height: 30),
                                      minimumContentSize: .zero)
        let child2 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 150, y: 180, width: 30, height: 30),
                                      minimumContentSize: .zero)
        self.page1.addChild(child1)
        self.page1.addChild(child2)

        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .titleBar)
        eventContext.downEvent(at: self.page1.titlePoint, modifiers: [], eventCount: 2, in: self.mockLayoutEngine)

        let (pages, extend) = try XCTUnwrap(self.mockLayoutEngine.selectItemsMock.arguments.first)
        XCTAssertEqual(pages, [self.page1, child1, child2])
        XCTAssertFalse(extend)
    }

    func test_doubleClick_downEventWithCount2OnPageContentTellsLayoutEngineToStartEditingPageIfEditable() throws {
        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: true, component: .content)

        let clickPoint = self.page1.contentPoint
        eventContext.downEvent(at: clickPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        eventContext.downEvent(at: clickPoint, modifiers: [], eventCount: 2, in: self.mockLayoutEngine)
        eventContext.upEvent(at: clickPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)

        let (page, point) = try XCTUnwrap(self.mockLayoutEngine.startEditingMock.arguments.first)
        XCTAssertEqual(page, self.page1)
        XCTAssertEqual(point, clickPoint)
    }

    func test_doubleClick_downEventWithCount2OnPageContentDoesntTellsLayoutEngineToStartEditingPageIfNotEditable() throws {
        let eventContext = SelectAndMoveEventContext(page: self.page1, editable: false, component: .content)

        let clickPoint = self.page1.contentPoint
        eventContext.downEvent(at: clickPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)
        eventContext.downEvent(at: clickPoint, modifiers: [], eventCount: 2, in: self.mockLayoutEngine)
        eventContext.upEvent(at: clickPoint, modifiers: [], eventCount: 1, in: self.mockLayoutEngine)

        XCTAssertFalse(self.mockLayoutEngine.startEditingMock.wasCalled)
    }
}
