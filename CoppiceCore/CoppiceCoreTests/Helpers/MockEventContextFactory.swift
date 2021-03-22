//
//  MockEventContextFactory.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 05/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import Foundation

class MockEventContextFactory: LayoutEngineEventContextFactory {
    let createMouseEventContextMock = MockDetails<(CGPoint, LayoutEngine), CanvasMouseEventContext?>()
    func createMouseEventContext(for location: CGPoint, in layoutEngine: LayoutEngine) -> CanvasMouseEventContext? {
        return self.createMouseEventContextMock.called(withArguments: (location, layoutEngine)) ?? nil
    }

    let createKeyEventContextMock = MockDetails<(UInt16, LayoutEngine), CanvasKeyEventContext?>()
    func createKeyEventContext(for keyCode: UInt16, in layoutEngine: LayoutEngine) -> CanvasKeyEventContext? {
        return self.createKeyEventContextMock.called(withArguments: (keyCode, layoutEngine)) ?? nil
    }
}


class MockCanvasMouseEventContext: CanvasMouseEventContext {
    let downEventMock = MockDetails<(CGPoint, LayoutEventModifiers, Int, LayoutEngine), Void>()
    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        self.downEventMock.called(withArguments: (location, modifiers, eventCount, layout))
    }

    let draggedEventMock = MockDetails<(CGPoint, LayoutEventModifiers, Int, LayoutEngine), Void>()
    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        self.draggedEventMock.called(withArguments: (location, modifiers, eventCount, layout))
    }

    let upEventMock = MockDetails<(CGPoint, LayoutEventModifiers, Int, LayoutEngine), Void>()
    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        self.upEventMock.called(withArguments: (location, modifiers, eventCount, layout))
    }
}


class MockCanvasKeyEventContext: CanvasKeyEventContext {
    let keyDownMock = MockDetails<(UInt16, LayoutEventModifiers, Bool, LayoutEngine), Void>()
    func keyDown(withCode code: UInt16, modifiers: LayoutEventModifiers, isARepeat: Bool, in layout: LayoutEngine) {
        self.keyDownMock.called(withArguments: (code, modifiers, isARepeat, layout))
    }

    let keyUpMock = MockDetails<(UInt16, LayoutEventModifiers, LayoutEngine), Void>()
    func keyUp(withCode code: UInt16, modifiers: LayoutEventModifiers, in layout: LayoutEngine) {
        self.keyUpMock.called(withArguments: (code, modifiers, layout))
    }
}
