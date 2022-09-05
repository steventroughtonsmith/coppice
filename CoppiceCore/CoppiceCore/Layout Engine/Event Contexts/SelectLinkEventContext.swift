//
//  SelectLinkEventContext.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 04/09/2022.
//

import Foundation

class SelectLinkEventContext: CanvasMouseEventContext {
    private var didShiftSelect = false
    private var initialLocation: CGPoint?

    let link: LayoutEngineLink
    let editable: Bool
    init(link: LayoutEngineLink, editable: Bool) {
        self.link = link
        self.editable = editable
    }

    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        //Toggle selection if the user is shift clicking
        if (modifiers.contains(.shift)) {
            if self.link.selected {
                layout.deselect([self.link])
            } else {
                layout.select([self.link], extendingSelection: true)
            }
            self.didShiftSelect = true
        } else if (self.link.selected == false) {
            layout.select([self.link], extendingSelection: false)
        }
        self.initialLocation = location
    }

    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        if (layout.selectedItems.count > 1) && (self.initialLocation == location) && !self.didShiftSelect {
            layout.select([self.link], extendingSelection: false)
        }
    }

}
