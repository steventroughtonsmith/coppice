//
//  PageTitleBarEventContext.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 11/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class PageTitleBarEventContext: CanvasEventContext {
    private var lastLocation: CGPoint?
    private var initialLocation: CGPoint?

    let page: LayoutEnginePage
    init(page: LayoutEnginePage) {
        self.page = page
    }

    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {
        //Toggle selection if the user is shift clicking
        if (modifiers.contains(.shift)) {
            self.page.selected = !self.page.selected
        }
        //Otherwise we want to select just the clicked page if it isn't already selected (if it is then we assume the user is about the drag the selection
        else if (self.page.selected == false) {
            layout.deselectAll()
            self.page.selected = true
        }

        if (eventCount == 2) {
            let pages = layout.allChildren(of: self.page)
            pages.forEach { $0.selected = true }
        }
        self.lastLocation = location
    }

    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {
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

    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {
        let movedPages = layout.selectedPages
        layout.finishedModifying(movedPages)
    }
}
