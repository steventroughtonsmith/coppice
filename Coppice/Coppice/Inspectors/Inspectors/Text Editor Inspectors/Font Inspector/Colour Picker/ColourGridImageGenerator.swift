//
//  ColourGridImageGenerator.swift
//  Coppice
//
//  Created by Martin Pilkington on 31/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

class ColourGridImageGenerator {
    private let cache = NSCache<NSColor, NSImage>()
    func image(for colour: NSColor, size: CGSize, selected: Bool) -> NSImage {
        if let cachedImage = self.cache.object(forKey: colour) {
            return cachedImage
        }
        let image = NSImage(size: size, flipped: false) { (rect) -> Bool in
            colour.set()
            rect.fill()
            self.drawBorder(in: rect)
            if selected {
                self.drawSelection(in: rect)
            }
            return true
        }

        self.cache.setObject(image, forKey: colour)

        return image
    }

    private func drawBorder(in rect: CGRect) {
        //Draw Border
        if (NSApp.effectiveAppearance.isDarkMode) {
            NSColor.white.withAlphaComponent(0.3).set()
        } else {
            NSColor.black.withAlphaComponent(0.3).set()
        }
        NSBezierPath(rect: rect).stroke()
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
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 10),
        ]

        var tickRect = string.boundingRect(with: selectionFrame.size, options: [], attributes: attributes)
        tickRect.origin = selectionFrame.midPoint.minus(tickRect.size.multiplied(by: 0.5).toPoint())

        string.draw(in: tickRect, withAttributes: attributes)
    }
}
