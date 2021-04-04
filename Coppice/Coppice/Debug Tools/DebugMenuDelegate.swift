//
//  DebugMenuDelegate.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/11/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Subscriptions

#if DEBUG
class DebugMenuBuilder: NSObject {
    let debugCanvasOriginItem: NSMenuItem = {
        let menuItem = NSMenuItem(title: "Show Canvas Origin", action: nil, keyEquivalent: "")
        menuItem.bind(.value, to: NSUserDefaultsController.shared, withKeyPath: "values.debugShowCanvasOrigin", options: [:])
        return menuItem
    }()

    let showKeyLoopItem = NSMenuItem(title: "Show Key Loop", action: #selector(NSWindow.showKeyLoop(_:)), keyEquivalent: "")

    let showPreviewGenerationItem = NSMenuItem(title: "Show Preview Generation…", action: #selector(DocumentWindowController.showPreviewGenerationWindow(_:)), keyEquivalent: "")


    let logResponderChainItem = NSMenuItem(title: "Log Responder Chain", action: #selector(DocumentWindowController.logResponderChain(_:)), keyEquivalent: "")

    let checkSubscriptionMenuItem = NSMenuItem(title: "Check Subscription", action: #selector(AppDelegate.checkSubscription(_:)), keyEquivalent: "")

    let subscriptionDebugMenuItem: NSMenuItem = {
        let menuItem = NSMenuItem(title: "Subscriptions", action: nil, keyEquivalent: "")
        menuItem.submenu = APIDebugManager.shared.buildMenu()
        return menuItem
    }()

    func buildMenu() -> NSMenu {
        let menu = NSMenu(title: "**DEBUG**")
        menu.addItem(self.debugCanvasOriginItem)
        menu.addItem(self.showKeyLoopItem)
        menu.addItem(self.showPreviewGenerationItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.logResponderChainItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.checkSubscriptionMenuItem)
        menu.addItem(self.subscriptionDebugMenuItem)

        return menu
    }
}
#endif
