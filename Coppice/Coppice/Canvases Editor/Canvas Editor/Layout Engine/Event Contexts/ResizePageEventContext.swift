//
//  ResizePageEventContext.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 11/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ResizePageEventContext: CanvasMouseEventContext {
    var lastLocation: CGPoint?
    var startPoint: CGPoint?

    let page: LayoutEnginePage
    let component: LayoutEnginePageComponent
    let startLayoutFrame: CGRect
    init(page: LayoutEnginePage, component: LayoutEnginePageComponent) {
        self.page = page
        self.component = component
        self.startLayoutFrame = page.layoutFrame
    }

    //MARK: - Events
    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        self.startPoint = location
    }

    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        guard let startPoint = self.startPoint else {
            return
        }
        let boundedLocation = location.bounded(within: CGRect(origin: .zero, size: layout.canvasSize))

        let delta = boundedLocation.minus(startPoint).rounded()

        self.resize(withDelta: delta, in: layout)

        self.lastLocation = boundedLocation
    }

    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        layout.finishedModifying([self.page])
    }


    //MARK: - Convenience
    @discardableResult func resize(withDelta delta: CGPoint, in layout: LayoutEngine) -> CGPoint {
        let finalDelta: CGPoint
        if (self.page.maintainAspectRatio) {
            finalDelta = self.performAspectResize(with: delta, in: layout)
        } else {
            finalDelta = self.performRegularResize(with: delta, in: layout)
        }

        layout.modified([self.page])
        return finalDelta
    }


    //MARK: - Resizing
    private func performRegularResize(with delta: CGPoint, in layout: LayoutEngine) -> CGPoint {
        var layoutFrame = self.startLayoutFrame

        var deltaX = delta.x
        if (self.component.isRight) {
            if (layoutFrame.width + deltaX < self.page.minimumLayoutSize.width) {
                deltaX = self.page.minimumLayoutSize.width - layoutFrame.width
            }
            //If the page is outside the canvas right edge then reduce the delta by the overshoot and fit inside
            if ((layoutFrame.maxX + deltaX) > layout.canvasSize.width) {
                deltaX = layout.canvasSize.width - layoutFrame.maxX
            }
            layoutFrame.size.width += deltaX
        }
        else if (self.component.isLeft) {
            if (layoutFrame.width - deltaX < self.page.minimumLayoutSize.width) {
                deltaX = -(self.page.minimumLayoutSize.width - layoutFrame.width)
            }

            //If the page is outside the canvas left edge then reduce the delta by the overshoot and fit inside
            if ((layoutFrame.origin.x + deltaX) < 0) {
                deltaX = -(layoutFrame.origin.x)
            }

            layoutFrame.size.width -= deltaX
            layoutFrame.origin.x += deltaX
        }

        var deltaY = delta.y
        if (self.component.isBottom) {
            if (layoutFrame.height + deltaY < self.page.minimumLayoutSize.height) {
                deltaY = self.page.minimumLayoutSize.height - layoutFrame.height
            }
            //If the page is outside the canvas bottom edge then reduce the delta by the overshoot and fit inside
            if ((layoutFrame.maxY + deltaY) > layout.canvasSize.height) {
                deltaY = layout.canvasSize.height - layoutFrame.maxY
            }
            layoutFrame.size.height += deltaY
        }
        else if (self.component.isTop) {
            if (layoutFrame.height - deltaY < self.page.minimumLayoutSize.height) {
                deltaY = -(self.page.minimumLayoutSize.height - layoutFrame.height)
            }
            //If the page is outside the canvas top edge then reduce the delta by the overshoot and fit inside
            if ((layoutFrame.origin.y + deltaY) < 0) {
                deltaY = -(layoutFrame.origin.y)
            }
            layoutFrame.size.height -= deltaY
            layoutFrame.origin.y += deltaY
        }

        self.page.layoutFrame = layoutFrame
        return CGPoint(x: deltaX, y: deltaY)
    }

    private func performAspectResize(with delta: CGPoint, in layout: LayoutEngine) -> CGPoint {
        if (self.component.isTop) {
            return self.performTopAspectResize(with: delta, in: layout)
        }
        else if (self.component.isBottom) {
            return self.performBottomAspectResize(with: delta, in: layout)
        }
        return .zero
    }

    private func performTopAspectResize(with delta: CGPoint, in layout: LayoutEngine) -> CGPoint {
        var layoutFrame = self.startLayoutFrame

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

        //We handle deltaX differently depending on if it's left or right, so we need to account for that here
        let modifiedDeltaX = self.component.isRight ? -deltaX : deltaX
        return CGPoint(x: modifiedDeltaX, y: deltaY)
    }

    private func performBottomAspectResize(with delta: CGPoint, in layout: LayoutEngine) -> CGPoint {
        var layoutFrame = self.startLayoutFrame

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

        //We handle deltaX differently depending on if it's left or right, so we need to account for that here
        let modifiedDeltaX = self.component.isRight ? deltaX : -deltaX
        return CGPoint(x: modifiedDeltaX, y: deltaY)
    }
}
