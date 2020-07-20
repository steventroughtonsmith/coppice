//
//  CoreGraphicsExtensions.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 06/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation
import CoreGraphics

public extension CGPoint {
    static var identity: CGPoint {
        return CGPoint(x: 1, y: 1)
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

    func multiplied(by value: CGFloat) -> CGPoint {
        var newPoint = self
        newPoint.x *= value
        newPoint.y *= value
        return newPoint
    }

    func rounded(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGPoint {
        let x = self.x.rounded(rule)
        let y = self.y.rounded(rule)
        return CGPoint(x: x, y: y)
    }

    func bounded(within rect: CGRect) -> CGPoint {
        let x = min(max(self.x, rect.minX), (rect.maxX - 1))
        let y = min(max(self.y, rect.minY), (rect.maxY - 1))
        return CGPoint(x: x, y: y)
    }

    func toRect(with size: CGSize = .zero) -> CGRect {
        return CGRect(origin: self, size: size)
    }

    func toSize() -> CGSize {
        return CGSize(width: self.x, height: self.y)
    }
}


public extension CGSize {
    static var identity: CGSize {
        return CGSize(width: 1, height: 1)
    }

    func plus(_ size: CGSize) -> CGSize {
        var newSize = self
        newSize.width += size.width
        newSize.height += size.height
        return newSize
    }

    func plus(width: CGFloat = 0, height: CGFloat = 0) -> CGSize {
        return self.plus(CGSize(width: width, height: height))
    }

    func minus(_ size: CGSize) -> CGSize {
        return self.plus(size.multiplied(by: -1))
    }

    func minus(width: CGFloat = 0, height: CGFloat = 0) -> CGSize {
        return self.minus(CGSize(width: width, height: height))
    }

    func rounded(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGSize {
        let width = self.width.rounded(rule)
        let height = self.height.rounded(rule)
        return CGSize(width: width, height: height)
    }

    func multiplied(by value: CGFloat) -> CGSize {
        var size = self
        size.width *= value
        size.height *= value
        return size
    }

    func scaleDownToFit(width: CGFloat, height: CGFloat) -> CGSize {
        var newSize = self
        if newSize.width > width {
            newSize.height *= (width / newSize.width)
            newSize.width = width
        }
        if newSize.height > height {
            newSize.width *= (height / newSize.height)
            newSize.height = height
        }
        return newSize
    }

    func toRect(withOrigin origin: CGPoint = .zero) -> CGRect {
        return CGRect(origin: origin, size: self)
    }

    func toPoint() -> CGPoint {
        return CGPoint(x: self.width, y: self.height)
    }
}


public extension CGRect {
    func rounded(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGRect {
        let origin = self.origin.rounded(rule)
        let size = self.size.rounded(rule)
        return CGRect(origin: origin, size: size)
    }

    init(width: CGFloat, height: CGFloat, centredIn rect: CGRect) {
        let x = rect.midX - (width / 2)
        let y = rect.midY - (height / 2)
        self.init(x: x, y: y, width: width, height: height)
    }

    init?(points: [CGPoint]) {
        var containingRect: CGRect? = nil
        for point in points {
            let pointRect = CGRect(origin: point, size: .zero)
            guard let rect = containingRect else {
                containingRect = pointRect
                continue
            }
            containingRect = rect.union(pointRect)
        }

        guard let rect = containingRect else {
            return nil
        }
        self.init(origin: rect.origin, size: rect.size)
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
