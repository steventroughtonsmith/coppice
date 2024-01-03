//
//  LayoutEngineArrow.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit
import Foundation

public struct ArrowPoint: Equatable {
    public var point: CGPoint
    public var edge: LayoutEnginePage.Edge

    public init(point: CGPoint, edge: LayoutEnginePage.Edge) {
        self.point = point
        self.edge = edge
    }

    func adjusted(by adjustment: CGPoint) -> ArrowPoint {
        return ArrowPoint(point: self.point.plus(adjustment), edge: self.edge)
    }
}

public class LayoutEngineLink: LayoutEngineItem {
    public let pageLink: PageLink?
    public let sourcePageID: UUID
    public let destinationPageID: UUID
    public var highlighted: Bool = false

    weak var linkLayoutEngine: LinkLayoutEngine?

    public var sourcePoint: ArrowPoint = .init(point: .zero, edge: .left)
    public var destinationPoint: ArrowPoint = .init(point: .zero, edge: .right)

    public init(id: UUID, pageLink: PageLink?, sourcePageID: UUID, destinationPageID: UUID, canvasLayoutEngine: CanvasLayoutEngine? = nil) {
        self.pageLink = pageLink
        self.sourcePageID = sourcePageID
        self.destinationPageID = destinationPageID
        super.init(id: id)
        self.canvasLayoutEngine = canvasLayoutEngine
    }

    //MARK: - Comparison
    public static func == (lhs: LayoutEngineLink, rhs: LayoutEngineLink) -> Bool {
        return lhs.id == rhs.id
    }

    public func betweenSamePages(as otherArrow: LayoutEngineLink) -> Bool {
        return (otherArrow.sourcePageID == self.sourcePageID) && (otherArrow.destinationPageID == self.destinationPageID)
    }


    //MARK: - Pages
    public var sourcePage: LayoutEnginePage? {
        return self.canvasLayoutEngine?.page(withID: self.sourcePageID)
    }

    public var destinationPage: LayoutEnginePage? {
        return self.canvasLayoutEngine?.page(withID: self.destinationPageID)
    }

    func opposite(of page: LayoutEnginePage) -> LayoutEnginePage? {
        if self.sourcePage == page {
            return self.destinationPage
        }
        if self.destinationPage == page {
            return self.sourcePage
        }
        return nil
    }


    //MARK: - Frames
    public override var layoutFrame: CGRect {
        get {
            guard let basicFrame = CGRect(points: [self.sourcePoint.point, self.destinationPoint.point]) else {
                return .zero
            }

            guard let config = canvasLayoutEngine?.configuration else {
                return basicFrame
            }

            let arrowConfig = config.arrow

            let invertedArrowOffset = arrowConfig.endLength + arrowConfig.cornerSize

            var xInset: CGFloat = 0
            var yInset: CGFloat = 0
            switch self.sourcePoint.edge {
            case .top, .bottom:
                xInset = -(arrowConfig.arrowHeadSize / 2) - arrowConfig.lineWidth
                yInset = -(invertedArrowOffset / 2) - arrowConfig.lineWidth - config.page.titleHeight
            case .left, .right:
                xInset = -(invertedArrowOffset / 2) - arrowConfig.lineWidth
                yInset = -(arrowConfig.arrowHeadSize / 2) - arrowConfig.lineWidth
            }

            return basicFrame.insetBy(dx: xInset, dy: yInset)
        }
        set {}
    }

    public var startPointInLayoutFrame: ArrowPoint {
        var startPoint = self.sourcePoint
        startPoint.point = startPoint.point.minus(self.layoutFrame.origin)
        return startPoint
    }

    public var endPointInLayoutFrame: ArrowPoint {
        var endPoint = self.destinationPoint
        endPoint.point = endPoint.point.minus(self.layoutFrame.origin)

        guard let config = self.canvasLayoutEngine?.configuration else {
            return endPoint
        }

        let lineWidth = config.arrow.lineWidth

        let backgroundVisible = self.destinationPage?.showBackground ?? false
        //Reduce to account for line width and border visibility
        switch endPoint.edge {
        case .left:
            endPoint.point.x -= lineWidth
            if backgroundVisible {
                endPoint.point.x -= config.page.borderSize
            }
        case .top:
            endPoint.point.y -= lineWidth
            if backgroundVisible {
                endPoint.point.y -= config.page.titleHeight
            }
        case .right:
            endPoint.point.x += lineWidth
            if backgroundVisible {
                endPoint.point.x += config.page.borderSize
            }
        case .bottom:
            endPoint.point.y += lineWidth
            if backgroundVisible {
                endPoint.point.y += config.page.borderSize
            }
        }
        return endPoint
    }

    public var linePath: NSBezierPath {
        switch self.sourcePoint.edge {
        case .top, .bottom:
            return self.verticalPath
        case .left, .right:
            return self.horizontalPath
        }
    }

    public var interactionPath: NSBezierPath {
        guard let config = self.canvasLayoutEngine?.configuration.arrow else {
            return self.linePath
        }
        return self.linePath.bezierPath(strokedWithWidth: config.arrowHeadSize)
    }

    private var verticalPath: NSBezierPath {
        let path = NSBezierPath()

        guard let config = self.canvasLayoutEngine?.configuration.arrow else {
            return path
        }

        let topToBottom = (self.sourcePoint.edge == .bottom)

        let topPoint = topToBottom ? self.startPointInLayoutFrame.point : self.endPointInLayoutFrame.point
        let bottomPoint = topToBottom ? self.endPointInLayoutFrame.point : self.startPointInLayoutFrame.point
        let topStraightPoint = topPoint.plus(y: config.endLength)
        let bottomStraightPoint = bottomPoint.minus(y: config.endLength)

        let halfY = (topStraightPoint.y + bottomStraightPoint.y) / 2
        let minY = topStraightPoint.y + config.cornerSize
        let topControl = CGPoint(x: topStraightPoint.x, y: max(halfY, minY))

        let maxY = bottomStraightPoint.y - config.cornerSize
        let bottomControl = CGPoint(x: bottomStraightPoint.x, y: min(halfY, maxY))

        path.move(to: topPoint)
        path.line(to: topStraightPoint)
        path.curve(to: bottomStraightPoint, controlPoint1: topControl, controlPoint2: bottomControl)
        path.line(to: bottomPoint)

        return path
    }

    private var horizontalPath: NSBezierPath {
        let path = NSBezierPath()
        guard let config = self.canvasLayoutEngine?.configuration.arrow else {
            return path
        }

        let leftToRight = (self.sourcePoint.edge == .right)

        let leftPoint = leftToRight ? self.startPointInLayoutFrame.point : self.endPointInLayoutFrame.point
        let rightPoint = leftToRight ? self.endPointInLayoutFrame.point : self.startPointInLayoutFrame.point
        let leftStraightPoint = leftPoint.plus(x: config.endLength)
        let rightStraightPoint = rightPoint.minus(x: config.endLength)

        let halfX = (leftStraightPoint.x + rightStraightPoint.x) / 2
        let minX = leftStraightPoint.x + config.cornerSize
        let leftControl = CGPoint(x: max(halfX, minX), y: leftStraightPoint.y)

        let maxX = rightStraightPoint.x - config.cornerSize
        let rightControl = CGPoint(x: min(halfX, maxX), y: rightStraightPoint.y)

        path.move(to: leftPoint)
        path.line(to: leftStraightPoint)
        path.curve(to: rightStraightPoint, controlPoint1: leftControl, controlPoint2: rightControl)
        path.line(to: rightPoint)

        return path
    }
}
