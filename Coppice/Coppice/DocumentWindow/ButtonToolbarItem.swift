//
//  ButtonToolbarItem.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ButtonToolbarItem: NSToolbarItem {
    init(itemIdentifier: NSToolbarItem.Identifier, image: NSImage, action: Selector) {
        super.init(itemIdentifier: itemIdentifier)

        let button = NSButton(image: image, target: nil, action: action)
        button.bezelStyle = .texturedRounded
        self.view = button
    }

    override func validate() {
        guard
            let button = self.view as? NSButton,
            let action = button.action
        else {
            super.validate()
            return
        }


        guard let target = NSApplication.shared.target(forAction: action) as? NSObject else {
            button.isEnabled = false
            return
        }

        guard let validator = target as? NSToolbarItemValidation else {
            button.isEnabled = true
            return
        }

        button.isEnabled = validator.validateToolbarItem(self)
    }
}
