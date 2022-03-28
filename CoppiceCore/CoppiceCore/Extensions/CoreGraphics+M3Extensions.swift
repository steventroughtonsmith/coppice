//
//  CoreGraphicsExtensions.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 06/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import CoreGraphics
import Foundation

extension CGPoint {
    public static var identity: CGPoint {
        return CGPoint(x: 1, y: 1)
    }

    public func plus(_ point: CGPoint) -> CGPoint {
        var newPoint = self
        newPoint.x += point.x
        newPoint.y += point.y
        return newPoint
    }

    public func plus(x: CGFloat = 0, y: CGFloat = 0) -> CGPoint {
        return self.plus(CGPoint(x: x, y: y))
    }

    public func minus(_ point: CGPoint) -> CGPoint {
        return self.plus(point.multiplied(by: -1))
    }

    public func minus(x: CGFloat = 0, y: CGFloat = 0) -> CGPoint {
        return self.minus(CGPoint(x: x, y: y))
    }

    public func multiplied(by value: CGFloat) -> CGPoint {
        var newPoint = self
        newPoint.x *= value
        newPoint.y *= value
        return newPoint
    }

    public func rounded(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGPoint {
        let x = self.x.rounded(rule)
        let y = self.y.rounded(rule)
        return CGPoint(x: x, y: y)
    }

    public func bounded(within rect: CGRect) -> CGPoint {
        let x = min(max(self.x, rect.minX), (rect.maxX - 1))
        let y = min(max(self.y, rect.minY), (rect.maxY - 1))
        return CGPoint(x: x, y: y)
    }

    public func toRect(with size: CGSize = .zero) -> CGRect {
        return CGRect(origin: self, size: size)
    }

    public func toSize() -> CGSize {
        return CGSize(width: self.x, height: self.y)
    }

    public func distance(to otherPoint: CGPoint) -> CGFloat {
        let x = self.x - otherPoint.x
        let y = self.y - otherPoint.y

        return sqrt((x * x) + (y * y))
    }

    public func flip(in size: CGSize) -> CGPoint {
        var newPoint = self
        newPoint.y = size.height - self.y
        return newPoint
    }
}


extension CGSize {
    public static var identity: CGSize {
        return CGSize(width: 1, height: 1)
    }

    public func plus(_ size: CGSize) -> CGSize {
        var newSize = self
        newSize.width += size.width
        newSize.height += size.height
        return newSize
    }

    public func plus(width: CGFloat = 0, height: CGFloat = 0) -> CGSize {
        return self.plus(CGSize(width: width, height: height))
    }

    public func minus(_ size: CGSize) -> CGSize {
        return self.plus(size.multiplied(by: -1))
    }

    public func minus(width: CGFloat = 0, height: CGFloat = 0) -> CGSize {
        return self.minus(CGSize(width: width, height: height))
    }

    public func rounded(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGSize {
        let width = self.width.rounded(rule)
        let height = self.height.rounded(rule)
        return CGSize(width: width, height: height)
    }

    public func multiplied(by value: CGFloat) -> CGSize {
        var size = self
        size.width *= value
        size.height *= value
        return size
    }

    public func scaleDownToFit(_ size: CGSize) -> CGSize {
        return self.scaleDownToFit(width: size.width, height: size.height)
    }

    public func scaleDownToFit(width: CGFloat, height: CGFloat) -> CGSize {
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

    public func toRect(withOrigin origin: CGPoint = .zero) -> CGRect {
        return CGRect(origin: origin, size: self)
    }

    public func toPoint() -> CGPoint {
        return CGPoint(x: self.width, y: self.height)
    }

    public func centred(in rect: CGRect) -> CGRect {
        var newRect = CGRect(origin: .zero, size: self)
        newRect.origin.x = rect.midX - (self.width / 2)
        newRect.origin.y = rect.midY - (self.height / 2)
        return newRect
    }
}


extension CGRect {
    public func rounded(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGRect {
        let origin = self.origin.rounded(rule)
        let size = self.size.rounded(rule)
        return CGRect(origin: origin, size: size)
    }

    public init(width: CGFloat, height: CGFloat, centredIn rect: CGRect) {
        let x = rect.midX - (width / 2)
        let y = rect.midY - (height / 2)
        self.init(x: x, y: y, width: width, height: height)
    }

    public init?(points: [CGPoint]) {
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

    public enum RectPoint: Equatable {
        case min
        case mid
        case max
    }

    public func point(atX x: RectPoint, y: RectPoint) -> CGPoint {
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

    public var midPoint: CGPoint {
        return self.point(atX: .mid, y: .mid)
    }

    public func insetBy(_ edgeInsets: NSEdgeInsets, flipped: Bool = true) -> CGRect {
        var rect = self
        rect.origin.x += edgeInsets.left
        rect.origin.y += (flipped ? edgeInsets.top : edgeInsets.bottom)

        rect.size.width -= (edgeInsets.left + edgeInsets.right)
        rect.size.height -= (edgeInsets.top + edgeInsets.bottom)
        return rect
    }

    public func moved(byX x: CGFloat, y: CGFloat) -> CGRect {
        var rect = self
        rect.origin.x += x
        rect.origin.y += y
        return rect
    }

    public func flipped(in rect: CGRect) -> CGRect {
        var flippedRect = self
        flippedRect.origin.y = rect.height - flippedRect.maxY
        return flippedRect
    }

    public func multiplied(by factor: CGFloat) -> CGRect {
        return CGRect(origin: self.origin.multiplied(by: factor), size: self.size.multiplied(by: factor))
    }

    public func rotate(byRadians radians: CGFloat, around rotationOrigin: CGPoint) -> CGRect {
        let translate = CGAffineTransform(translationX: rotationOrigin.x, y: rotationOrigin.y)
        let rotation = translate.rotated(by: radians)
        let postTranslate = rotation.translatedBy(x: -rotationOrigin.y, y: -rotationOrigin.x)

        return self.applying(postTranslate)
    }
}
