//
//  NSBezierPath+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 01/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

extension NSBezierPath {
    convenience init(roundedRect rect: CGRect, topLeftRadius: CGFloat? = nil, topRightRadius: CGFloat? = nil, bottomLeftRadius: CGFloat? = nil, bottomRightRadius: CGFloat? = nil) {
        self.init()

        let radiusFactor: CGFloat = 0.66

        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)

        if let radius = topLeftRadius {
            var start = topLeft
            start.x += radius
            move(to: start)
        } else {
            move(to: topLeft)
        }

        if let radius = topRightRadius {
            var start = topRight
            start.x -= radius

            var end = topRight
            end.y += radius

            var startControl = start
            startControl.x += radius * radiusFactor

            var endControl = end
            endControl.y -= radius * radiusFactor
            line(to: start)
            curve(to: end, controlPoint1: startControl, controlPoint2: endControl)
        } else {
            line(to: topRight)
        }

        if let radius = bottomRightRadius {
            var start = bottomRight
            start.y -= radius

            var end = bottomRight
            end.x -= radius

            var startControl = start
            startControl.y += radius * radiusFactor

            var endControl = end
            endControl.x += radius * radiusFactor
            line(to: start)
            curve(to: end, controlPoint1: startControl, controlPoint2: endControl)
        } else {
            line(to: bottomRight)
        }

        if let radius = bottomLeftRadius {
            var start = bottomLeft
            start.x += radius

            var end = bottomLeft
            end.y -= radius

            var startControl = start
            startControl.x -= radius * radiusFactor

            var endControl = end
            endControl.y += radius * radiusFactor
            line(to: start)
            curve(to: end, controlPoint1: startControl, controlPoint2: endControl)
        } else {
            line(to: bottomLeft)
        }

        if let radius = topLeftRadius {
            var start = topLeft
            start.y += radius

            var end = topLeft
            end.x += radius

            var startControl = start
            startControl.y -= radius * radiusFactor

            var endControl = end
            endControl.x -= radius * radiusFactor
            line(to: start)
            curve(to: end, controlPoint1: startControl, controlPoint2: endControl)

        } else {
            line(to: topLeft)
        }
        close()
    }

    convenience init(lineFrom point1: CGPoint, to point2: CGPoint) {
        self.init()

        move(to: point1)
        line(to: point2)
    }


    convenience init(cgPath: CGPath) {
        self.init()
        cgPath.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            let points = element.points
            switch element.type {
            case .moveToPoint:
                self.move(to: points[0])
            case .addLineToPoint:
                self.line(to: points[0])
            case .addQuadCurveToPoint:
                preconditionFailure("In your hubris you said 'I'll never need this'")
            case .addCurveToPoint:
                self.curve(to: points[2], controlPoint1: points[0], controlPoint2: points[1])
            case .closeSubpath:
                self.close()
            @unknown default:
                break
            }
        }
    }

    var cgPath: CGPath {
        let mutablePath = CGMutablePath()
        for elementIndex in 0..<self.elementCount {
            let pointArray = NSPointArray.allocate(capacity: 3)
            let element = self.element(at: elementIndex, associatedPoints: pointArray)
            switch element {
            case .moveTo:
                mutablePath.move(to: pointArray[0])
            case .lineTo:
                mutablePath.addLine(to: pointArray[0])
            case .curveTo, .cubicCurveTo:
                mutablePath.addCurve(to: pointArray[2], control1: pointArray[0], control2: pointArray[1])
            case .closePath:
                mutablePath.closeSubpath()
            case .quadraticCurveTo:
                mutablePath.addQuadCurve(to: pointArray[1], control: pointArray[0])
            @unknown default:
                preconditionFailure()
            }
        }
        return mutablePath
    }

    func bezierPath(strokedWithWidth lineWidth: CGFloat) -> NSBezierPath {
        let cgPath = self.cgPath
        let strokedPath = cgPath.copy(strokingWithWidth: lineWidth, lineCap: .butt, lineJoin: .round, miterLimit: 1)
        return NSBezierPath(cgPath: strokedPath)
    }

    func intersects(with otherPath: NSBezierPath) -> Bool {
        if self.bounds.intersects(otherPath.bounds) == false {
            return false
        }

        let colourSpace = CGColorSpaceCreateDeviceGray()
        let width = Int(self.bounds.maxX)
        let height = Int(self.bounds.maxY)
        guard
            let graphicsContext = Self.createGreyscaleContext(of: CGSize(width: width, height: height)),
            let testContext = Self.testContext
        else {
            return false
        }
        graphicsContext.setFillColorSpace(colourSpace)
        graphicsContext.setStrokeColorSpace(colourSpace)

        graphicsContext.saveGState()
        graphicsContext.clear(CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        graphicsContext.addPath(self.cgPath)
        graphicsContext.clip()
        graphicsContext.setFillColor(.white)
        graphicsContext.addPath(otherPath.cgPath)
        graphicsContext.fillPath()
        graphicsContext.restoreGState()

        guard let image = graphicsContext.makeImage() else {
            return false
        }
        testContext.clear(CGRect(origin: .zero, size: Self.testSize))
        testContext.draw(image, in: CGRect(origin: .zero, size: Self.testSize))

        guard let data = testContext.data else {
            return false
        }
        for offset in 0..<Int(Self.testSize.width * Self.testSize.height) {
            let value = data.load(fromByteOffset: offset, as: UInt8.self)
            if value != 0 {
                return true
            }
        }
        return false
    }

    private static var testSize = CGSize(width: 2, height: 2)
    private static var testContext: CGContext? = {
        return NSBezierPath.createGreyscaleContext(of: NSBezierPath.testSize)
    }()

    private static func createGreyscaleContext(of size: CGSize) -> CGContext? {
        let colourSpace = CGColorSpaceCreateDeviceGray()
        let graphicsContext = CGContext(data: nil,
                                        width: Int(size.width),
                                        height: Int(size.height),
                                        bitsPerComponent: 16,
                                        bytesPerRow: 2 * Int(size.width),
                                        space: colourSpace,
                                        bitmapInfo: 0)
        graphicsContext?.setFillColorSpace(colourSpace)
        graphicsContext?.setStrokeColorSpace(colourSpace)
        return graphicsContext
    }
}
