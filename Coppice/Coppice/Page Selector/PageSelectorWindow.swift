//
//  PageSelectorWindow.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class PageSelectorWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect,
                   styleMask: [ .closable, .borderless ],
                   backing: backingStoreType,
                   defer: flag)
        self.isMovableByWindowBackground = true
        self.isOpaque = false
        self.backgroundColor = .clear
    }
}
