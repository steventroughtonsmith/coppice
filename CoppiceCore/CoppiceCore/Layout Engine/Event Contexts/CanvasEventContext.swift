//
//  CanvasEventContext.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

public protocol CanvasMouseEventContext {
    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine)
    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine)
    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine)
}

extension CanvasMouseEventContext {
    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {}
    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {}
    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {}
}


public protocol CanvasKeyEventContext {
    func keyDown(withCode: UInt16, modifiers: LayoutEventModifiers, isARepeat: Bool, in layout: LayoutEngine)
    func keyUp(withCode: UInt16, modifiers: LayoutEventModifiers, in layout: LayoutEngine)
}

extension CanvasKeyEventContext {
    func keyDown(withCode: UInt16, modifiers: LayoutEventModifiers, isARepeat: Bool, in layout: LayoutEngine) {}
    func keyUp(withCode: UInt16, modifiers: LayoutEventModifiers, in layout: LayoutEngine) {}
}


public protocol LayoutEngine: class {
    var editable: Bool { get }
    var selectedPages: [LayoutEnginePage] { get }
    var canvasSize: CGSize { get }
    var selectionRect: CGRect? { get set }

    func select(_ pages: [LayoutEnginePage], extendingSelection: Bool)
    func deselect(_ pages: [LayoutEnginePage])
    func deselectAll()

    func pages(inCanvasRect rect: CGRect) -> [LayoutEnginePage]
    func page(atCanvasPoint point: CGPoint) -> LayoutEnginePage?
    func movePageToFront(_ page: LayoutEnginePage)

    func modified(_ pages: [LayoutEnginePage])
    func finishedModifying(_ pages: [LayoutEnginePage])
    func tellDelegateToRemove(_ pages: [LayoutEnginePage])

    func startEditing(_ page: LayoutEnginePage, at point: CGPoint)
    func stopEditingPages()
}
