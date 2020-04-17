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
            self.performAspectResize(with: delta, in: layout)
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

    private func performAspectResize(with delta: CGPoint, in layout: CanvasLayoutEngine) {
        if (self.component.isTop) {
            self.performTopAspectResize(with: delta, in: layout)
        }
        else if (self.component.isBottom) {
            self.performBottomAspectResize(with: delta, in: layout)
        }
    }

    private func performTopAspectResize(with delta: CGPoint, in layout: CanvasLayoutEngine) {
        var layoutFrame = self.page.layoutFrame

        var deltaY = delta.y //deltaY is negative if increasing size, positive if decreasing size
        var deltaX = deltaY * self.page.aspectRatio

        //Constraint max vertically
        if layoutFrame.minY + deltaY < 0 {
            deltaY = -layoutFrame.minY
            deltaX = deltaY * self.page.aspectRatio
        }

        //Constraint max horizontally
        if self.component.isLeft && (layoutFrame.minX + deltaX < 0) {
            deltaX = -layoutFrame.minX
            deltaY = deltaX / self.page.aspectRatio
        }
        else if self.component.isRight && ((layoutFrame.maxX - deltaX) > layout.canvasSize.width) {
            deltaX = -(layout.canvasSize.width - layoutFrame.maxX)
            deltaY = deltaX / self.page.aspectRatio
        }

        //Constraint min size
        if layoutFrame.height - deltaY < self.page.minimumLayoutSize.height {
            deltaY = layoutFrame.height - self.page.minimumLayoutSize.height
            deltaX = deltaY * self.page.aspectRatio
        }
        if layoutFrame.width - deltaX < self.page.minimumLayoutSize.width {
            deltaX = layoutFrame.width - self.page.minimumLayoutSize.width
            deltaY = deltaX / self.page.aspectRatio
        }


        layoutFrame.size.height -= deltaY
        layoutFrame.size.width -= deltaX

        layoutFrame.origin.y += deltaY
        if (self.component.isLeft) {
            layoutFrame.origin.x += deltaX
        }
        self.page.layoutFrame = layoutFrame
    }

    private func performBottomAspectResize(with delta: CGPoint, in layout: CanvasLayoutEngine) {
        var layoutFrame = self.page.layoutFrame

        var deltaY = delta.y //DeltaY is positive if increasing size, negative if decreasing size
        var deltaX = deltaY * self.page.aspectRatio

        //Constraint max vertically
        if (layoutFrame.maxY + deltaY) > layout.canvasSize.height {
            deltaY = layout.canvasSize.height - layoutFrame.maxY
            deltaX = deltaY * self.page.aspectRatio
        }

        //Constraint max horizontally
        if self.component.isLeft && (layoutFrame.minX - deltaX < 0) {
            deltaX = layoutFrame.minX
            deltaY = deltaX / self.page.aspectRatio
        }
        else if self.component.isRight && ((layoutFrame.maxX + deltaX) > layout.canvasSize.width) {
            deltaX = layout.canvasSize.width - layoutFrame.maxX
            deltaY = deltaX / self.page.aspectRatio
        }

        //Constraint min size
        if layoutFrame.height + deltaY < self.page.minimumLayoutSize.height {
            deltaY = -(layoutFrame.height - self.page.minimumLayoutSize.height)
            deltaX = deltaY * self.page.aspectRatio
        }
        if layoutFrame.width + deltaX < self.page.minimumLayoutSize.width {
            deltaX = -(layoutFrame.width - self.page.minimumLayoutSize.width)
            deltaY = deltaX / self.page.aspectRatio
        }

        layoutFrame.size.height += deltaY
        layoutFrame.size.width += deltaX
        if (self.component.isLeft) {
            layoutFrame.origin.x -= deltaX
        }

        self.page.layoutFrame = layoutFrame
    }
}
