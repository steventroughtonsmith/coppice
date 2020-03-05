//
//  RectDrawingView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 05/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class RectDrawingView: NSView {
    override var isFlipped: Bool {
        return true
    }
    var rects: [(CGRect, NSColor)] = [] {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        for (rect, colour) in self.rects {
            colour.setFill()
            rect.fill()
        }
    }
}
