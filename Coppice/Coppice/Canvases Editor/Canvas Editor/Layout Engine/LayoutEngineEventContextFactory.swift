//
//  CanvasEventContextFactory.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import CoppiceCore

protocol LayoutEngineEventContextFactory {
    func createMouseEventContext(for location: CGPoint, in layoutEngine: LayoutEngine) -> CanvasMouseEventContext?
    func createKeyEventContext(for keyCode: UInt16, in layoutEngine: LayoutEngine) -> CanvasKeyEventContext?
}


class CanvasLayoutEngineEventContextFactory: LayoutEngineEventContextFactory {
    func createMouseEventContext(for location: CGPoint, in layoutEngine: LayoutEngine) -> CanvasMouseEventContext? {
        //Canvas click
        guard let page = layoutEngine.page(atCanvasPoint: location) else {
            return CanvasSelectionEventContext()
        }

        layoutEngine.movePageToFront(page)

        //Page content click
        guard let pageComponent = page.component(at: location.minus(page.layoutFrame.origin)) else {
            return nil
        }

        switch pageComponent {
        case .titleBar, .content:
            return SelectAndMoveEventContext(page: page)
        default:
            return ResizePageEventContext(page: page, component: pageComponent)
        }
    }

    func createKeyEventContext(for keyCode: UInt16, in layoutEngine: LayoutEngine) -> CanvasKeyEventContext? {
        let selectedPages = layoutEngine.selectedPages
        guard selectedPages.count > 0 else {
            return nil
        }

        if KeyboardMovePageEventContext.acceptedKeyCodes.contains(keyCode) {
            return KeyboardMovePageEventContext(pages: selectedPages)
        } else if RemovePageEventContext.acceptedKeyCodes.contains(keyCode) {
            return RemovePageEventContext(pages: selectedPages)
        }
        return nil
    }
}
