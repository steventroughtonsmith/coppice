//
//  NSAttributedString+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 07/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

extension NSAttributedString {
    var fullRange: NSRange {
        return NSRange(location: 0, length: self.length)
    }
}
