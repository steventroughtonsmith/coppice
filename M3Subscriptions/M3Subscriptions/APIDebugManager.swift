//
//  APIDebugManager.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 15/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
#if DEBUG
public class APIDebugManager: NSObject {
    public static var shared = APIDebugManager()

    public func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let activateMenuItem = NSMenuItem(title: "Activation Errors", action: nil, keyEquivalent: "")
        activateMenuItem.submenu = self.buildActivateMenu()
        menu.addItem(activateMenuItem)

        let deactivateMenuItem = NSMenuItem(title: "Deactivation Errors", action: nil, keyEquivalent: "")
        deactivateMenuItem.submenu = self.buildDeactivateMenu()
        menu.addItem(deactivateMenuItem)

        let checkMenuItem = NSMenuItem(title: "Check Errors", action: nil, keyEquivalent: "")
        checkMenuItem.submenu = self.buildCheckMenu()
        menu.addItem(checkMenuItem)
        return menu
    }

    //MARK: - Activate
    var activateDebugString: String? {
        return nil
    }

    private func buildActivateMenu() -> NSMenu {
        let menu = NSMenu()
        return menu
    }

    @IBAction func activateMenuItemSelected(_ sender: NSMenuItem?) {

    }


    //MARK: - Deactivate
    var deactivateDebugString: String? {
        return nil
    }

    private func buildDeactivateMenu() -> NSMenu {
        let menu = NSMenu()
        return menu
    }

    @IBAction func deactivateMenuItemSelected(_ sender: NSMenuItem?) {

    }


    //MARK: - Check
    var checkDebugString: String? {
        return nil
    }

    private func buildCheckMenu() -> NSMenu {
        let menu = NSMenu()
        return menu
    }

    @IBAction func checkMenuItemSelected(_ sender: NSMenuItem?) {

    }
}
#endif
