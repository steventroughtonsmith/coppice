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
}
