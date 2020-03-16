//
//  CanvasEventContext.swift
//  Bubbles
//
//  Created by Martin Pilkington on 18/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol CanvasEventContext {
    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine)
    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine)
    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine)

    func keyDown(withCode: UInt16, modifiers: LayoutEventModifiers, isARepeat: Bool, in layout: CanvasLayoutEngine)
    func keyUp(withCode: UInt16, modifiers: LayoutEventModifiers, in layout: CanvasLayoutEngine)
}

extension CanvasEventContext {
    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {}
    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {}
    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {}

    func keyDown(withCode: UInt16, modifiers: LayoutEventModifiers, isARepeat: Bool, in layout: CanvasLayoutEngine) {}
    func keyUp(withCode: UInt16, modifiers: LayoutEventModifiers, in layout: CanvasLayoutEngine) {}
}
