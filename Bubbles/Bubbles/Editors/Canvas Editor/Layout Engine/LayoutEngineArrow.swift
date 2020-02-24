//
//  LayoutEngineArrow.swift
//  Bubbles
//
//  Created by Martin Pilkington on 20/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

struct ArrowPoint: Equatable {
    var point: CGPoint
    var edge: LayoutEnginePage.Edge
    var pageID: UUID
}

class LayoutEngineArrow: Equatable {
    let startPoint: ArrowPoint
    let endPoint: ArrowPoint

    weak var layoutEngine: CanvasLayoutEngine?

    init(startPoint: ArrowPoint, endPoint: ArrowPoint, layoutEngine: CanvasLayoutEngine? = nil) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.layoutEngine = layoutEngine
    }


    //MARK: - Comparison
    static func == (lhs: LayoutEngineArrow, rhs: LayoutEngineArrow) -> Bool {
        return (lhs.startPoint == rhs.startPoint) && (lhs.endPoint == rhs.endPoint)
    }

    func betweenSamePages(as otherArrow: LayoutEngineArrow) -> Bool {
        return (otherArrow.startPoint.pageID == self.startPoint.pageID) && (otherArrow.endPoint.pageID == self.startPoint.pageID)
    }

    var layoutFrame: CGRect {
        guard let basicFrame = CGRect(points: [self.startPoint.point, self.endPoint.point]) else {
            return .zero
        }

        guard let config = layoutEngine?.configuration.arrow else {
            return basicFrame
        }

        let invertedArrowOffset = config.endLength + config.cornerSize + config.lineWidth

        var xInset: CGFloat = 0
        var yInset: CGFloat = 0
        switch self.startPoint.edge {
        case .top, .bottom:
            xInset = -config.arrowHeadSize
            yInset = -invertedArrowOffset
        case .left, .right:
            xInset = -invertedArrowOffset
            yInset = -config.arrowHeadSize
        }

        return basicFrame.insetBy(dx: xInset, dy: yInset)
    }

    var startPointInLayoutFrame: ArrowPoint {
        var startPoint = self.startPoint
        startPoint.point = startPoint.point.minus(self.layoutFrame.origin)
        return startPoint
    }

    var endPointInLayoutFrame: ArrowPoint {
        var endPoint = self.endPoint
        endPoint.point = endPoint.point.minus(self.layoutFrame.origin)
        return endPoint
    }
}
