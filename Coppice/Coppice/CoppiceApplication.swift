//
//  CoppiceApplication.swift
//  Coppice
//
//  Created by Martin Pilkington on 23/11/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

@objc class CoppiceApplication: NSApplication {
    //Get rid of the "Send Coppice Feedback to Apple"
    override var helpMenu: NSMenu? {
        get {
            return NSMenu()
        }
        set {}
    }
}
