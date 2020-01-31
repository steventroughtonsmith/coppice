//
//  ColourCell.swift
//  Bubbles
//
//  Created by Martin Pilkington on 18/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

class ColourGridButton: NSButton {
    override class var cellClass: AnyClass? {
        get {
            return ColourGridButtonCell.self
        }
        set {}
    }

    var selected: Bool {
        get { (self.cell as? ColourGridButtonCell)?.selected ?? false }
        set {
            (self.cell as? ColourGridButtonCell)?.selected = newValue
            self.setNeedsDisplay(self.bounds)
        }
    }

    let colour: NSColor
    init(colour: NSColor, target: AnyObject?, action: Selector?) {
        self.colour = colour
        super.init(frame: .zero)

        self.target = target
        self.action = action
        (self.cell as? ColourGridButtonCell)?.colour = colour
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 40, height: 24)
    }
}

class ColourGridButtonCell: NSButtonCell {
    var colour: NSColor = .black
    var selected: Bool = false
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        colour.set()
        cellFrame.fill()

        self.drawBorder(in: cellFrame)
        if self.isHighlighted {
            self.drawHighlight(in: cellFrame)
        }
        if self.selected {
            self.drawSelection(in: cellFrame)
        }
    }

    private func drawBorder(in rect: CGRect) {
        //Draw Border
        if (NSApp.effectiveAppearance.name == .darkAqua) {
            NSColor.white.withAlphaComponent(0.3).set()
        } else {
            NSColor.black.withAlphaComponent(0.3).set()
        }
        NSBezierPath(rect: rect).stroke()
    }

    private func drawHighlight(in rect: CGRect) {
        if (self.colour.brightnessComponent > 0.7) {
            NSColor(white: 0, alpha: 0.4).set()
        } else {
            NSColor(white: 1, alpha: 0.7).set()
        }
        let path = NSBezierPath(rect: rect.insetBy(dx: 2, dy: 2))
        path.lineWidth = 2
        path.stroke()
    }

    private func drawSelection(in rect: CGRect) {
        NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5)).setClip()
        let size: CGFloat = 17
        let origin = rect.point(atX: .max, y: .min).minus(x: size)
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
