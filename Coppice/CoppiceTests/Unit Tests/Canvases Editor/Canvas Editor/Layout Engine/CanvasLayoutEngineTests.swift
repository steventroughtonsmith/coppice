//
//  CanvasLayoutEngineTests.swift
//  Canvas FinalTests
//
//  Created by Martin Pilkington on 31/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice
import Carbon.HIToolbox

let testLayoutASCII = """
          |
          |       ____
     ___  |      | 3  |
    | 2 | |      |____|
    |   | |
----|---|-|------------
    |   | |
    |___| |
          |
          |         _
          |        |1|
          |
"""

//Need to move events out one by one
//Need to add new tests that check layout engine calls eventContextFactory
//Need to add new tests that check layout engine calls context returned from context factory
//Need to add new test case that tests the standard factory



class CanvasLayoutEngineTests: XCTestCase {

    var mockContextFactory = MockEventContextFactory()
    var layoutEngine: CanvasLayoutEngine!
    var page1: LayoutEnginePage!
    var page2: LayoutEnginePage!
    var page3: LayoutEnginePage!
    var contentFrame: CGRect = .zero
    var expectedOffset: CGPoint!

    let contentBorder: CGFloat = 20

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        let config = CanvasLayoutEngine.Configuration(page: .init(titleHeight: 5,
                                                                  borderSize: 0,
                                                                  shadowOffset: .zero,
                                                                  edgeResizeHandleSize: 1,
                                                                  cornerResizeHandleSize: 1),
                                                      contentBorder: self.contentBorder,
                                                      arrow: .standard)

        self.layoutEngine = CanvasLayoutEngine(configuration: config, eventContextFactory: self.mockContextFactory)

        self.page1 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 40, y: 40, width: 10, height: 10),
                                      minimumContentSize: CGSize(width: 0, height: 0))

        self.page2 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: -30, y: -20, width: 20, height: 40),
                                      minimumContentSize: CGSize(width: 0, height: 0))

        self.page3 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 30, y: -30, width: 30, height: 20),
                                      minimumContentSize: CGSize(width: 0, height: 0))
        self.layoutEngine.add([self.page1, self.page2, self.page3])

        self.contentFrame = self.page1.layoutFrame.union(self.page2.layoutFrame).union(self.page3.layoutFrame)
        self.expectedOffset = CGPoint(x: 50, y: 55) //This is (50, 50) for the content frame, but we have a 5pt title which pushes the y up a bit
    }

    override func tearDown() {
        self.layoutEngine = nil
        self.page1 = nil
        self.page2 = nil
        self.page3 = nil
        self.contentFrame = .zero
    }

    //MARK: - Adding/Removing Pages
    func test_addPage_addsPageWithSuppliedValuesToPagesArray() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 1, width: 2, height: 3),
                                    minimumContentSize: CGSize(width: 4, height: 5))
        self.layoutEngine.add([page])
        XCTAssertTrue(self.layoutEngine.pages.contains(page))
    }

    func test_addPage_setsLayoutEngineOfSuppliedPages() throws {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 1, width: 2, height: 3),
                                    minimumContentSize: CGSize(width: 4, height: 5))
        self.layoutEngine.add([page])
        XCTAssertTrue(page.layoutEngine === self.layoutEngine)
    }

    func test_removePages_removesSuppliedPagesFromPagesArray() throws {
        XCTAssertTrue(self.layoutEngine.pages.contains(self.page1))
        XCTAssertTrue(self.layoutEngine.pages.contains(self.page3))

        self.layoutEngine.remove([self.page1, self.page3])

        XCTAssertFalse(self.layoutEngine.pages.contains(self.page1))
        XCTAssertTrue(self.layoutEngine.pages.contains(self.page2))
        XCTAssertFalse(self.layoutEngine.pages.contains(self.page3))
    }


    //MARK: - Updating Pages
    func test_updateFrame_updatesTheFrameOfPageWithSuppliedUUID() throws {
        let expectedContentFrame = CGRect(x: 35, y: 35, width: 20, height: 20)
        self.layoutEngine.updateContentFrame(expectedContentFrame, ofPageWithID: self.page1.id)
        XCTAssertEqual(self.page1.contentFrame, expectedContentFrame)
    }

    func test_updateFrame_updatesCanvasSizeIfNewFrameChangesSize() throws {
        let expectedCanvasSize = self.layoutEngine.canvasSize.plus(CGSize(width: 10, height: 10))
        self.layoutEngine.updateContentFrame(CGRect(x: 30, y: -40, width: 40, height: 20), ofPageWithID: self.page3.id)
        XCTAssertEqual(self.layoutEngine.canvasSize, expectedCanvasSize)
    }

    func test_updateFrame_notifiesViewOfLayoutChange() throws {
        let view = TestCanvasView()
        view.viewPortFrame = CGRect(x: 50, y: 50, width: 10, height: 10)
        self.layoutEngine.view = view
        self.layoutEngine.updateContentFrame(CGRect(x: -20, y: -10, width: 20, height: 40), ofPageWithID: self.page2.id)

        let expectedContext = CanvasLayoutEngine.LayoutContext(sizeChanged: true, pageOffsetChange: CGPoint(x: -10, y: 0))
        XCTAssertEqual(view.context, expectedContext)
    }

    func test_updateFrame_doesntUpdateLayoutIfFrameHasNotChanged() throws {
        let view = TestCanvasView()
        view.viewPortFrame = CGRect(x: 50, y: 50, width: 10, height: 10)
        self.layoutEngine.view = view
        self.layoutEngine.updateContentFrame(CGRect(x: -30, y: -20, width: 20, height: 40), ofPageWithID: self.page2.id)

        XCTAssertNil(view.context)
    }


    //MARK: - Point Conversion
    func test_pointConversion_convertsPointFromPageSpaceToCanvasSpaceForEmptyEngine() throws {
        let basePoint = CGPoint(x: 10, y: 42)

        let emptyEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 5,
                                                                              borderSize: 0,
                                                                              shadowOffset: .zero,
                                                                              edgeResizeHandleSize: 1,
                                                                              cornerResizeHandleSize: 1),
                                                                  contentBorder: 20,
                                                                  arrow: .standard))

        let expectedPoint = basePoint
        XCTAssertEqual(emptyEngine.convertPointToCanvasSpace(basePoint), expectedPoint)
    }

    func test_pointConversion_convertsPointFromPageSpaceToCanvasSpace() throws {
        let basePoint = CGPoint(x: 10, y: 42)

        let expectedPoint = basePoint.plus(self.expectedOffset)
        XCTAssertEqual(self.layoutEngine.convertPointToCanvasSpace(basePoint), expectedPoint)
    }

    func test_pointConversion_convertsPointFromCanvasSpaceToPageSpaceForEmptyEngine() throws {
        let basePoint = CGPoint(x: 15, y: 31)

        let emptyEngine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 5,
                                                                              borderSize: 0,
                                                                              shadowOffset: .zero,
                                                                              edgeResizeHandleSize: 1,
                                                                              cornerResizeHandleSize: 1),
                                                                  contentBorder: 20,
                                                                  arrow: .standard))
        let expectedPoint = basePoint
        XCTAssertEqual(emptyEngine.convertPointToPageSpace(basePoint), expectedPoint)
    }

    func test_pointConversion_convertsPointFromCanvasSpaceToPageSpace() throws {
        let basePoint = CGPoint(x: 65, y: 81)

        let expectedPoint = basePoint.minus(self.expectedOffset)
        XCTAssertEqual(self.layoutEngine.convertPointToPageSpace(basePoint), expectedPoint)
    }


    //MARK: - selectAll()
    func test_selectAll_selectsAllPagesIfNoneWereSelected() throws {
        self.layoutEngine.selectAll()
        XCTAssertTrue(self.page1.selected)
        XCTAssertTrue(self.page2.selected)
        XCTAssertTrue(self.page3.selected)
    }

    func test_selectAll_selectsAllPagesEvenIfSomeWereAlreadySelected() throws {
        self.page2.selected = true
        self.layoutEngine.selectAll()
        XCTAssertTrue(self.page1.selected)
        XCTAssertTrue(self.page2.selected)
        XCTAssertTrue(self.page3.selected)
    }

    func test_selectAll_doesntChangeSelectionIfAllWereAlreadySelected() throws {
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.selectAll()
        XCTAssertTrue(self.page1.selected)
        XCTAssertTrue(self.page2.selected)
        XCTAssertTrue(self.page3.selected)
    }

    func test_selectAll_updatesTheEnabledPage() throws {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        self.layoutEngine.select([self.page3])
        XCTAssertTrue(self.layoutEngine.enabledPage === self.page3)

        self.layoutEngine.selectAll()

        XCTAssertNil(self.layoutEngine.enabledPage)

    }

    func test_selectAll_informsViewOfLayoutChange() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.selectAll()

        let context = try XCTUnwrap(view.context)
        XCTAssertTrue(context.selectionChanged)
    }


    //MARK: - deselectAll()
    func test_deselectAll_deselectsAllPagesIfAllWereSelected() throws {
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.deselectAll()
        XCTAssertFalse(self.page1.selected)
        XCTAssertFalse(self.page2.selected)
        XCTAssertFalse(self.page3.selected)
    }

    func test_deselectAll_deselectsAllPagesIfSomeWereSelected() throws {
        self.page1.selected = true
        self.page3.selected = true
        self.layoutEngine.deselectAll()
        XCTAssertFalse(self.page1.selected)
        XCTAssertFalse(self.page2.selected)
        XCTAssertFalse(self.page3.selected)
    }

    func test_deselectAll_doesntChangeSelectionIfNoneWereAlreadySelected() throws {
        self.layoutEngine.deselectAll()
        XCTAssertFalse(self.page1.selected)
        XCTAssertFalse(self.page2.selected)
        XCTAssertFalse(self.page3.selected)
    }

    func test_deselectAll_updatesTheEnabledPage() throws {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        self.layoutEngine.select([self.page3])
        XCTAssertTrue(self.layoutEngine.enabledPage === self.page3)

        self.layoutEngine.deselectAll()

        XCTAssertNil(self.layoutEngine.enabledPage)
    }

    func test_deselectAll_informsViewOfLayoutChange() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.deselectAll()

        let context = try XCTUnwrap(view.context)
        XCTAssertTrue(context.selectionChanged)
    }


    //MARK: - Enabled Page
    func test_enabledPage_isNilWhenNoPageSelected() throws {
        self.layoutEngine.finishedModifying([])

        XCTAssertNil(self.layoutEngine.enabledPage)
    }

    func test_enabledPage_isSetToSelectedPageIfSinglePageSelected() throws {
        self.page2.selected = true
        self.layoutEngine.finishedModifying([])

        XCTAssertEqual(self.layoutEngine.enabledPage, self.page2)
    }

    func test_enabledPage_isNilIfMultiplePagesSelected() throws {
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.finishedModifying([])

        XCTAssertNil(self.layoutEngine.enabledPage)
    }

    func test_enabledPage_isSetToSelectedPageIfAllOtherPagesAreDeselected() throws {
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.finishedModifying([])
        XCTAssertNil(self.layoutEngine.enabledPage)

        self.page2.selected = false
        self.layoutEngine.finishedModifying([])
        XCTAssertEqual(self.layoutEngine.enabledPage, self.page3)
    }


    //MARK: - .selectedPages
    func test_selectedPages_returnsAllPagesWithSelectedTrue() throws {
        self.page1.selected = true
        self.page2.selected = true

        let selectedPages = self.layoutEngine.selectedPages
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 0]) === self.page1)
        XCTAssertTrue(try XCTUnwrap(selectedPages[safe: 1]) === self.page2)
    }


    //MARK: - select(_:extendingSelection:)
    func test_selectPages_addsPagesToSelectionIfExtendingSelectionIsTrue() throws {
        self.page1.selected = true
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 1)

        self.layoutEngine.select([self.page2, self.page3], extendingSelection: true)

        XCTAssertEqual(self.layoutEngine.selectedPages, [self.page1, self.page2, self.page3])
    }

    func test_selectPages_deselectsAllOtherPagesIfExtendingSelectionIsNotTrue() throws {
        self.page2.selected = true
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 1)

        self.layoutEngine.select([self.page1, self.page3], extendingSelection: false)

        XCTAssertEqual(self.layoutEngine.selectedPages, [self.page1, self.page3])
    }

    func test_selectPages_updatesEnabledPage() throws {
        self.layoutEngine.select([self.page2])
        XCTAssertEqual(self.layoutEngine.enabledPage, self.page2)

        self.layoutEngine.select([self.page3], extendingSelection: true)
        XCTAssertNil(self.layoutEngine.enabledPage)

        self.layoutEngine.select([self.page1], extendingSelection: false)
        XCTAssertEqual(self.layoutEngine.enabledPage, self.page1)
    }

    func test_selectPages_informsViewOfLayoutSelectionChange() throws {
        let testView = TestCanvasView()
        self.layoutEngine.view = testView
        self.layoutEngine.select([self.page2, self.page1])

        XCTAssertEqual(testView.context, CanvasLayoutEngine.LayoutContext(selectionChanged: true))
    }


    //MARK: - deselect(_:)
    func test_deselectPages_deselectsAllSuppliedPages() throws {
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.deselect([self.page1, self.page3])
        XCTAssertEqual(self.layoutEngine.selectedPages, [self.page2])
    }

    func test_deselectPages_updatesEnabledPage() throws {
        self.layoutEngine.select([self.page1, self.page2])
        XCTAssertNil(self.layoutEngine.enabledPage)
        self.layoutEngine.deselect([self.page2])
        XCTAssertEqual(self.layoutEngine.enabledPage, self.page1)
    }

    func test_deselectPages_informsViewOfLayoutSelectionChange() throws {
        let testView = TestCanvasView()
        self.layoutEngine.view = testView
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = true
        self.layoutEngine.deselect([self.page1, self.page3])

        XCTAssertEqual(testView.context, CanvasLayoutEngine.LayoutContext(selectionChanged: true))
    }


    //MARK: - groupSelectionChange(_:)
    func test_groupSelectionChange_doesntUpdateEnabledPageIfSelectingInsideBlock() throws {
        var enabledPage: LayoutEnginePage? = nil
        self.layoutEngine.groupSelectionChange {
            self.layoutEngine.select([self.page1])
            enabledPage = self.layoutEngine.enabledPage
        }
        XCTAssertNil(enabledPage)
    }

    func test_groupSelectionChange_doesntUpdateEnabledPageIfDeselectingInsideBlock() throws {
        self.layoutEngine.select([self.page3])
        var enabledPage: LayoutEnginePage? = self.layoutEngine.enabledPage
        self.layoutEngine.groupSelectionChange {
            self.layoutEngine.deselect([self.page3])
            enabledPage = self.layoutEngine.enabledPage
        }
        XCTAssertEqual(enabledPage, self.page3)
    }

    func test_groupSelectionChange_doesntInformViewOfLayoutChangeIfSelectingInsideBlock() throws {
        let testView = TestCanvasView()
        self.layoutEngine.view = testView
        var context: CanvasLayoutEngine.LayoutContext?
        self.layoutEngine.groupSelectionChange {
            self.layoutEngine.select([self.page1])
            context = testView.context
        }

        XCTAssertNil(context)
    }

    func test_groupSelectionChange_doesntInformViewOfLayoutChangeIfDeselectingInsideBlock() throws {
        let testView = TestCanvasView()
        self.layoutEngine.view = testView

        self.page2.selected = true

        var context: CanvasLayoutEngine.LayoutContext?
        self.layoutEngine.groupSelectionChange {
            self.layoutEngine.deselect([self.page2])
            context = testView.context
        }

        XCTAssertNil(context)
    }

    func test_groupSelectionChange_updatesEnabledPageAfterBlockInvoked() throws {
        self.layoutEngine.groupSelectionChange {
            self.layoutEngine.select([self.page1])
            self.layoutEngine.select([self.page3])
        }
        XCTAssertEqual(self.layoutEngine.enabledPage, self.page3)
    }

    func test_groupSelectionChange_informsViewOfLayoutSelectionChangeAfterBlockInvoked() throws {
        self.page2.selected = true
        let testView = TestCanvasView()
        self.layoutEngine.view = testView

        self.layoutEngine.groupSelectionChange {
            self.layoutEngine.deselect([self.page2])
        }

        XCTAssertEqual(testView.context, CanvasLayoutEngine.LayoutContext(selectionChanged: true))
    }


    //MARK: - Mouse Events
    func test_downEvent_createsMouseEventFromContextEventFactoryWithLocation() throws {
        self.layoutEngine.downEvent(at: CGPoint(x: 123, y: 456))
        XCTAssertTrue(self.mockContextFactory.createMouseEventContextMock.wasCalled)
        let (location, engine) = try XCTUnwrap(self.mockContextFactory.createMouseEventContextMock.arguments.first)
        XCTAssertEqual(location, CGPoint(x: 123, y: 456))
        XCTAssertTrue(engine === self.layoutEngine)
    }

    func test_downEvent_callsDownEventOnContextReturnedFromEventContextFactory() throws {
        let eventContext = MockCanvasMouseEventContext()
        self.mockContextFactory.createMouseEventContextMock.returnValue = eventContext
        self.layoutEngine.downEvent(at: CGPoint(x: 123, y: 456), modifiers: [.shift, .option], eventCount: 3)
        XCTAssertTrue(eventContext.downEventMock.wasCalled)
        let (location, modifiers, eventCount, engine) = try XCTUnwrap(eventContext.downEventMock.arguments.first)
        XCTAssertEqual(location, CGPoint(x: 123, y: 456))
        XCTAssertEqual(modifiers, [.shift, .option])
        XCTAssertEqual(eventCount, 3)
        XCTAssertTrue(engine === self.layoutEngine)
    }

    func test_downEvent_informsViewOfLayoutChange() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view
        self.mockContextFactory.createMouseEventContextMock.returnValue = MockCanvasMouseEventContext()
        self.layoutEngine.downEvent(at: CGPoint(x: 123, y: 456))
        XCTAssertEqual(view.context, CanvasLayoutEngine.LayoutContext())
    }

    func test_draggedEvent_callsDraggedEventOnContextReturnedFromEventContextFactory() throws {
        let eventContext = MockCanvasMouseEventContext()
        self.mockContextFactory.createMouseEventContextMock.returnValue = eventContext
        self.layoutEngine.downEvent(at: CGPoint(x: 123, y: 456), modifiers: [.shift, .option], eventCount: 3)
        self.layoutEngine.draggedEvent(at: CGPoint(x: 123, y: 456), modifiers: [.shift, .option], eventCount: 3)
        XCTAssertTrue(eventContext.draggedEventMock.wasCalled)
        let (location, modifiers, eventCount, engine) = try XCTUnwrap(eventContext.draggedEventMock.arguments.first)
        XCTAssertEqual(location, CGPoint(x: 123, y: 456))
        XCTAssertEqual(modifiers, [.shift, .option])
        XCTAssertEqual(eventCount, 3)
        XCTAssertTrue(engine === self.layoutEngine)
    }

    func test_draggedEvent_informsViewOfLayoutChange() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view
        self.mockContextFactory.createMouseEventContextMock.returnValue = MockCanvasMouseEventContext()
        self.layoutEngine.draggedEvent(at: CGPoint(x: 123, y: 456))
        XCTAssertEqual(view.context, CanvasLayoutEngine.LayoutContext())
    }

    func test_upEvent_callsUpEventOnContextReturnedFromEventContextFactory() throws {
        let eventContext = MockCanvasMouseEventContext()
        self.mockContextFactory.createMouseEventContextMock.returnValue = eventContext
        self.layoutEngine.downEvent(at: CGPoint(x: 123, y: 456), modifiers: [.shift, .option], eventCount: 3)
        self.layoutEngine.draggedEvent(at: CGPoint(x: 123, y: 456), modifiers: [.shift, .option], eventCount: 3)
        self.layoutEngine.upEvent(at: CGPoint(x: 123, y: 456), modifiers: [.shift, .option], eventCount: 3)
        XCTAssertTrue(eventContext.upEventMock.wasCalled)
        let (location, modifiers, eventCount, engine) = try XCTUnwrap(eventContext.upEventMock.arguments.first)
        XCTAssertEqual(location, CGPoint(x: 123, y: 456))
        XCTAssertEqual(modifiers, [.shift, .option])
        XCTAssertEqual(eventCount, 3)
        XCTAssertTrue(engine === self.layoutEngine)
    }

    func test_upEvent_informsViewOfLayoutChange() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view
        self.mockContextFactory.createMouseEventContextMock.returnValue = MockCanvasMouseEventContext()
        self.layoutEngine.downEvent(at: CGPoint(x: 123, y: 456))
        self.layoutEngine.draggedEvent(at: CGPoint(x: 123, y: 456))
        self.layoutEngine.upEvent(at: CGPoint(x: 123, y: 456))
        XCTAssertEqual(view.context, CanvasLayoutEngine.LayoutContext(pageOffsetChange: .zero))
    }

    func test_upEvent_informsViewThatSelectionAndBackgroundVisibilityChangedIfSelectionChangedDuringEvent() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view
        self.mockContextFactory.createMouseEventContextMock.returnValue = MockCanvasMouseEventContext()
        self.layoutEngine.downEvent(at: CGPoint(x: 123, y: 456))
        self.layoutEngine.draggedEvent(at: CGPoint(x: 123, y: 456))
        self.page3.selected = true
        self.layoutEngine.upEvent(at: CGPoint(x: 123, y: 456))
        XCTAssertEqual(view.context, CanvasLayoutEngine.LayoutContext(pageOffsetChange: .zero, selectionChanged: true, backgroundVisibilityChanged: true))
    }

    func test_upEvent_informsViewThatSelectionAndBackgroundVisibilityDidNOTChangeIfSelectionDidntChangeDuringEvent() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view
        self.mockContextFactory.createMouseEventContextMock.returnValue = MockCanvasMouseEventContext()
        self.layoutEngine.downEvent(at: CGPoint(x: 123, y: 456))
        self.layoutEngine.draggedEvent(at: CGPoint(x: 123, y: 456))
        self.layoutEngine.upEvent(at: CGPoint(x: 123, y: 456))
        XCTAssertEqual(view.context, CanvasLayoutEngine.LayoutContext(pageOffsetChange: .zero, selectionChanged: false, backgroundVisibilityChanged: false))
    }


    //MARK: - Keyboard Events
    func test_keyDownEvent_createsKeyEventFromContextEventFactoryWithKeyCode() throws {
        self.layoutEngine.keyDownEvent(keyCode: 31)
        XCTAssertTrue(self.mockContextFactory.createKeyEventContextMock.wasCalled)
        let (keyCode, engine) = try XCTUnwrap(self.mockContextFactory.createKeyEventContextMock.arguments.first)
        XCTAssertEqual(keyCode, 31)
        XCTAssertTrue(engine === self.layoutEngine)
    }

    func test_keyDownEvent_doesntCreateKeyEventFromContextEventFactoryIfKeyDownCalledAgainBeforeKeyUp() throws {
        self.mockContextFactory.createKeyEventContextMock.returnValue = MockCanvasKeyEventContext()
        self.layoutEngine.keyDownEvent(keyCode: 31)
        self.layoutEngine.keyDownEvent(keyCode: 31, isARepeat: true)
        XCTAssertEqual(self.mockContextFactory.createKeyEventContextMock.arguments.count, 1)
    }

    func test_keyDownEvent_callsKeyDownOnContextReturnedFromEventContextFactory() throws {
        let eventContext = MockCanvasKeyEventContext()
        self.mockContextFactory.createKeyEventContextMock.returnValue = eventContext
        self.layoutEngine.keyDownEvent(keyCode: 42, modifiers: [.shift, .command], isARepeat: true)
        XCTAssertTrue(eventContext.keyDownMock.wasCalled)
        let (keyCode, modifiers, isARepeat, engine) = try XCTUnwrap(eventContext.keyDownMock.arguments.first)
        XCTAssertEqual(keyCode, 42)
        XCTAssertEqual(modifiers, [.shift, .command])
        XCTAssertTrue(isARepeat)
        XCTAssertTrue(engine === self.layoutEngine)
    }

    func test_keyDownEvent_informsViewofLayoutChange() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view
        self.mockContextFactory.createKeyEventContextMock.returnValue = MockCanvasKeyEventContext()
        self.layoutEngine.keyDownEvent(keyCode: 42)
        XCTAssertEqual(view.context, CanvasLayoutEngine.LayoutContext())
    }

    func test_keyUpEvent_callsKeyUpOnContextReturnedFromEventContextFactory() throws {
        let eventContext = MockCanvasKeyEventContext()
        self.mockContextFactory.createKeyEventContextMock.returnValue = eventContext
        self.layoutEngine.keyDownEvent(keyCode: 42, modifiers: [.shift, .command], isARepeat: true)
        self.layoutEngine.keyUpEvent(keyCode: 42, modifiers: [.shift, .command])
        XCTAssertTrue(eventContext.keyUpMock.wasCalled)
        let (keyCode, modifiers, engine) = try XCTUnwrap(eventContext.keyUpMock.arguments.first)
        XCTAssertEqual(keyCode, 42)
        XCTAssertEqual(modifiers, [.shift, .command])
        XCTAssertTrue(engine === self.layoutEngine)
    }

    func test_keyUpEvent_informsViewOfLayoutChange() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view
        self.mockContextFactory.createKeyEventContextMock.returnValue = MockCanvasKeyEventContext()
        self.layoutEngine.keyDownEvent(keyCode: 42, modifiers: [.shift, .command], isARepeat: true)
        view.context = nil
        self.layoutEngine.keyDownEvent(keyCode: 42)
        XCTAssertEqual(view.context, CanvasLayoutEngine.LayoutContext())
    }

    func test_keyUpEvent_doesntInformViewOfLayoutChangeIfKeyUpCalledWithoutKeyDown() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view
        self.mockContextFactory.createKeyEventContextMock.returnValue = MockCanvasKeyEventContext()
        self.layoutEngine.keyUpEvent(keyCode: 42)
        XCTAssertNil(view.context)
    }


    //MARK: - Accessibility Resize
    func test_accessibilityResize_topLeft_regularUnboundedResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -5, y: 0), on: .resizeTopLeft, expectingFrameChange: (-5, 0, 5, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -5, y: 0))
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 5, y: 0), on: .resizeTopLeft, expectingFrameChange: (5, 0, -5, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 5, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -5), on: .resizeTopLeft, expectingFrameChange: (0, -5, 0, 5))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -5))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 5), on: .resizeTopLeft, expectingFrameChange: (0, 5, 0, -5))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 5))
    }

    func test_accessibilityResize_topLeft_regularMinResize() throws {
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 20, y: 0), on: .resizeTopLeft, expectingFrameChange: (10, 0, -10, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 10, y: 0))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 40), on: .resizeTopLeft, expectingFrameChange: (0, 30, 0, -30))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 30))
    }

    func test_accessibilityResize_topRight_regularUnboundedResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -5, y: 0), on: .resizeTopRight, expectingFrameChange: (0, 0, -5, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -5, y: 0))
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 5, y: 0), on: .resizeTopRight, expectingFrameChange: (0, 0, 5, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 5, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -5), on: .resizeTopRight, expectingFrameChange: (0, -5, 0, 5))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -5))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 5), on: .resizeTopRight, expectingFrameChange: (0, 5, 0, -5))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 5))
    }

    func test_accessibilityResize_topRight_regularMinResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -20, y: 0), on: .resizeTopRight, expectingFrameChange: (0, 0, -10, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -10, y: 0))

        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 40), on: .resizeTopRight, expectingFrameChange: (0, 30, 0, -30))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 30))
    }

    func test_accessibilityResize_bottomRight_regularUnboundedResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -5, y: 0), on: .resizeBottomRight, expectingFrameChange: (0, 0, -5, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -5, y: 0))
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 5, y: 0), on: .resizeBottomRight, expectingFrameChange: (0, 0, 5, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 5, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -5), on: .resizeBottomRight, expectingFrameChange: (0, 0, 0, -5))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -5))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 5), on: .resizeBottomRight, expectingFrameChange: (0, 0, 0, 5))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 5))
    }

    func test_accessibilityResize_bottomRight_regularMinResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -20, y: 0), on: .resizeBottomRight, expectingFrameChange: (0, 0, -10, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -10, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -40), on: .resizeBottomRight, expectingFrameChange: (0, 0, 0, -30))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -30))
    }

    func test_accessibilityResize_bottomLeft_regularUnboundedResize() throws {
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -5, y: 0), on: .resizeBottomLeft, expectingFrameChange: (-5, 0, 5, 0))
        XCTAssertEqual(minusXPoint, CGPoint(x: -5, y: 0))
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 5, y: 0), on: .resizeBottomLeft, expectingFrameChange: (5, 0, -5, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 5, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -5), on: .resizeBottomLeft, expectingFrameChange: (0, 0, 0, -5))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -5))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 5), on: .resizeBottomLeft, expectingFrameChange: (0, 0, 0, 5))
        XCTAssertEqual(plusYPoint, CGPoint(x: 0, y: 5))
    }

    func test_accessibilityResize_bottomLeft_regularMinResize() throws {
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 20, y: 0), on: .resizeBottomLeft, expectingFrameChange: (10, 0, -10, 0))
        XCTAssertEqual(plusXPoint, CGPoint(x: 10, y: 0))
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -40), on: .resizeBottomLeft, expectingFrameChange: (0, 0, 0, -30))
        XCTAssertEqual(minusYPoint, CGPoint(x: 0, y: -30))
    }

    func test_accessibilityResize_topLeft_aspectUnboundedResize() throws {
        //Aspect doesn't resize horizontally
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -4, y: 0), on: .resizeTopLeft, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(minusXPoint, .zero)
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 4, y: 0), on: .resizeTopLeft, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(plusXPoint, .zero)
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -4), on: .resizeTopLeft, maintainAspectRatio: true, expectingFrameChange: (-2, -4, 2, 4))
        XCTAssertEqual(minusYPoint, CGPoint(x: -2, y: -4))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 4), on: .resizeTopLeft, maintainAspectRatio: true, expectingFrameChange: (2, 4, -2, -4))
        XCTAssertEqual(plusYPoint, CGPoint(x: 2, y: 4))
    }

    func test_accessibilityResize_topLeft_aspectMinResize() throws {
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 40), on: .resizeTopLeft, maintainAspectRatio: true, expectingFrameChange: (10, 20, -10, -20))
        XCTAssertEqual(plusYPoint, CGPoint(x: 10, y: 20))
    }

    func test_accessibilityResize_topRight_aspectUnboundedResize() throws {
        //Aspect doesn't resize horizontally
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -4, y: 0), on: .resizeTopRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(minusXPoint, .zero)
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 4, y: 0), on: .resizeTopRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(plusXPoint, .zero)
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -4), on: .resizeTopRight, maintainAspectRatio: true, expectingFrameChange: (0, -4, 2, 4))
        XCTAssertEqual(minusYPoint, CGPoint(x: 2, y: -4))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 4), on: .resizeTopRight, maintainAspectRatio: true, expectingFrameChange: (0, 4, -2, -4))
        XCTAssertEqual(plusYPoint, CGPoint(x: -2, y: 4))
    }

    func test_accessibilityResize_topRight_aspectMinResize() throws {
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 40), on: .resizeTopRight, maintainAspectRatio: true, expectingFrameChange: (0, 20, -10, -20))
        XCTAssertEqual(plusYPoint, CGPoint(x: -10, y: 20))
    }

    func test_accessibilityResize_bottomRight_aspectUnboundedResize() throws {
        //Aspect doesn't resize horizontally
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -4, y: 0), on: .resizeBottomRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(minusXPoint, .zero)
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 4, y: 0), on: .resizeBottomRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(plusXPoint, .zero)
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -4), on: .resizeBottomRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, -2, -4))
        XCTAssertEqual(minusYPoint, CGPoint(x: -2, y: -4))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 4), on: .resizeBottomRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, 2, 4))
        XCTAssertEqual(plusYPoint, CGPoint(x: 2, y: 4))
    }

    func test_accessibilityResize_bottomRight_aspectMinResize() throws {
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -40), on: .resizeBottomRight, maintainAspectRatio: true, expectingFrameChange: (0, 0, -10, -20))
        XCTAssertEqual(minusYPoint, CGPoint(x: -10, y: -20))
    }

    func test_accessibilityResize_bottomLeft_aspectUnboundedResize() throws {
        //Aspect doesn't resize horizontally
        let minusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: -4, y: 0), on: .resizeBottomLeft, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(minusXPoint, .zero)
        let plusXPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 4, y: 0), on: .resizeBottomLeft, maintainAspectRatio: true, expectingFrameChange: (0, 0, 0, 0))
        XCTAssertEqual(plusXPoint, .zero)
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -4), on: .resizeBottomLeft, maintainAspectRatio: true, expectingFrameChange: (2, 0, -2, -4))
        XCTAssertEqual(minusYPoint, CGPoint(x: 2, y: -4))
        let plusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: 4), on: .resizeBottomLeft, maintainAspectRatio: true, expectingFrameChange: (-2, 0, 2, 4))
        XCTAssertEqual(plusYPoint, CGPoint(x: -2, y: 4))
    }

    func test_accessibilityResize_bottomLeft_aspectMinResize() throws {
        let minusYPoint = self.performAccessibilityResize(withDelta: CGPoint(x: 0, y: -40), on: .resizeBottomLeft, maintainAspectRatio: true, expectingFrameChange: (10, 0, -10, -20))
        XCTAssertEqual(minusYPoint, CGPoint(x: 10, y: -20))
    }


    private func performAccessibilityResize(withDelta delta: CGPoint, on component: LayoutEnginePageComponent, maintainAspectRatio: Bool = false, expectingFrameChange change: (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)) -> CGPoint? {
        let page = LayoutEnginePage(id: UUID(),
                                    contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40),
                                    maintainAspectRatio: maintainAspectRatio,
                                    minimumContentSize: CGSize(width: 10, height: 10))
        self.layoutEngine.add([page])

        var expectedFrame = page.layoutFrame
        expectedFrame.size = expectedFrame.size.plus(width: change.width, height: change.height)
        expectedFrame.origin = expectedFrame.origin.plus(x: change.x, y: change.y)

        let returnedDelta = self.layoutEngine.accessibilityResize(component, of: page, by: delta)

        guard page.layoutFrame == expectedFrame else {
            XCTFail("\(page.layoutFrame) not equal to \(expectedFrame)")
            return nil
        }

        return returnedDelta
    }



    //MARK: - Background
    func test_pageBackground_noPageShowsBackgroundIfMouseMovedOverCanvasAndNothingSelected() throws {
        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)

        self.layoutEngine.moveEvent(at: CGPoint(x: 40, y: 100))

        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)
    }

    func test_pageBackground_pageShowsBackgroundIfMouseMovesOverPage() throws {
        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: 3, y: 3)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertTrue(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)
    }

    func test_pageBackground_pageStillShowsBackgroundIfMouseMovesFurtherOverPage() throws {
        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: 3, y: 3)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertTrue(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: 5, y: 4)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertTrue(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)
    }

    func test_pageBackground_pageDoesntShowBackgroundIfMouseMovesOffPage() throws {
        XCTAssertEqual(self.layoutEngine.pages.filter(\.showBackground).count, 0)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: 3, y: 3)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertTrue(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: -2, y: -2)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)
    }

    func test_pageBackground_pagesShowBackgroundIfSelected() throws {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        self.layoutEngine.select([self.page1, self.page3])

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)

        XCTAssertTrue(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertTrue(self.page3.showBackground)
    }

    func test_pageBackground_pageStillShowsBackgroundIfSelectedAndMouseMovesOver() throws {
        let clickPoint1 = self.page1.layoutFrame.midPoint
        self.layoutEngine.downEvent(at: clickPoint1)

        self.layoutEngine.moveEvent(at: clickPoint1.plus(CGPoint(x: 2, y: 3)))

        XCTAssertTrue(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertFalse(self.page3.showBackground)
    }

    func test_pageBackground_pageStillShowsBackgroundIfSelectedAndMouseMovesOff() throws {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        self.layoutEngine.select([self.page3])

        self.layoutEngine.moveEvent(at: self.page3.layoutFrame.origin.minus(CGPoint(x: 10, y: 10)))

        XCTAssertFalse(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertTrue(self.page3.showBackground)
    }

    func test_pageBackground_allSelectedPagesAndTheHoveredPageShowBackground() throws {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        self.layoutEngine.select([self.page1, self.page3])

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.midPoint)

        XCTAssertTrue(self.page1.showBackground)
        XCTAssertTrue(self.page2.showBackground)
        XCTAssertTrue(self.page3.showBackground)
    }

    func test_pageBackground_onlySelectedPagesShowBackgroundAfterMouseMovesOffHoveredPage() throws {
        XCTAssertEqual(self.layoutEngine.selectedPages.count, 0)

        self.layoutEngine.select([self.page1, self.page3])

        XCTAssertEqual(self.layoutEngine.selectedPages.count, 2)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.midPoint)
        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.minus(x: 10, y: 10))

        XCTAssertTrue(self.page1.showBackground)
        XCTAssertFalse(self.page2.showBackground)
        XCTAssertTrue(self.page3.showBackground)
    }

    func test_pageBackground_notifiesViewWhenPageHoveredOver() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(CGPoint(x: 3, y: 3)))

        XCTAssertTrue(try XCTUnwrap(view.context?.backgroundVisibilityChanged))
    }

    func test_pageBackground_notifiesViewWhenMovedAwayFromHoveredPage() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        view.context = nil

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.minus(x: 3, y: 3))

        XCTAssertTrue(try XCTUnwrap(view.context?.backgroundVisibilityChanged))
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOverHoveredPage() throws {
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        view.context = nil

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 4, y: 4))

        XCTAssertNil(view.context)
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOntoSelectedPage() throws {
        self.page2.selected = true
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        XCTAssertNil(view.context)
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOffSelectedPageToCanvas() throws {
        self.page2.selected = true
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        XCTAssertNil(view.context)

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.minus(x: 4, y: 4))
        XCTAssertNil(view.context)
    }

    func test_pageBackground_notifiesViewWhenMovingOffSelectedPageToOtherUnselectedPage() throws {
        self.page2.selected = true
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        XCTAssertNil(view.context)

        self.layoutEngine.moveEvent(at: self.page3.layoutFrame.midPoint)
        XCTAssertNil(view.context)
    }

    func test_pageBackground_doesntNotifyViewWhenMovingOffSelectedPageToOtherSelectedPage() throws {
        self.page2.selected = true
        self.page3.selected = true
        let view = TestCanvasView()
        self.layoutEngine.view = view

        self.layoutEngine.moveEvent(at: self.page2.layoutFrame.origin.plus(x: 3, y: 3))
        XCTAssertNil(view.context)

        self.layoutEngine.moveEvent(at: self.page3.layoutFrame.midPoint)
        XCTAssertNil(view.context)
    }



    //MARK: - Canvas Size and Offset
    func test_canvasSize_canvasSizeShouldEqualContentBoundsPlusCanvasBorderOnEachSize() throws {
        XCTAssertEqual(self.layoutEngine.canvasSize, self.contentFrame.insetBy(dx: -20, dy: -20).size)
    }

    func test_canvasSize_canvasSizeShouldBeBiggerThanContentBoundsPlusCanvasBorderIfViewPortFrameIsOutside() throws {
        let testCanvas = TestCanvasView()
        testCanvas.viewPortFrame = CGRect(x: 60, y: 60, width: 80, height: 80)
        self.layoutEngine.view = testCanvas

        let point = self.page1.layoutFrame.origin
        self.layoutEngine.downEvent(at: point)
        self.layoutEngine.draggedEvent(at: point)
        self.layoutEngine.upEvent(at: point)

        let borderedContentFrame = self.contentFrame.insetBy(dx: -20, dy: -20)
        let fullFrame = borderedContentFrame.union(testCanvas.viewPortFrame)
        XCTAssertEqual(self.layoutEngine.canvasSize, fullFrame.size)
    }

    func test_canvasSize_pageSpaceOffsetShouldChangeIfCanvasGrowsUpwards() throws {
        let initialOffset = self.layoutEngine.convertPointToPageSpace(.zero)

        var frame = self.page2.contentFrame
        frame.origin.y -= 20
        self.layoutEngine.updateContentFrame(frame, ofPageWithID: self.page2.id)

        let newOffset = self.layoutEngine.convertPointToPageSpace(.zero)

        XCTAssertEqual(initialOffset.minus(newOffset), CGPoint(x: 0, y: 10))
    }

    func test_canvasSize_pageSpaceOffsetShouldChangeIfCanvasGrowsToLeft() throws {
        let initialOffset = self.layoutEngine.convertPointToPageSpace(.zero)

        var frame = self.page2.contentFrame
        frame.origin.x -= 20
        self.layoutEngine.updateContentFrame(frame, ofPageWithID: self.page2.id)

        let newOffset = self.layoutEngine.convertPointToPageSpace(.zero)

        XCTAssertEqual(initialOffset.minus(newOffset), CGPoint(x: 20, y: 0))
    }

    func test_canvasSize_canvasSizeShouldUpdateWhenMouseEventEnds() throws {
        let initialSize = self.layoutEngine.canvasSize
        let pageOrigin = self.page2.layoutFrame
        let startPoint = CGPoint(x: pageOrigin.midX, y: pageOrigin.minY + 3)
        let endPoint = startPoint.plus(CGPoint(x: -20, y: 0))

        let page = self.page2!
        let mockMouseEvent = MockCanvasMouseEventContext()
        mockMouseEvent.upEventMock.method = { _ in
            var frame = page.contentFrame
            frame.origin.x -= 20
            page.contentFrame = frame
        }
        self.mockContextFactory.createMouseEventContextMock.returnValue = mockMouseEvent

        self.layoutEngine.downEvent(at: startPoint)
        XCTAssertEqual(self.layoutEngine.canvasSize, initialSize)
        self.layoutEngine.draggedEvent(at: endPoint)
        XCTAssertEqual(self.layoutEngine.canvasSize, initialSize)
        self.layoutEngine.upEvent(at: endPoint)
        XCTAssertNotEqual(self.layoutEngine.canvasSize, initialSize)
    }

    func test_canvasSize_updatesAllPagesCanvasFrameIfCanvasResizesUpAndToTheLeft() throws {
        let page1Origin = self.page1.layoutFrame.origin
        let page3Origin = self.page3.layoutFrame.origin

        var frame = self.page2.contentFrame
        frame.origin.x -= 10
        frame.origin.y -= 30
        self.layoutEngine.updateContentFrame(frame, ofPageWithID: self.page2.id)

        XCTAssertEqual(self.page1.layoutFrame.origin, page1Origin.plus(CGPoint(x: 10, y: 20)))
        XCTAssertEqual(self.page2.layoutFrame.origin, CGPoint(x: self.layoutEngine.configuration.contentBorder, y: self.layoutEngine.configuration.contentBorder))
        XCTAssertEqual(self.page3.layoutFrame.origin, page3Origin.plus(CGPoint(x: 10, y: 20)))
    }

    func test_canvasSize_doesNOTUpdatePagesCanvasFrameIfCanvasResizesDownToTheLeft() throws {
        let page1Origin = self.page1.layoutFrame.origin
        let page2Origin = self.page2.layoutFrame.origin
        let page3Origin = self.page3.layoutFrame.origin

        var frame = self.page1.contentFrame
        frame.origin.x += 10
        frame.origin.y += 20
        self.layoutEngine.updateContentFrame(frame, ofPageWithID: self.page1.id)

        XCTAssertEqual(self.page1.layoutFrame.origin, page1Origin.plus(CGPoint(x: 10, y: 20)))
        XCTAssertEqual(self.page2.layoutFrame.origin, page2Origin)
        XCTAssertEqual(self.page3.layoutFrame.origin, page3Origin)
    }


    //MARK: - pages(inCanvasRect:)
    func test_pagesInCanvasRect_returnsAllPagesIfRectCoversWholeCanvas() throws {
        let rect = CGRect(origin: .zero, size: self.layoutEngine.canvasSize)
        let pages = self.layoutEngine.pages(inCanvasRect: rect)

        XCTAssertEqual(pages, [self.page1, self.page2, self.page3])
    }

    func test_pagesInCanvasRect_returnsNoPagesIfRectCoversNoPages() throws {
        let rect = CGRect(origin: .zero, size: CGSize(width: 5, height: 5))
        let pages = self.layoutEngine.pages(inCanvasRect: rect)

        XCTAssertEqual(pages, [])
    }

    func test_pagesInCanvasRect_returnsOnlyPagesCoveredByRect() throws {
        let rect = try XCTUnwrap(CGRect(points: [self.page3.layoutFrame.midPoint, self.page2.layoutFrame.midPoint]))
        let pages = self.layoutEngine.pages(inCanvasRect: rect)

        XCTAssertEqual(pages, [self.page2, self.page3])
    }


    //MARK: - movePageToFront(_:)
    func test_movePageToFront_doesntChangeIndexesIfPageDoesntExistInCanvas() throws {
        let expectedPageOrder = self.layoutEngine.pages

        let page = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 20, y: 20, width: 30, height: 30))
        self.layoutEngine.movePageToFront(page)

        XCTAssertEqual(self.layoutEngine.pages, expectedPageOrder)
    }

    func test_movePageToFront_movesPageToEndOfPageArray() throws {
        self.layoutEngine.movePageToFront(self.page2)

        XCTAssertEqual(self.layoutEngine.pages, [self.page1, self.page3, self.page2])
    }

    func test_movePageToFront_updatesZIndexOfAllPages() throws {
        self.layoutEngine.movePageToFront(self.page2)
        self.page1.zIndex = 0
        self.page2.zIndex = 2
        self.page3.zIndex = 1
    }
}


private class TestCanvasView: CanvasLayoutView {
    var context: CanvasLayoutEngine.LayoutContext?
    func layoutChanged(with context: CanvasLayoutEngine.LayoutContext) {
        self.context = context
    }
    var viewPortFrame: CGRect = .zero
}
