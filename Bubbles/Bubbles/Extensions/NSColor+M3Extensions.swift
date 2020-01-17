//
//  NSColor+M3Extensions.swift
//  Bubbles
//
//  Created by Martin Pilkington on 23/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

extension NSColor {
    var identifier: String? {
        guard let rgbSelf = self.usingColorSpace(.sRGB) else {
            return nil
        }
        let red = Int(round(rgbSelf.redComponent * 255))
        let green = Int(round(rgbSelf.greenComponent * 255))
        let blue = Int(round(rgbSelf.blueComponent * 255))
        let alpha = Int(round(rgbSelf.alphaComponent * 255))
        return "\(red)/\(green)/\(blue)/\(alpha)"
    }

    var dragImage: NSImage {
        return NSImage(size: NSSize(width: 10, height: 10), flipped: false) { rect in
            let clip = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
            clip.setClip()

            NSColor.white.set()
            rect.fill()

            let blackTriangle = NSBezierPath()
            blackTriangle.move(to: CGPoint(x: rect.minX, y: rect.minY))
            blackTriangle.line(to: CGPoint(x: rect.minX, y: rect.maxY))
            blackTriangle.line(to: CGPoint(x: rect.maxX, y: rect.maxY))
            blackTriangle.close()

            NSColor.black.set()
            blackTriangle.fill()

            self.set()
            rect.fill()

            return true
        }
    }
}
