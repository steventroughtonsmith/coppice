//
//  PageArrowView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

class PageArrowView: NSView {
    var arrow: Arrow?

    let lineWidth: CGFloat
    init(lineWidth: CGFloat) {
        self.lineWidth = lineWidth
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override var isFlipped: Bool {
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.yellow.withAlphaComponent(0.7).set()
        self.bounds.fill()
        NSColor.black.set()
        NSBezierPath(rect: self.bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()
        return

        let linePath = self.linePath()
        NSColor(white: 0.9, alpha: 1).setStroke()
        linePath.stroke()

        NSColor(white: 0.4, alpha: 1).setStroke()
        let arrowPath = self.arrowPath()
        arrowPath.stroke()
    }


    private func linePath() -> NSBezierPath {
        let path = NSBezierPath()
        guard let arrow = self.arrow else {
            return path
        }

//        let offset = self.lineWidth / 2
//        let startX: CGFloat
//        let endX: CGFloat
//        if (arrow.horizontalDirection == .minEdge) {
//            startX = self.bounds.maxX - offset
//            endX = self.bounds.minX + offset
//        } else {
//            startX = self.bounds.minX + offset
//            endX = self.bounds.maxX - offset
//        }
//
//        let startY: CGFloat
//        let endY: CGFloat
//        if (arrow.verticalDirection == .minEdge) {
//            startY = self.bounds.maxY - offset
//            endY = self.bounds.minY + offset
//        } else {
//            startY = self.bounds.minY + offset
//            endY = self.bounds.maxY - offset
//        }
//
//        path.move(to: CGPoint(x: startX, y: startY))
//        path.line(to: CGPoint(x: endX, y: endY))
//
//        path.lineWidth = self.lineWidth
        return path
    }


    private func arrowPath() -> NSBezierPath {
        let arrowSize = self.arrowSize()
        let angle = self.angleFromOrigin()
        let offset = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
        let startPoint = self.rotate(CGPoint(x: -arrowSize, y: arrowSize), byAngle: -angle).plus(offset)
        let endPoint = self.rotate(CGPoint(x: -arrowSize, y: -arrowSize), byAngle: -angle).plus(offset)

        let bezierPath = NSBezierPath()
        bezierPath.move(to: startPoint)
        bezierPath.line(to: offset)
        bezierPath.line(to: endPoint)
        bezierPath.lineWidth = 5
        return bezierPath
    }

    private func rotate(_ point: CGPoint, byAngle angle: CGFloat) -> CGPoint {
        return CGPoint(x: (point.x * cos(angle)) - (point.y * sin(angle)),
                       y: (point.x * sin(angle)) + (point.y * cos(angle)))
    }

    private func angleFromOrigin() -> CGFloat {
        return 0
//        guard let arrow = self.arrow else {
//            return 0.0
//        }
//
//        let innerAngle = atan(self.bounds.height/self.bounds.width)
//        switch (arrow.horizontalDirection, arrow.verticalDirection) {
//        case (.maxEdge, .minEdge):
//            return innerAngle
//        case (.minEdge, .minEdge):
//            return CGFloat.pi - innerAngle
//        case (.minEdge, .maxEdge):
//            return CGFloat.pi + innerAngle
//        case (.maxEdge, .maxEdge):
//            return (2 * CGFloat.pi) - innerAngle
//        }
    }

    func arrowSize() -> CGFloat {
        return self.lineWidth / 2
    }
}
