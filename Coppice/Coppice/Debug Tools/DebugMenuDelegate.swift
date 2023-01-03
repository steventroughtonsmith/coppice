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

    let debugCanvasArrows: NSMenuItem = {
        let menuItem = NSMenuItem(title: "Show Arrow Bounds", action: nil, keyEquivalent: "")
        menuItem.bind(.value, to: NSUserDefaultsController.shared, withKeyPath: "values.debugShowArrowBounds", options: [:])
        return menuItem
    }()

    let showKeyLoopItem = NSMenuItem(title: "Show Key Loop", action: #selector(NSWindow.showKeyLoop(_:)), keyEquivalent: "")

    let showPreviewGenerationItem = NSMenuItem(title: "Show Preview Generation…", action: #selector(DocumentWindowController.showPreviewGenerationWindow(_:)), keyEquivalent: "")


    let logResponderChainItem = NSMenuItem(title: "Log Responder Chain", action: #selector(DocumentWindowController.logResponderChain(_:)), keyEquivalent: "")

    let proDisabledMenuItem = NSMenuItem(title: "Pro Disabled", action: #selector(AppDelegate.toggleProDisabled(_:)), keyEquivalent: "")
    let checkSubscriptionMenuItem = NSMenuItem(title: "Check Subscription", action: #selector(AppDelegate.checkSubscription(_:)), keyEquivalent: "")

    let subscriptionDebugMenuItem: NSMenuItem = {
        let menuItem = NSMenuItem(title: "Subscriptions", action: nil, keyEquivalent: "")
        menuItem.submenu = APIDebugManager.shared.buildResponsesMenu()
        return menuItem
    }()

    let activeAPIConfigMenuItem: NSMenuItem = {
        let menuItem = NSMenuItem(title: "Active Config", action: nil, keyEquivalent: "")
        menuItem.submenu = APIDebugManager.shared.buildConfigMenu()
        return menuItem
    }()

    let windowSizeMenuItem: NSMenuItem = {
        let menuItem = NSMenuItem(title: "Resize Window", action: nil, keyEquivalent: "")

        let submenu = NSMenu()
        submenu.addItem(withTitle: "Big Screenshot",
                        action: #selector(DocumentWindowController.applyWindowSize(_:)),
                        keyEquivalent: "").representedObject = CGSize(width: 1312, height: 736)
        submenu.addItem(withTitle: "Compact Screenshot",
                        action: #selector(DocumentWindowController.applyWindowSize(_:)),
                        keyEquivalent: "").representedObject = CGSize(width: 1070, height: 600)
		submenu.addItem(withTitle: "Smallest MBA Screen",
		                action: #selector(DocumentWindowController.applyWindowSize(_:)),
		                keyEquivalent: "").representedObject = CGSize(width: 1024, height: 616)
		submenu.addItem(withTitle: "14\" MBP",
		                action: #selector(DocumentWindowController.applyWindowSize(_:)),
		                keyEquivalent: "").representedObject = CGSize(width: 1512, height: 958)
        menuItem.submenu = submenu

        return menuItem
    }()

    let createDebugDocumentItem: NSMenuItem = {
        let menuItem = NSMenuItem(title: "Create Debug Document", action: #selector(DebugDocumentBuilder.createNewDebugDocument(_:)), keyEquivalent: "")
        menuItem.target = DebugDocumentBuilder.shared
        return menuItem
    }()

    func buildMenu() -> NSMenu {
        let menu = NSMenu(title: "**DEBUG**")
        menu.addItem(self.debugCanvasOriginItem)
        menu.addItem(self.debugCanvasArrows)
        menu.addItem(self.showKeyLoopItem)
        menu.addItem(self.showPreviewGenerationItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.logResponderChainItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.proDisabledMenuItem)
        menu.addItem(self.activeAPIConfigMenuItem)
        menu.addItem(self.checkSubscriptionMenuItem)
        menu.addItem(self.subscriptionDebugMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.windowSizeMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(self.createDebugDocumentItem)
        return menu
    }
}
#endif
