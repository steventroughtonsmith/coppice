//
//  CoppiceGreenView.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

class CoppiceGreenView: NSView {
    //MARK: -
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.sharedInit()
    }

    private func sharedInit() {
        self.wantsLayer = true
        self.layer?.masksToBounds = false
    }

    //MARK: - Properties
    enum Shape {
        case rectangle
        case curveTop
        case curveBottom
        case hillsBottom
    }

    var shape: Shape = .rectangle {
        didSet {
            setNeedsDisplay(self.bounds)
        }
    }

    var backgroundInsets: NSEdgeInsets = .zero {
        didSet {
            setNeedsDisplay(self.bounds)
        }
    }

    @IBInspectable var curveAmount: Double = 0.1


    //MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        guard let color = NSColor(named: "CoppiceGreen") else {
            return
        }
        color.set()


        let path = self.backgroundPath
        path.fill()

        let isDarkMode = self.effectiveAppearance.isDarkMode
        NSGradient(colors: [.clear, .black.withAlphaComponent(isDarkMode ? 0.09 : 0.03)])?.draw(in: path, angle: -90)
        NSGradient(colors: [.white.withAlphaComponent(isDarkMode ? 0.03 : 0.09), .clear])?.draw(in: path, angle: -90)
    }

    private var backgroundPath: NSBezierPath {
        let path = NSBezierPath()
        let insetBounds = self.bounds.insetBy(self.backgroundInsets, flipped: false)
        switch self.shape {
        case .curveBottom:
            path.move(to: insetBounds.point(atX: .min, y: .max))
            let curveStartPoint = insetBounds.point(atX: .min, y: .min).plus(y: self.bounds.height * self.curveAmount)
            path.line(to: curveStartPoint)
            let curveInsetPoint = curveStartPoint.plus(x: insetBounds.width * 0.1)
            path.line(to: curveInsetPoint)
            let controlPoint1 = CGPoint(x: insetBounds.width * 0.6, y: curveStartPoint.y)
            let curveEnd = insetBounds.point(atX: .max, y: .min)
            path.curve(to: curveEnd, controlPoint1: controlPoint1, controlPoint2: curveEnd)
            path.line(to: insetBounds.point(atX: .max, y: .max))
            path.close()
        case .curveTop:
            path.move(to: insetBounds.point(atX: .min, y: .min))

            let curveStartPoint = insetBounds.point(atX: .min, y: .max)
            path.line(to: curveStartPoint)

            let curveInsetPoint = curveStartPoint.plus(x: insetBounds.width * 0.1)
            path.line(to: curveInsetPoint)

            let controlPoint1 = CGPoint(x: insetBounds.width * 0.6, y: curveStartPoint.y)

            let curveEnd = insetBounds.point(atX: .max, y: .max).minus(y: self.bounds.height * self.curveAmount)
            path.curve(to: curveEnd, controlPoint1: controlPoint1, controlPoint2: curveEnd)
            path.line(to: insetBounds.point(atX: .max, y: .min))
            path.close()
        case .hillsBottom:
            fallthrough
        case .rectangle:
            path.appendRect(insetBounds)
        }
        return path
    }
}
