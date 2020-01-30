//
//  ColourCell.swift
//  Bubbles
//
//  Created by Martin Pilkington on 18/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

class ColourGridCell: NSView {
    var colour: NSColor = .black {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 40, height: 24)
    }

    var selected: Bool = false {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }


    //MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        self.drawBackground()
        self.drawBorder()
        self.drawSelection()
    }

    private func drawBorder() {
        //Draw Border
        if (NSApp.effectiveAppearance.name == .darkAqua) {
            NSColor.white.withAlphaComponent(0.3).set()
        } else {
            NSColor.black.withAlphaComponent(0.3).set()
        }
        NSBezierPath(rect: self.bounds).stroke()
    }

    private func drawBackground() {
        //Draw Colour
        self.colour.set()
        self.bounds.fill()
    }

    private func drawSelection() {
        guard self.selected else {
            return
        }

        NSBezierPath(rect: self.bounds.insetBy(dx: 0.5, dy: 0.5)).setClip()
        let size: CGFloat = 17
        let origin = self.bounds.point(atX: .max, y: .min).minus(x: size)
        let selectionFrame = CGRect(origin: origin, size: CGSize(width: size, height: size))

        let selectionPath = NSBezierPath()
        selectionPath.move(to: selectionFrame.point(atX: .max, y: .max))
        selectionPath.line(to: selectionFrame.point(atX: .max, y: .min))
        selectionPath.line(to: selectionFrame.point(atX: .min, y: .min))
        selectionPath.line(to: selectionFrame.point(atX: .min, y: .max).minus(y: 2))
        selectionPath.curve(to: selectionFrame.point(atX: .min, y: .max).plus(x: 2),
                            controlPoint1: selectionFrame.point(atX: .min, y: .max).plus(x: 1),
                            controlPoint2: selectionFrame.point(atX: .min, y: .max).minus(y: 1))
        selectionPath.line(to: selectionFrame.point(atX: .max, y: .max))


        NSColor(white: 0, alpha: 0.45).set()
        selectionPath.fill()

        let string: NSString = "✓"
        let attributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 10)
        ]

        var tickRect = string.boundingRect(with: selectionFrame.size, options: [], attributes: attributes)
        tickRect.origin = selectionFrame.midPoint.minus(tickRect.size.multiplied(by: 0.5).toPoint())

        string.draw(in: tickRect, withAttributes: attributes)
    }

}
