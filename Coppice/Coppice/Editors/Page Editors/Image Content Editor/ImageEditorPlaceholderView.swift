//
//  ImageEditorPlaceHolderView.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class ImageEditorPlaceholderView: NSView {
    @IBInspectable var colour: NSColor = NSColor(white: 0.5, alpha: 1)

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        self.colour.withAlphaComponent(0.75).set()
        let bounds = self.bounds.insetBy(dx: 2, dy: 2)

        self.drawCorner(in: bounds, xEdge: .min, yEdge: .max, size: 10) //Top-left
        self.drawCorner(in: bounds, xEdge: .max, yEdge: .max, size: 10) //Top-right
        self.drawCorner(in: bounds, xEdge: .max, yEdge: .min, size: 10) //Bottom-right
        self.drawCorner(in: bounds, xEdge: .min, yEdge: .min, size: 10) //Bottom-left

        self.drawDashedLine(between: bounds.point(atX: .min, y: .max).plus(x: 10, y: 0),
                            and: bounds.point(atX: .max, y: .max).plus(x: -10, y: 0)) //Top
        self.drawDashedLine(between: bounds.point(atX: .max, y: .max).plus(x: 0, y: -10),
                            and: bounds.point(atX: .max, y: .min).plus(x: 0, y: 10)) //Right
        self.drawDashedLine(between: bounds.point(atX: .max, y: .min).plus(x: -10, y: 0),
                            and: bounds.point(atX: .min, y: .min).plus(x: 10, y: 0)) //Bottom
        self.drawDashedLine(between: bounds.point(atX: .min, y: .min).plus(x: 0, y: 10),
                            and: bounds.point(atX: .min, y: .max).plus(x: 0, y: -10)) //Left
    }


    private func drawCorner(in bounds: CGRect, xEdge: CGRect.RectPoint, yEdge: CGRect.RectPoint, size: CGFloat) {
        let cornerPath = NSBezierPath()
        let cornerPoint = bounds.point(atX: xEdge, y: yEdge)
        cornerPath.move(to: cornerPoint.plus(x: 0, y: (yEdge == .min) ? size : -size))
        cornerPath.curve(to: cornerPoint.plus(x: (xEdge == .min) ? size : -size, y: 0),
                         controlPoint1: cornerPoint.plus(x: 0, y: (yEdge == .min) ? (size * 0.25) : -(size * 0.25)),
                         controlPoint2: cornerPoint.plus(x: (xEdge == .min) ? (size * 0.25) : -(size * 0.25), y: 0))
        cornerPath.lineWidth = 4
        cornerPath.stroke()
    }

    private func drawDashedLine(between firstPoint: CGPoint, and secondPoint: CGPoint) {
        let path = NSBezierPath()
        path.move(to: firstPoint)
        path.line(to: secondPoint)
        path.lineWidth = 4

        let steps: [CGFloat] = [10.0, 10.0]
        path.setLineDash(steps, count: 2, phase: 10.0)
        path.stroke()
    }
}
