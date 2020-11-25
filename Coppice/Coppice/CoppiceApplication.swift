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

    override func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) -> Bool {
        #if TEST
        if (UserDefaults.standard.bool(forKey: "CoppiceDisableStateRestoration")) {
            return false
        }
        #endif
        return super.restoreWindow(withIdentifier: identifier, state: state, completionHandler: completionHandler)
    }
}
