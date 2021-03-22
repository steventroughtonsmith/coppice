//
//  EditorBackgroundView.swift
//  Coppice
//
//  Created by Martin Pilkington on 01/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ColourBackgroundView: NSView {
    var backgroundColour: NSColor? {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        self.backgroundColour?.set()
        self.bounds.fill()
    }
}
