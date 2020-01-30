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

    func plus(x: CGFloat = 0, y: CGFloat = 0) -> CGPoint {
        return self.plus(CGPoint(x: x, y: y))
    }

    func minus(_ point: CGPoint) -> CGPoint {
        return self.plus(point.multiplied(by: -1))
    }

    func minus(x: CGFloat = 0, y: CGFloat = 0) -> CGPoint {
        return self.minus(CGPoint(x: x, y: y))
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

    func plus(width: CGFloat = 0, height: CGFloat = 0) -> CGSize {
        return self.plus(CGSize(width: width, height: height))
    }

    func rounded() -> CGSize {
        let width = round(self.width)
        let height = round(self.height)
        return CGSize(width: width, height: height)
    }

    func multiplied(by value: CGFloat) -> CGSize {
        var size = self
        size.width *= value
        size.height *= value
        return size
    }

    func toRect(withOrigin origin: CGPoint = .zero) -> CGRect {
        return CGRect(origin: origin, size: self)
    }

    func toPoint() -> CGPoint {
        return CGPoint(x: self.width, y: self.height)
    }
}

extension CGRect {
    func rounded() -> CGRect {
        let origin = self.origin.rounded()
        let size = self.size.rounded()
        return CGRect(origin: origin, size: size)
    }

    init(width: CGFloat, height: CGFloat, centredIn rect: CGRect) {
        let x = rect.midX - (width / 2)
        let y = rect.midY - (height / 2)
        self.init(x: x.rounded(), y: y.rounded(), width: width, height: height)
    }

    enum RectPoint {
        case min
        case mid
        case max
    }

    func point(atX x: RectPoint, y: RectPoint) -> CGPoint {
        var point = CGPoint()
        switch x {
        case .min:
            point.x = self.minX
        case .mid:
            point.x = self.midX
        case .max:
            point.x = self.maxX
        }

        switch y {
        case .min:
            point.y = self.minY
        case .mid:
            point.y = self.midY
        case .max:
            point.y = self.maxY
        }
        return point
    }

    var midPoint: CGPoint {
        return self.point(atX: .mid, y: .mid)
    }
}
