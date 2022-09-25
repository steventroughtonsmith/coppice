//
//  CanvasEventContextFactory.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public protocol LayoutEngineEventContextFactory {
    func createMouseEventContext(for location: CGPoint, in layoutEngine: LayoutEngine) -> CanvasMouseEventContext?
    func createKeyEventContext(for keyCode: UInt16, in layoutEngine: LayoutEngine) -> CanvasKeyEventContext?
}


public class CanvasLayoutEngineEventContextFactory: LayoutEngineEventContextFactory {
    public init() {}

    public func createMouseEventContext(for location: CGPoint, in layoutEngine: LayoutEngine) -> CanvasMouseEventContext? {
        if layoutEngine.isLinking {
            return CreateLinkMouseEventContext(page: layoutEngine.item(atCanvasPoint: location) as? LayoutEnginePage)
        }

        //Canvas click
        guard let item = layoutEngine.item(atCanvasPoint: location) else {
            return CanvasSelectionEventContext()
        }

        if let page = item as? LayoutEnginePage {
            return self.createMouseEventContext(for: page, location: location, in: layoutEngine)
        } else if let link = item as? LayoutEngineLink {
            return self.createMouseEventContext(for: link, location: location, in: layoutEngine)
        }
        return nil
    }

    private func createMouseEventContext(for page: LayoutEnginePage, location: CGPoint, in layoutEngine: LayoutEngine) -> CanvasMouseEventContext? {
        if layoutEngine.editable {
            layoutEngine.movePageToFront(page)
        }

        //Page content click
        guard let pageComponent = page.component(at: location.minus(page.layoutFrame.origin)) else {
            return nil
        }

        switch pageComponent {
        case .titleBar, .content:
            return SelectAndMoveEventContext(page: page, editable: layoutEngine.editable, component: pageComponent)
        default:
            //Can only resize when editable
            return (layoutEngine.editable) ? ResizePageEventContext(page: page, component: pageComponent) : nil
        }
    }

    private func createMouseEventContext(for link: LayoutEngineLink, location: CGPoint, in layoutEngine: LayoutEngine) -> CanvasMouseEventContext? {
        return SelectLinkEventContext(link: link, editable: layoutEngine.editable)
    }

    public func createKeyEventContext(for keyCode: UInt16, in layoutEngine: LayoutEngine) -> CanvasKeyEventContext? {
        guard layoutEngine.editable else {
            return nil
        }
        let selectedItems = layoutEngine.selectedItems
        guard selectedItems.count > 0 else {
            return nil
        }

        if KeyboardMovePageEventContext.acceptedKeyCodes.contains(keyCode) {
            let pages = selectedItems.pages
            guard pages.count > 0 else {
                return nil
            }
            return KeyboardMovePageEventContext(pages: pages)
        } else if RemoveItemEventContext.acceptedKeyCodes.contains(keyCode) {
            return RemoveItemEventContext(items: selectedItems)
        }
        return nil
    }
}
