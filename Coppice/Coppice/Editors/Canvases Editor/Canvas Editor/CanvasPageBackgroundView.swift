//
//  CanvasPageBackgroundView.swift
//  Coppice
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

    var selected: Bool = false {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    var active: Bool = false {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    override var acceptsFirstResponder: Bool {
        return true
    }


    //MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.drawOuterStroke()
        self.drawBackground()
        self.drawInnerStroke()
        if self.selected {
            self.drawSelectionHighlight()
        }
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

    private func drawSelectionHighlight() {
        let color = (self.active ? NSColor.controlAccentColor : NSColor(white: 0.5, alpha: 1))
        color.set()
        let path = NSBezierPath(roundedRect: self.bounds.insetBy(dx: 1, dy: 1), xRadius: 5, yRadius: 5)
        path.lineWidth = 2
        path.stroke()
    }
}
