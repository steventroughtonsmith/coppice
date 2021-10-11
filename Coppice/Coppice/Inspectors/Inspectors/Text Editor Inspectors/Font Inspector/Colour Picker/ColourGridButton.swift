//
//  ColourCell.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

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

    var roundedCorner: ColourGridButtonCell.Corner? {
        get { (self.cell as? ColourGridButtonCell)?.roundedCorner }
        set { (self.cell as? ColourGridButtonCell)?.roundedCorner = newValue }
    }

    let colour: NSColor
    init(colour: NSColor, target: AnyObject?, action: Selector?) {
        self.colour = colour
        super.init(frame: .zero)

        self.target = target
        self.action = action
        (self.cell as? ColourGridButtonCell)?.colour = colour
        self.focusRingType = .default
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 40, height: 24)
    }
}

class ColourGridButtonCell: NSButtonCell {
    var colour: NSColor = .black
    var selected: Bool = false
    var roundedCorner: Corner?

    enum Corner: Equatable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    //Don't override the plain draw method as otherwise we get a weird focus ring
    override func drawBezel(withFrame cellFrame: NSRect, in controlView: NSView) {
        let path = self.roundedPath(in: cellFrame)
        self.colour.set()
        path.fill()

        self.drawBorder(in: cellFrame)
        if self.isHighlighted {
            self.drawHighlight(in: cellFrame)
        }
        if self.selected {
            self.drawSelection(in: cellFrame)
        }
    }

    private func roundedPath(in rect: CGRect) -> NSBezierPath {
        guard let corner = self.roundedCorner else {
            return NSBezierPath(rect: rect)
        }

        return NSBezierPath(roundedRect: rect,
                            topLeftRadius: (corner == .topLeft) ? 8 : nil,
                            topRightRadius: (corner == .topRight) ? 8 : nil,
                            bottomLeftRadius: (corner == .bottomLeft) ? 8 : nil,
                            bottomRightRadius: (corner == .bottomRight) ? 8 : nil)
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        //We don't need an interior
    }

    private func drawBorder(in rect: CGRect) {
        //Draw Border
        if (NSApp.effectiveAppearance.isDarkMode) {
            NSColor.white.withAlphaComponent(0.3).set()
        } else {
            NSColor.black.withAlphaComponent(0.3).set()
        }
        self.roundedPath(in: rect).stroke()
    }

    private func drawHighlight(in rect: CGRect) {
        if (self.colour.brightnessComponent > 0.7) {
            NSColor(white: 0, alpha: 0.4).set()
        } else {
            NSColor(white: 1, alpha: 0.7).set()
        }
        let path = self.roundedPath(in: rect.insetBy(dx: 2, dy: 2))
        path.lineWidth = 2
        path.stroke()
    }

    private func drawSelection(in rect: CGRect) {
        self.roundedPath(in: rect.insetBy(dx: 0.5, dy: 0.5)).setClip()
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
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 10),
        ]

        var tickRect = string.boundingRect(with: selectionFrame.size, options: [], attributes: attributes)
        tickRect.origin = selectionFrame.midPoint.minus(tickRect.size.multiplied(by: 0.5).toPoint())

        string.draw(in: tickRect, withAttributes: attributes)
    }

    override func focusRingMaskBounds(forFrame cellFrame: NSRect, in controlView: NSView) -> NSRect {
        return cellFrame
    }
}
