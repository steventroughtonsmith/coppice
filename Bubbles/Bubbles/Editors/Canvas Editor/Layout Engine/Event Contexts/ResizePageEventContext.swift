//
//  ResizePageEventContext.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 11/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ResizePageEventContext: CanvasEventContext {
    var lastLocation: CGPoint?

    let page: LayoutEnginePage
    let component: LayoutEnginePageComponent
    init(page: LayoutEnginePage, component: LayoutEnginePageComponent) {
        self.page = page
        self.component = component
    }

    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, in layout: CanvasLayoutEngine) {
        self.lastLocation = location
    }

    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, in layout: CanvasLayoutEngine) {
        guard let lastLocation = self.lastLocation else {
            return
        }
        let boundedLocation = location.bounded(within: CGRect(origin: .zero, size: layout.canvasSize))

        var delta = boundedLocation.minus(lastLocation).rounded()
        if (self.component.isRight) {
            if (self.page.layoutFrame.size.width + delta.x < self.page.minimumLayoutSize.width) {
                delta.x = self.page.minimumLayoutSize.width - self.page.layoutFrame.size.width
            }
            self.page.layoutFrame.size.width += delta.x
        }

        if (self.component.isBottom) {
            if (self.page.layoutFrame.size.height + delta.y < self.page.minimumLayoutSize.height) {
                delta.y = self.page.minimumLayoutSize.height - self.page.layoutFrame.size.height
            }
            self.page.layoutFrame.size.height += delta.y
        }

        if (self.component.isLeft) {
            if (self.page.layoutFrame.size.width - delta.x < self.page.minimumLayoutSize.width) {
                delta.x = -(self.page.minimumLayoutSize.width - self.page.layoutFrame.size.width)
            }
            self.page.layoutFrame.size.width -= delta.x
            self.page.layoutFrame.origin.x += delta.x
        }

        if (self.component.isTop) {
            if (self.page.layoutFrame.size.height - delta.y < self.page.minimumLayoutSize.height) {
                delta.y = -(self.page.minimumLayoutSize.height - self.page.layoutFrame.size.height)
            }
            self.page.layoutFrame.size.height -= delta.y
            self.page.layoutFrame.origin.y += delta.y
        }

        self.lastLocation = boundedLocation
    }

    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, in layout: CanvasLayoutEngine) {
        layout.finishedModifying([self.page])
    }
}
