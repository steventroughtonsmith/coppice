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


public class LayoutEngineItem: Equatable {
    public let id: UUID
    public init(id: UUID) {
        self.id = id
    }

    public var selected: Bool = false
    public weak var canvasLayoutEngine: CanvasLayoutEngine?

    public var layoutFrame: CGRect = .zero

    public static func == (lhs: LayoutEngineItem, rhs: LayoutEngineItem) -> Bool {
        return lhs.id == rhs.id
    }
}


public protocol LayoutEngine: AnyObject {
    var editable: Bool { get }
    var selectedItems: [LayoutEngineItem] { get }
    var canvasSize: CGSize { get }
    var selectionRect: CGRect? { get set }

    func select(_ item: [LayoutEngineItem], extendingSelection: Bool)
    func deselect(_ items: [LayoutEngineItem])
    func deselectAll()

    func items(inCanvasRect rect: CGRect) -> [LayoutEngineItem]
    func item(atCanvasPoint point: CGPoint) -> LayoutEngineItem?

    func modified(_ items: [LayoutEngineItem])
    func finishedModifying(_ items: [LayoutEngineItem])
    func tellDelegateToRemove(_ items: [LayoutEngineItem])

    func startEditing(_ page: LayoutEnginePage, atContentPoint point: CGPoint)
    func stopEditingPages()
    func movePageToFront(_ page: LayoutEnginePage)
}


extension Array where Element == LayoutEngineItem {
    public var pages: [LayoutEnginePage] {
        return self.compactMap { $0 as? LayoutEnginePage }
    }

    public var links: [LayoutEngineLink] {
        return self.compactMap { $0 as? LayoutEngineLink }
    }

    var firstPage: LayoutEnginePage? {
        for item in self {
            if let page = item as? LayoutEnginePage {
                return page
            }
        }
        return nil
    }

    var firstLink: LayoutEngineLink? {
        for item in self {
            if let link = item as? LayoutEngineLink {
                return link
            }
        }
        return nil
    }
}
