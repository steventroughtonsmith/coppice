//
//  ResponderChainValidatingToolbarItem.swift
//  Bubbles
//
//  Created by Martin Pilkington on 04/05/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ResponderChainValidatingToolbarItem: NSToolbarItem {
    override func validate() {
        guard let action = self.action else {
            super.validate()
            return
        }
        self.isEnabled = (NSApp.target(forAction: action) != nil)
    }
}
