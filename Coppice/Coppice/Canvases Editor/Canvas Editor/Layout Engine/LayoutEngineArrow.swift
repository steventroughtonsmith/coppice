//
//  LayoutEngineArrow.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import CoppiceCore

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
        return (otherArrow.startPoint.pageID == self.startPoint.pageID) && (otherArrow.endPoint.pageID == self.endPoint.pageID)
    }


    //MARK: - Pages
    var startPage: LayoutEnginePage? {
        return self.layoutEngine?.page(withID: self.startPoint.pageID)
    }

    var endPage: LayoutEnginePage? {
        return self.layoutEngine?.page(withID: self.endPoint.pageID)
    }


    //MARK: - Frames

    var layoutFrame: CGRect {
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

    var startPointInLayoutFrame: ArrowPoint {
        var startPoint = self.startPoint
        startPoint.point = startPoint.point.minus(self.layoutFrame.origin)
        return startPoint
    }

    var endPointInLayoutFrame: ArrowPoint {
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
