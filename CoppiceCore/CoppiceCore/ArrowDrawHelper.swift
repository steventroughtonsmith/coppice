//
//  ArrowDrawHelper.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 21/07/2020.
//

import AppKit

public class ArrowDrawHelper {
    public let config: CanvasLayoutEngine.Configuration.Arrow
    public init(config: CanvasLayoutEngine.Configuration.Arrow) {
        self.config = config
    }

    public func draw(_ arrow: LayoutEngineLink, with colour: NSColor) {
        self.drawLine(for: arrow, with: colour)
        self.drawArrowHead(for: arrow, with: colour)
    }

    private func drawLine(for arrow: LayoutEngineLink, with lineColour: NSColor) {
        let path: NSBezierPath
        switch arrow.sourcePoint.edge {
        case .top, .bottom:
            path = self.pathForVerticalLine(from: arrow.startPointInLayoutFrame, to: arrow.endPointInLayoutFrame)
        case .left, .right:
            path = self.pathForHorizontalLine(from: arrow.startPointInLayoutFrame, to: arrow.endPointInLayoutFrame)
        }

        lineColour.set()
        path.lineWidth = self.config.lineWidth
        path.stroke()
    }

    private func drawArrowHead(for arrow: LayoutEngineLink, with lineColour: NSColor) {
        let endPoint = arrow.endPointInLayoutFrame

        var arrowStart = endPoint.point
        var arrowEnd = endPoint.point

        let arrowArmSize = self.config.arrowHeadSize / 2
        switch endPoint.edge {
        case .left:
            arrowStart.x -= arrowArmSize
            arrowStart.y -= arrowArmSize
            arrowEnd.x -= arrowArmSize
            arrowEnd.y += arrowArmSize
        case .top:
            arrowStart.x -= arrowArmSize
            arrowStart.y -= arrowArmSize
            arrowEnd.x += arrowArmSize
            arrowEnd.y -= arrowArmSize
        case .right:
            arrowStart.x += arrowArmSize
            arrowStart.y -= arrowArmSize
            arrowEnd.x += arrowArmSize
            arrowEnd.y += arrowArmSize
        case .bottom:
            arrowStart.x -= arrowArmSize
            arrowStart.y += arrowArmSize
            arrowEnd.x += arrowArmSize
            arrowEnd.y += arrowArmSize
        }

        let path = NSBezierPath()
        path.move(to: arrowStart)
        path.line(to: endPoint.point)
        path.line(to: arrowEnd)

        lineColour.set()
        path.lineWidth = self.config.lineWidth
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        path.stroke()
    }

    private func pathForVerticalLine(from startPoint: ArrowPoint, to endPoint: ArrowPoint) -> NSBezierPath {
        let topToBottom = (startPoint.edge == .bottom) //A top to bottom arrow goes from the bottom of the top item)

        let path = NSBezierPath()

        let lineStart = startPoint.point
        var startStraight = lineStart
        startStraight.y += topToBottom ? self.config.endLength : -self.config.endLength


        let lineEnd = endPoint.point
        var endStraight = lineEnd
        endStraight.y += topToBottom ? -self.config.endLength : self.config.endLength

        let startControl: CGPoint
        let endControl: CGPoint

        let halfY = (startStraight.y + endStraight.y) / 2
        if topToBottom {
            let minStartY = startStraight.y + self.config.cornerSize
            startControl = CGPoint(x: startStraight.x, y: max(halfY, minStartY))

            let maxEndY = endStraight.y - self.config.cornerSize
            endControl = CGPoint(x: endStraight.x, y: min(halfY, maxEndY))
        } else {
            let maxStartY = startStraight.y - self.config.cornerSize
            startControl = CGPoint(x: startStraight.x, y: min(halfY, maxStartY))

            let minEndY = endStraight.y + self.config.cornerSize
            endControl = CGPoint(x: endStraight.x, y: max(halfY, minEndY))
        }

        path.move(to: lineStart)
        path.line(to: startStraight)
        path.curve(to: endStraight, controlPoint1: startControl, controlPoint2: endControl)
        path.line(to: lineEnd)
        return path
    }

    private func pathForHorizontalLine(from startPoint: ArrowPoint, to endPoint: ArrowPoint) -> NSBezierPath {
        let leftToRight = (startPoint.edge == .right) //A left to right arrow goes from the right of the left item)

        let path = NSBezierPath()

        let lineStart = startPoint.point
        var startStraight = lineStart
        startStraight.x += leftToRight ? self.config.endLength : -self.config.endLength


        let lineEnd = endPoint.point
        var endStraight = lineEnd
        endStraight.x += leftToRight ? -self.config.endLength : self.config.endLength

        let startControl: CGPoint
        let endControl: CGPoint

        let halfX = (startStraight.x + endStraight.x) / 2
        if leftToRight {
            let minStartX = startStraight.x + self.config.cornerSize
            startControl = CGPoint(x: max(halfX, minStartX), y: startStraight.y)

            let maxEndX = endStraight.x - self.config.cornerSize
            endControl = CGPoint(x: min(halfX, maxEndX), y: endStraight.y)
        } else {
            let maxStartX = startStraight.x - self.config.cornerSize
            startControl = CGPoint(x: min(halfX, maxStartX), y: startStraight.y)

            let minEndX = endStraight.x + self.config.cornerSize
            endControl = CGPoint(x: max(halfX, minEndX), y: endStraight.y)
        }

        path.move(to: lineStart)
        path.line(to: startStraight)
        path.curve(to: endStraight, controlPoint1: startControl, controlPoint2: endControl)
        path.line(to: lineEnd)
        return path
    }
}
