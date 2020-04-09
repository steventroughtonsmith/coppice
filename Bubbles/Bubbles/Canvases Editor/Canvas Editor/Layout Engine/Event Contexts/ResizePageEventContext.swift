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

    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {
        self.lastLocation = location
    }

    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {
        guard let lastLocation = self.lastLocation else {
            return
        }
        let boundedLocation = location.bounded(within: CGRect(origin: .zero, size: layout.canvasSize))

        let delta = boundedLocation.minus(lastLocation).rounded()

        if (self.page.maintainAspectRatio) {
            self.performAspectResize(with: delta)
        } else {
            self.performRegularResize(with: delta)
        }

        self.lastLocation = boundedLocation
        layout.modified([self.page])
    }

    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {
        layout.finishedModifying([self.page])
    }


    //MARK: - Resizing
    private func performRegularResize(with delta: CGPoint) {
        var layoutFrame = self.page.layoutFrame

        var deltaX = delta.x
        if (self.component.isRight) {
            if (layoutFrame.width + deltaX < self.page.minimumLayoutSize.width) {
                deltaX = self.page.minimumLayoutSize.width - layoutFrame.width
            }
            layoutFrame.size.width += deltaX
        }
        else if (self.component.isLeft) {
            if (layoutFrame.width - deltaX < self.page.minimumLayoutSize.width) {
                deltaX = -(self.page.minimumLayoutSize.width - layoutFrame.width)
            }
            layoutFrame.size.width -= deltaX
            layoutFrame.origin.x += deltaX
        }

        var deltaY = delta.y
        if (self.component.isBottom) {
            if (layoutFrame.height + deltaY < self.page.minimumLayoutSize.height) {
                deltaY = self.page.minimumLayoutSize.height - layoutFrame.height
            }
            layoutFrame.size.height += deltaY
        }
        else if (self.component.isTop) {
            if (layoutFrame.height - deltaY < self.page.minimumLayoutSize.height) {
                deltaY = -(self.page.minimumLayoutSize.height - layoutFrame.height)
            }
            layoutFrame.size.height -= deltaY
            layoutFrame.origin.y += deltaY
        }

        self.page.layoutFrame = layoutFrame
    }

    private func performAspectResize(with delta: CGPoint) {
        var layoutFrame = self.page.layoutFrame



        let deltaY = delta.y
        let deltaX = (delta.y * layoutFrame.width) / layoutFrame.height
        if (self.component.isBottom) {
            layoutFrame.size.height += deltaY
            layoutFrame.size.width += deltaX
            if (self.component.isLeft) {
                layoutFrame.origin.x -= deltaX
            }
        }
        else if (self.component.isTop) {
            layoutFrame.size.height -= deltaY
            layoutFrame.size.width -= deltaX

            layoutFrame.origin.y += deltaY
            if (self.component.isLeft) {
                layoutFrame.origin.x += deltaX
            }
        }

        self.page.layoutFrame = layoutFrame
    }
}
