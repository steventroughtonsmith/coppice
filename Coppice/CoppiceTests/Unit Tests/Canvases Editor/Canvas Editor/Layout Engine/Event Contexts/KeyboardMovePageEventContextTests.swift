//
//  KeyboardMovePageEventContextTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 03/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice
@testable import CoppiceCore
import Carbon.HIToolbox

class KeyboardMovePageEventContextTests: EventContextTestBase {

    private func layoutFrames(shiftingSelected pages: [LayoutEnginePage], by delta: CGPoint = .zero) -> [CGRect] {
        var frames = [CGRect]()
        for page in pages {
            var frame = page.layoutFrame
            if (page.selected) {
                frame = frame.offsetBy(dx: delta.x, dy: delta.y)
            }
            frames.append(frame)
        }
        return frames
    }

    private func performKeyboardMoveTest(keyCode: Int, downEventCount: Int = 1, expectedShift: CGPoint = .zero, modifiers: (Int) -> LayoutEventModifiers = {_ in []}) -> (actual: [CGRect], expected: [CGRect]) {
        let pages = [self.page1, self.page2, self.page3] as [LayoutEnginePage]
        let expectedFrames = self.layoutFrames(shiftingSelected: pages, by: expectedShift)

        let eventContext = KeyboardMovePageEventContext(pages: pages.filter(\.selected))
        eventContext.keyDown(withCode: UInt16(keyCode), modifiers: modifiers(0), isARepeat: false, in: self.mockLayoutEngine)
        (1..<downEventCount).forEach {
            eventContext.keyDown(withCode: UInt16(keyCode), modifiers: modifiers($0), isARepeat: true, in: self.mockLayoutEngine)
        }
        eventContext.keyUp(withCode: UInt16(keyCode), modifiers: modifiers(downEventCount), in: self.mockLayoutEngine)

        return (pages.map(\.layoutFrame), expectedFrames)
    }


    //MARK: - No Selection
    func test_noSelection_upArrowWithDoesNothing() {
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow)
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_noSelection_downArrowWithDoesNothing() {
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow)
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_noSelection_leftArrowWithDoesNothing() {
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow)
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_noSelection_rightArrowWithDoesNothing() {
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow)
        XCTAssertEqual(frames.actual, frames.expected)
    }


    //MARK: - Press Once
    func test_pressOnce_upArrowMovesSelectionUp() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, expectedShift: CGPoint(x: 0, y: -1))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressOnce_downArrowMovesSelectionDown() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, expectedShift: CGPoint(x: 0, y: 1))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressOnce_leftArrowMovesSelectionToLeft() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, expectedShift: CGPoint(x: -1, y: 0))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressOnce_rightArrowMovesSelectionToRight() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, expectedShift: CGPoint(x: 1, y: 0))
        XCTAssertEqual(frames.actual, frames.expected)
    }


    //MARK: - Press And Hold
    func test_pressAndHoldFor10Events_upArrowMovesSelection10StepsUp() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: -10))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressAndHoldFor10Events_downArrowMovesSelection10StepsDown() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: 10))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressAndHoldFor10Events_leftArrowMovesSelection10StepsToLeft() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, downEventCount: 10, expectedShift: CGPoint(x: -10, y: 0))
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressAndHoldFor10Events_rightArrowMovesSelection10StepsToRight() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, downEventCount: 10, expectedShift: CGPoint(x: 10, y: 0))
        XCTAssertEqual(frames.actual, frames.expected)
    }


    //MARK: - Hold Shift
    func test_holdShift_upArrowMovesSelectionUp10Steps() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, expectedShift: CGPoint(x: 0, y: -10)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_holdShift_downArrowMovesSelectionDown10Steps() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, expectedShift: CGPoint(x: 0, y: 10)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_holdShift_leftArrowMovesSelectionLeft10Steps() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, expectedShift: CGPoint(x: -10, y: 0)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_holdShift_rightArrowSelectionRight10Steps() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, expectedShift: CGPoint(x: 10, y: 0)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }


    //MARK: - Press And Hold Holding Shift
    func test_pressAndHoldFor10EventsHoldingShift_upArrowMovesSelection100StepsUp() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: -100)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressAndHoldFor10EventsHoldingShift_downArrowMovesSelection100StepsDown() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: 100)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressAndHoldFor10EventsHoldingShift_leftArrowMovesSelection100StepsToLeft() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, downEventCount: 10, expectedShift: CGPoint(x: -100, y: 0)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressAndHoldFor10EventsHoldingShift_rightArrowMovesSelection100StepsToRight() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, downEventCount: 10, expectedShift: CGPoint(x: 100, y: 0)) { _ in .shift }
        XCTAssertEqual(frames.actual, frames.expected)
    }


    //MARK: - Alternate Shift
    func test_pressAndHoldFor10EventsAlernatingShiftOnAndOff_upArrowMovesSelection55StepsUp() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: -55)) { (($0 % 2) == 0) ? .shift : [] }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressAndHoldFor10EventsAlernatingShiftOnAndOff_downArrowMovesSelection55StepsDown() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = true
        let frames = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, downEventCount: 10, expectedShift: CGPoint(x: 0, y: 55)) { (($0 % 2) == 0) ? .shift : [] }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressAndHoldFor10EventsAlernatingShiftOnAndOff_leftArrowMovesSelection55StepsToLeft() {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, downEventCount: 10, expectedShift: CGPoint(x: -55, y: 0)) { (($0 % 2) == 0) ? .shift : [] }
        XCTAssertEqual(frames.actual, frames.expected)
    }

    func test_pressAndHoldFor10EventsAlernatingShiftOnAndOff_rightArrowMovesSelection55StepsToRight() {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        let frames = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, downEventCount: 10, expectedShift: CGPoint(x: 55, y: 0)) { (($0 % 2) == 0) ? .shift : [] }
        XCTAssertEqual(frames.actual, frames.expected)
    }


    //MARK: - Calls Modified
    func test_keyDownCallsModified_upArrow() throws {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        _ = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, downEventCount: 1)

        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.count, 1)
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.first, [self.page1])
    }

    func test_keyDownCallsModified_downArrow() throws {
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = false
        _ = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, downEventCount: 1)

        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.count, 1)
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.first, [self.page1, self.page2])
    }

    func test_keyDownCallsModified_leftArrow() throws {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        _ = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, downEventCount: 1)

        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.count, 1)
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.first, [self.page2])
    }

    func test_keyDownCallsModified_rightArrow() throws {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = true
        _ = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, downEventCount: 1)

        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.count, 1)
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.first, [self.page1, self.page3])
    }

    func test_keyDownCallsModified_doesntCallForOtherKey() throws {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        _ = self.performKeyboardMoveTest(keyCode: kVK_Space, downEventCount: 1)

        XCTAssertFalse(self.mockLayoutEngine.modifiedPagesMock.wasCalled)
    }


    //MARK: - Calls Modified For Hold
    func test_keyDownCallsModifiedMultipleTimes_holdingUpArrow() throws {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        _ = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, downEventCount: 5)

        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.count, 5)
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.first, [self.page1])
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.last, [self.page1])
    }

    func test_keyDownCallsModifiedMultipleTimes_holdingDownArrow() throws {
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = false
        _ = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, downEventCount: 4)

        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.count, 4)
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.first, [self.page1, self.page2])
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.last, [self.page1, self.page2])
    }

    func test_keyDownCallsModifiedMultipleTimes_holdingLeftArrow() throws {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = true
        _ = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, downEventCount: 8)

        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.count, 8)
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.first, [self.page2, self.page3])
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.last, [self.page2, self.page3])
    }

    func test_keyDownCallsModifiedMultipleTimes_holdingRightArrow() throws {
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = true
        _ = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, downEventCount: 12)

        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.count, 12)
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.first, [self.page1, self.page2, self.page3])
        XCTAssertEqual(self.mockLayoutEngine.modifiedPagesMock.arguments.last, [self.page1, self.page2, self.page3])
    }


    //MARK: - Calls FinishedModifying
    func test_keyUpCallsFinishedModified_upArrow() throws {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        _ = self.performKeyboardMoveTest(keyCode: kVK_UpArrow, downEventCount: 1)

        XCTAssertEqual(self.mockLayoutEngine.finishedModifyingMock.arguments.count, 1)
        XCTAssertEqual(self.mockLayoutEngine.finishedModifyingMock.arguments.first, [self.page1])
    }

    func test_keyUpCallsFinishedModified_downArrow() throws {
        self.page1.selected = true
        self.page2.selected = true
        self.page3.selected = false
        _ = self.performKeyboardMoveTest(keyCode: kVK_DownArrow, downEventCount: 1)

        XCTAssertEqual(self.mockLayoutEngine.finishedModifyingMock.arguments.count, 1)
        XCTAssertEqual(self.mockLayoutEngine.finishedModifyingMock.arguments.first, [self.page1, self.page2])
    }

    func test_keyUpCallsFinishedModified_leftArrow() throws {
        self.page1.selected = false
        self.page2.selected = true
        self.page3.selected = false
        _ = self.performKeyboardMoveTest(keyCode: kVK_LeftArrow, downEventCount: 1)

        XCTAssertEqual(self.mockLayoutEngine.finishedModifyingMock.arguments.count, 1)
        XCTAssertEqual(self.mockLayoutEngine.finishedModifyingMock.arguments.first, [self.page2])
    }

    func test_keyUpCallsFinishedModified_rightArrow() throws {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = true
        _ = self.performKeyboardMoveTest(keyCode: kVK_RightArrow, downEventCount: 1)

        XCTAssertEqual(self.mockLayoutEngine.finishedModifyingMock.arguments.count, 1)
        XCTAssertEqual(self.mockLayoutEngine.finishedModifyingMock.arguments.first, [self.page1, self.page3])
    }

    func test_kkeyUpCallsFinishedModified_doesntCallForOtherKey() throws {
        self.page1.selected = true
        self.page2.selected = false
        self.page3.selected = false
        _ = self.performKeyboardMoveTest(keyCode: kVK_Tab, downEventCount: 1)

        XCTAssertFalse(self.mockLayoutEngine.finishedModifyingMock.wasCalled)
    }

}
