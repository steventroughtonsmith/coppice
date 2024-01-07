//
//  Canvas.Thumbnail+AppKit.swift
//  Coppice
//
//  Created by Martin Pilkington on 07/01/2024.
//  Copyright © 2024 M Cubed Software. All rights reserved.
//

import AppKit

import CoppiceCore

extension Thumbnail {
    var image: NSImage? {
        return NSImage(data: self.data)
    }
}
