//
//  ModelObjects+AppKit.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

extension Folder {
    static var icon: NSImage? {
        return NSImage.symbol(withName: Symbols.Page.folder)
    }
}
