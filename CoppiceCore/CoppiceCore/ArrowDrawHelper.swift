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

    public func draw(_ arrow: LayoutEngineLink, with colour: NSColor, borderColor: NSColor?, isConcrete: Bool) {
        let lineWidth = self.config.lineWidth
        if let borderColor {
            self.drawLine(for: arrow, with: borderColor, lineWidth: lineWidth + 3, isConcrete: true)
            self.drawArrowHead(for: arrow, with: borderColor, lineWidth: lineWidth + 3)
        }

        self.drawLine(for: arrow, with: colour, lineWidth: lineWidth, isConcrete: isConcrete)
        self.drawArrowHead(for: arrow, with: colour, lineWidth: lineWidth)
    }

    private func drawLine(for arrow: LayoutEngineLink, with lineColour: NSColor, lineWidth: CGFloat, isConcrete: Bool) {
        let path = arrow.linePath
        lineColour.set()
        path.lineWidth = lineWidth
        if !isConcrete {
            path.setLineDash([10.0, 10.0], count: 2, phase: 10.0)
        }
        path.stroke()
    }

    private func drawArrowHead(for arrow: LayoutEngineLink, with lineColour: NSColor, lineWidth: CGFloat) {
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
        path.lineWidth = lineWidth
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        path.stroke()
    }
}
