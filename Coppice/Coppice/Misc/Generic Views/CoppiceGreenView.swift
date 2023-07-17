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

    var shape: Shape = .rectangle


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
        let bounds = self.bounds
        switch self.shape {
        case .curveBottom:
            path.move(to: bounds.point(atX: .min, y: .max))
            let curveStartPoint = bounds.point(atX: .min, y: .min).plus(y: bounds.height * 0.1)
            path.line(to: curveStartPoint)
            let curveInsetPoint = curveStartPoint.plus(x: bounds.width * 0.1)
            path.line(to: curveInsetPoint)
            let controlPoint1 = CGPoint(x: bounds.width * 0.6, y: curveStartPoint.y)
            let curveEnd = bounds.point(atX: .max, y: .min)
            path.curve(to: curveEnd, controlPoint1: controlPoint1, controlPoint2: curveEnd)
            path.line(to: bounds.point(atX: .max, y: .max))
            path.close()
        case .curveTop:
            fallthrough
        case .hillsBottom:
            fallthrough
        case .rectangle:
            path.appendRect(bounds)
        }
        return path
    }
}
