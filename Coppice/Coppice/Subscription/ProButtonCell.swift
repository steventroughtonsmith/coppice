//
//  ProButtonCell.swift
//  Coppice
//
//  Created by Martin Pilkington on 04/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ProButtonCell: NSButtonCell {
    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {
        let drawFrame = frame.insetBy(controlView.alignmentRectInsets)
        let bezierPath = NSBezierPath(roundedRect: drawFrame, xRadius: 4, yRadius: 4)
        let coppiceGreen = NSColor(named: "CoppiceGreen")
        if (self.isHighlighted) {
            coppiceGreen?.highlight(withLevel: 0.2)?.setFill()
        } else {
            coppiceGreen?.setFill()
        }
        bezierPath.fill()
    }
}
