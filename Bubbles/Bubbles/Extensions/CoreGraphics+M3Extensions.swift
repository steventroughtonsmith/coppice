//
//  CoreGraphicsExtensions.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 06/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGPoint {
    func multiplied(by value: CGFloat) -> CGPoint {
        var newPoint = self
        newPoint.x *= value
        newPoint.y *= value
        return newPoint
    }

    func plus(_ point: CGPoint) -> CGPoint {
        var newPoint = self
        newPoint.x += point.x
        newPoint.y += point.y
        return newPoint
    }

    func minus(_ point: CGPoint) -> CGPoint {
        return self.plus(point.multiplied(by: -1))
    }

    func bounded(within rect: CGRect) -> CGPoint {
        let x = min(max(self.x, rect.minX), (rect.maxX - 1))
        let y = min(max(self.y, rect.minY), (rect.maxY - 1))
        return CGPoint(x: x, y: y)
    }

    static var identity: CGPoint {
        return CGPoint(x: 1, y: 1)
    }

    func rounded() -> CGPoint {
        let x = round(self.x)
        let y = round(self.y)
        return CGPoint(x: x, y: y)
    }
}


extension CGSize {
    func plus(_ size: CGSize) -> CGSize {
        var newSize = self
        newSize.width += size.width
        newSize.height += size.height
        return newSize
    }
}
