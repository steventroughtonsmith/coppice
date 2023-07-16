//
//  RoundButton.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import AppKit

class RoundButton: NSButton {
    @IBInspectable var borderColour: NSColor = .white.withAlphaComponent(0.5)

    override class var cellClass: AnyClass? {
        get {
            return RoundButtonCell.self
        }
        set {}
    }
}

class RoundButtonCell: NSButtonCell {
    override func drawBezel(withFrame cellFrame: NSRect, in controlView: NSView) {
        let pathFrame = cellFrame.insetBy(NSEdgeInsets(top: 2, left: 8, bottom: 4, right: 8))

        if self.isHighlighted {
            NSColor.highlightColor.withAlphaComponent(0.3).setFill()
            NSBezierPath(roundedRect: pathFrame, xRadius: pathFrame.height / 2, yRadius: pathFrame.height / 2).fill()
        }

        let colour = (controlView as? RoundButton)?.borderColour ?? NSColor.controlColor
        colour.setStroke()
        let path = NSBezierPath(roundedRect: pathFrame.insetBy(dx: 0.5, dy: 0.5), xRadius: pathFrame.height / 2, yRadius: pathFrame.height / 2)
        path.lineWidth = 1
        path.stroke()
    }
}
