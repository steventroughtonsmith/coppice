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
    @IBInspectable var fillColour: NSColor = .clear

    override class var cellClass: AnyClass? {
        get {
            return RoundButtonCell.self
        }
        set {}
    }
}

class RoundButtonCell: NSButtonCell {
    override func drawBezel(withFrame cellFrame: NSRect, in controlView: NSView) {
        guard let roundButton = controlView as? RoundButton else {
            return
        }

        let horizontalInset: CGFloat = (self.imagePosition == .noImage) ? 6 : 6
        let pathFrame = cellFrame.insetBy(NSEdgeInsets(top: 2, left: horizontalInset, bottom: 4, right: horizontalInset))

        let fillPath = NSBezierPath(roundedRect: pathFrame, xRadius: pathFrame.height / 2, yRadius: pathFrame.height / 2)
        if roundButton.fillColour != .clear {
            roundButton.fillColour.setFill()
            fillPath.fill()
        }

        if self.isHighlighted {
            if controlView.effectiveAppearance.isDarkMode {
                NSColor.white.withAlphaComponent(0.3).setFill()
            } else {
                NSColor.black.withAlphaComponent(0.15).setFill()
            }
            fillPath.fill()
        }

        let colour = roundButton.borderColour
        colour.setStroke()
        let path = NSBezierPath(roundedRect: pathFrame.insetBy(dx: 0.5, dy: 0.5), xRadius: pathFrame.height / 2, yRadius: pathFrame.height / 2)
        path.lineWidth = 1
        path.stroke()
    }
}
