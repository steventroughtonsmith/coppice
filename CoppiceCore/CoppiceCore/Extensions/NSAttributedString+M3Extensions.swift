//
//  NSAttributedString+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 07/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

extension String {
    public var fullRange: Range<String.Index> {
        return self.startIndex..<self.endIndex
    }
}

extension NSString {
    public var fullRange: NSRange {
        return NSRange(location: 0, length: self.length)
    }
}

extension NSAttributedString {
    public var fullRange: NSRange {
        return NSRange(location: 0, length: self.length)
    }
}
