//
//  Alert+AppKit.swift
//  Bubbles
//
//  Created by Martin Pilkington on 07/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

extension Alert {
    var nsAlert: NSAlert {
        let alert = NSAlert()
        alert.messageText = self.title
        alert.informativeText = self.message

        self.buttons.forEach { (_, title) in
            let tag = alert.buttons.count
            let button = alert.addButton(withTitle: title)
            button.tag = tag
        }

        return alert
    }
}
