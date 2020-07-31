//
//  NSColor+M3Extensions.swift
//  Coppice
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

    convenience init?(hexString: String) {
        var string = hexString
        if (string.hasPrefix("#")) {
            string = (string as NSString).substring(from: 1)
        }
        if string.count == 3 {
            let rString = string.substring(at: 0) + string.substring(at: 0)
            let gString = string.substring(at: 1) + string.substring(at: 1)
            let bString = string.substring(at: 2) + string.substring(at: 2)

            let r = CGFloat(strtol(rString, nil, 16))
            let g = CGFloat(strtol(gString, nil, 16))
            let b = CGFloat(strtol(bString, nil, 16))

            self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
            return
        }
        if string.count == 6 {
            let rString = string.substring(at: 0, length: 2)
            let gString = string.substring(at: 2, length: 2)
            let bString = string.substring(at: 4, length: 2)

            let r = CGFloat(strtol(rString, nil, 16))
            let g = CGFloat(strtol(gString, nil, 16))
            let b = CGFloat(strtol(bString, nil, 16))

            self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
            return
        }
        return nil
    }
}


extension String {
    func substring(at index: Int, length: Int = 1) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: index)
        let endIndex = self.index(startIndex, offsetBy: length)
        return String(self[startIndex..<endIndex])
    }
}
