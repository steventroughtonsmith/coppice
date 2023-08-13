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

    var titleInsets: NSEdgeInsets = .zero
    var imageInsets: NSEdgeInsets = .zero

    override class var cellClass: AnyClass? {
        get {
            return RoundButtonCell.self
        }
        set {}
    }

    override var alignmentRectInsets: NSEdgeInsets {
        return NSEdgeInsets(top: 2, left: 6, bottom: 4, right: 6)
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

    override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
        var adjustedFrame = frame
        if let roundButton = controlView as? RoundButton {
            adjustedFrame = frame.insetBy(roundButton.titleInsets)
        }
        return super.drawTitle(title, withFrame: adjustedFrame, in: controlView)
    }

    override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
        var adjustedFrame = frame
        if let roundButton = controlView as? RoundButton {
            adjustedFrame = frame.insetBy(roundButton.imageInsets)
        }
        super.drawImage(image, withFrame: adjustedFrame, in: controlView)
    }
}
