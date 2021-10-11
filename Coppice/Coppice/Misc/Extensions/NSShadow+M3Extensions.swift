//
//  NSShadow+M3Extensions.swift
//  NSShadow+M3Extensions
//
//  Created by Martin Pilkington on 08/10/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import AppKit

extension NSShadow {
    convenience init(offset: CGSize, blurRadius: CGFloat, color: NSColor) {
        self.init()
        
        self.shadowOffset = offset
        self.shadowBlurRadius = blurRadius
        self.shadowColor = color
    }
}
