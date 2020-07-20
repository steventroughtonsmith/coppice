//
//  LayoutEngineArrow.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public struct ArrowPoint: Equatable {
    public var point: CGPoint
    public var edge: LayoutEnginePage.Edge
    public var pageID: UUID

    public init(point: CGPoint, edge: LayoutEnginePage.Edge, pageID: UUID) {
        self.point = point
        self.edge = edge
        self.pageID = pageID
    }
}

public class LayoutEngineArrow: Equatable {
    public let startPoint: ArrowPoint
    public let endPoint: ArrowPoint

    public weak var layoutEngine: CanvasLayoutEngine?

    public init(startPoint: ArrowPoint, endPoint: ArrowPoint, layoutEngine: CanvasLayoutEngine? = nil) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.layoutEngine = layoutEngine
    }


    //MARK: - Comparison
    public static func == (lhs: LayoutEngineArrow, rhs: LayoutEngineArrow) -> Bool {
        return (lhs.startPoint == rhs.startPoint) && (lhs.endPoint == rhs.endPoint)
    }

    public func betweenSamePages(as otherArrow: LayoutEngineArrow) -> Bool {
        return (otherArrow.startPoint.pageID == self.startPoint.pageID) && (otherArrow.endPoint.pageID == self.endPoint.pageID)
    }


    //MARK: - Pages
    public var startPage: LayoutEnginePage? {
        return self.layoutEngine?.page(withID: self.startPoint.pageID)
    }

    public var endPage: LayoutEnginePage? {
        return self.layoutEngine?.page(withID: self.endPoint.pageID)
    }


    //MARK: - Frames

    public var layoutFrame: CGRect {
        guard let basicFrame = CGRect(points: [self.startPoint.point, self.endPoint.point]) else {
            return .zero
        }

        guard let config = layoutEngine?.configuration else {
            return basicFrame
        }

        let arrowConfig = config.arrow

        let invertedArrowOffset = arrowConfig.endLength + arrowConfig.cornerSize

        var xInset: CGFloat = 0
        var yInset: CGFloat = 0
        switch self.startPoint.edge {
        case .top, .bottom:
            xInset = -(arrowConfig.arrowHeadSize / 2) - arrowConfig.lineWidth
            yInset = -(invertedArrowOffset / 2) - arrowConfig.lineWidth - config.page.titleHeight
        case .left, .right:
            xInset = -(invertedArrowOffset / 2) - arrowConfig.lineWidth
            yInset = -(arrowConfig.arrowHeadSize / 2) - arrowConfig.lineWidth
        }

        return basicFrame.insetBy(dx: xInset, dy: yInset)
    }

    public var startPointInLayoutFrame: ArrowPoint {
        var startPoint = self.startPoint
        startPoint.point = startPoint.point.minus(self.layoutFrame.origin)
        return startPoint
    }

    public var endPointInLayoutFrame: ArrowPoint {
        var endPoint = self.endPoint
        endPoint.point = endPoint.point.minus(self.layoutFrame.origin)

        guard let config = self.layoutEngine?.configuration else {
            return endPoint
        }

        let lineWidth = config.arrow.lineWidth

        let backgroundVisible = self.endPage?.showBackground ?? false
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
}
