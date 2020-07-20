//
//  PageTitleBarEventContext.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 11/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class SelectAndMoveEventContext: CanvasMouseEventContext {
    private var lastLocation: CGPoint?
    private var initialLocation: CGPoint?
    private var didShiftSelect = false
    private var didDoubleClick = false

    let page: LayoutEnginePage
    init(page: LayoutEnginePage) {
        self.page = page
    }

    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        //Toggle selection if the user is shift clicking
        if (modifiers.contains(.shift)) {
            if self.page.selected {
                layout.deselect([self.page])
            } else {
                layout.select([self.page], extendingSelection: true)
            }
            self.didShiftSelect = true
        }
        //If we double click we want to select all descendents
        else if (eventCount == 2) {
            let pages = [self.page] + self.page.allDescendants
            layout.select(pages, extendingSelection: false)
            self.didDoubleClick = true
        }
        //Otherwise we want to select just the clicked page if it isn't already selected (if it is then we assume the user is about the drag the selection
        else if (self.page.selected == false) {
            layout.select([self.page], extendingSelection: false)
        }


        self.initialLocation = location
        self.lastLocation = location
    }

    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        guard let lastLocation = self.lastLocation else {
            return
        }
        let delta = location.minus(lastLocation)
        for page in layout.selectedPages {
            page.layoutFrame.origin = page.layoutFrame.origin.plus(delta)
        }
        self.lastLocation = location
        layout.modified(layout.selectedPages)
    }

    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        let movedPages = layout.selectedPages
        //If the user clicks on a page in a multiple selection we want to reduce selection to just that page
        if (movedPages.count > 1) && (self.lastLocation == self.initialLocation) && !self.didShiftSelect && !self.didDoubleClick {
            layout.select([self.page], extendingSelection: false)
        }
        layout.finishedModifying(movedPages)
    }
}
