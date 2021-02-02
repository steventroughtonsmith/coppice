//
//  ColouredButtonCell.swift
//  Coppice
//
//  Created by Martin Pilkington on 05/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

@IBDesignable
class ColouredButton: NSButton {
    @IBInspectable @objc var backgroundColor: NSColor? {
        didSet {
            (self.cell as? ColouredButtonCell)?.backgroundColor = self.backgroundColor
            self.setNeedsDisplay(self.bounds)
        }
    }

    override class var cellClass: AnyClass? {
        get {
            return ColouredButtonCell.self
        }
        set {}
    }
}

class ColouredButtonCell: NSButtonCell {
    override func drawBezel(withFrame cellFrame: NSRect, in controlView: NSView) {
        let color = (controlView as? ColouredButton)?.backgroundColor ?? NSColor.linkColor
        if self.isHighlighted {
            color.highlight(withLevel: 0.2)?.set()
        } else {
            color.set()
        }
        NSBezierPath(roundedRect: cellFrame, xRadius: 5, yRadius: 5).fill()
    }
}
