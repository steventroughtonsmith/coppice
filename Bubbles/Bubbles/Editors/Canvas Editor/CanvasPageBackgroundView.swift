//
//  CanvasPageBackgroundView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasPageBackgroundView: NSView {
    override var isFlipped: Bool {
        return true
    }

    //MARK: - Initialisation
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }


    //MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        self.drawOuterStroke()
        self.drawBackground()
        self.drawInnerStroke()
    }

    private func drawOuterStroke() {
        NSColor(named: "PageViewStroke")?.set()
        let path = NSBezierPath(roundedRect: self.bounds, xRadius: 5, yRadius: 5)
        path.fill()
    }

    private func drawBackground() {
        NSColor(named: "PageViewBackground")?.set()
        let path = NSBezierPath(roundedRect: self.bounds.insetBy(dx: 1, dy: 1), xRadius: 5, yRadius: 5)
        path.fill()
    }

    private func drawInnerStroke() {
        NSColor(named: "PageViewInnerStroke")?.set()
        let path = NSBezierPath(roundedRect: self.bounds.insetBy(dx: 1.5, dy: 1.5), xRadius: 4.5, yRadius: 4.5)
        path.stroke()
    }
    
}
