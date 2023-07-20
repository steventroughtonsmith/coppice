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

    public func buildResponsesMenu() -> NSMenu {
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

    private func updateState<T: Equatable>(of menu: NSMenu?, value: T?) {
        guard let menu = menu else {
            return
        }

        for item in menu.items {
            let representedString = item.representedObject as? T
            item.state = (representedString == value) ? .on : .off
        }
    }

    //MARK: - Active Config
    var activeConfig: Config {
        get {
            guard
                let rawConfig = UserDefaults.standard.string(forKey: "M3APIActiveConfig"),
                let config = Config(rawValue: rawConfig)
            else {
                return .production
            }
            return config
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "M3APIActiveConfig")
        }
    }

    public func buildConfigMenu() -> NSMenu {
        let menu = NSMenu()
        for config in Config.allCases {
            let menuItem = NSMenuItem(title: config.displayName, action: #selector(self.updateActiveConfig(_:)), keyEquivalent: "")
            menuItem.representedObject = config
            menuItem.target = self
            menu.addItem(menuItem)
        }
        self.updateState(of: menu, value: self.activeConfig)
        return menu
    }

    @IBAction func updateActiveConfig(_ sender: NSMenuItem) {
        guard let config = sender.representedObject as? Config else {
            return
        }
        self.activeConfig = config
        self.updateState(of: sender.menu, value: config)
    }

    //MARK: - Activate
    var activateDebugString: String?

    private func buildActivateMenu() -> NSMenu {
        let menu = NSMenu()
        let none = menu.addItem(withTitle: "None", action: #selector(self.activateMenuItemSelected(_:)), keyEquivalent: "")
        none.target = self
        menu.addItem(NSMenuItem.separator())

        let noSubscription = menu.addItem(withTitle: "No Subscription Found", action: #selector(self.activateMenuItemSelected(_:)), keyEquivalent: "")
        noSubscription.representedObject = "no_subscription_found"
        noSubscription.target = self

        let multipleSubscriptions2 = menu.addItem(withTitle: "2 Subscriptions Found", action: #selector(self.activateMenuItemSelected(_:)), keyEquivalent: "")
        multipleSubscriptions2.representedObject = "multiple_subscriptions::number:2"
        multipleSubscriptions2.target = self
        let multipleSubscriptions5 = menu.addItem(withTitle: "5 Subscription Found", action: #selector(self.activateMenuItemSelected(_:)), keyEquivalent: "")
        multipleSubscriptions5.representedObject = "multiple_subscriptions::number:5"
        multipleSubscriptions5.target = self

        let subscriptionExpiredCancelled = menu.addItem(withTitle: "Subscription Expired (Cancelled)", action: #selector(self.activateMenuItemSelected(_:)), keyEquivalent: "")
        subscriptionExpiredCancelled.representedObject = "subscription_expired::renewalStatus:cancelled"
        subscriptionExpiredCancelled.target = self
        let subscriptionExpiredFailed = menu.addItem(withTitle: "Subscription Expired (Billing Failed)", action: #selector(self.activateMenuItemSelected(_:)), keyEquivalent: "")
        subscriptionExpiredFailed.representedObject = "subscription_expired::renewalStatus:failed"
        subscriptionExpiredFailed.target = self

        let tooManyDevices = menu.addItem(withTitle: "Too Many Devices", action: #selector(self.activateMenuItemSelected(_:)), keyEquivalent: "")
        tooManyDevices.representedObject = "too_many_devices::number:3"
        tooManyDevices.target = self

        self.updateState(of: menu, value: self.activateDebugString)

        return menu
    }

    @IBAction func activateMenuItemSelected(_ sender: NSMenuItem?) {
        self.activateDebugString = sender?.representedObject as? String
        self.updateState(of: sender?.menu, value: self.activateDebugString)
    }


    //MARK: - Deactivate
    var deactivateDebugString: String?

    private func buildDeactivateMenu() -> NSMenu {
        let menu = NSMenu()
        let none = menu.addItem(withTitle: "None", action: #selector(self.deactivateMenuItemSelected(_:)), keyEquivalent: "")
        none.target = self
        menu.addItem(NSMenuItem.separator())

        let noDevice = menu.addItem(withTitle: "No Device Found", action: #selector(self.deactivateMenuItemSelected(_:)), keyEquivalent: "")
        noDevice.representedObject = "no_device_found"
        noDevice.target = self

        self.updateState(of: menu, value: self.activateDebugString)

        return menu
    }

    @IBAction func deactivateMenuItemSelected(_ sender: NSMenuItem?) {
        self.deactivateDebugString = sender?.representedObject as? String
        self.updateState(of: sender?.menu, value: self.deactivateDebugString)
    }


    //MARK: - Check
    var checkDebugString: String?

    private func buildCheckMenu() -> NSMenu {
        let menu = NSMenu()
        let none = menu.addItem(withTitle: "None", action: #selector(self.checkMenuItemSelected(_:)), keyEquivalent: "")
        none.target = self
        menu.addItem(NSMenuItem.separator())

        var timestamp = Int(Date.timeIntervalBetween1970AndReferenceDate + Date.timeIntervalSinceReferenceDate)
        timestamp += (24 * 60 * 60)

        let activeInPast = menu.addItem(withTitle: "Active (Soon)", action: #selector(self.checkMenuItemSelected(_:)), keyEquivalent: "")
        activeInPast.representedObject = "active::renewalStatus:renew::expirationTimestamp:\(timestamp)"
        activeInPast.target = self

        timestamp += (59 * 24 * 60 * 60)
        let activeInFuture = menu.addItem(withTitle: "Active (Far Future)", action: #selector(self.checkMenuItemSelected(_:)), keyEquivalent: "")
        activeInFuture.representedObject = "active::renewalStatus:renew::expirationTimestamp:\(timestamp)"
        activeInFuture.target = self

        let activeBillingFailed = menu.addItem(withTitle: "Active (Billing Failed)", action: #selector(self.checkMenuItemSelected(_:)), keyEquivalent: "")
        activeBillingFailed.representedObject = "active::renewalStatus:failed::expirationTimestamp:\(timestamp)"
        activeBillingFailed.target = self


        let noDevice = menu.addItem(withTitle: "No Device Found", action: #selector(self.checkMenuItemSelected(_:)), keyEquivalent: "")
        noDevice.representedObject = "no_device_found"
        noDevice.target = self

        let noSubscription = menu.addItem(withTitle: "No Subscription Found", action: #selector(self.checkMenuItemSelected(_:)), keyEquivalent: "")
        noSubscription.representedObject = "no_subscription_found"
        noSubscription.target = self

        let subscriptionExpiredCancelled = menu.addItem(withTitle: "Subscription Expired (Cancelled)", action: #selector(self.checkMenuItemSelected(_:)), keyEquivalent: "")
        subscriptionExpiredCancelled.representedObject = "subscription_expired::renewalStatus:cancelled"
        subscriptionExpiredCancelled.target = self
        let subscriptionExpiredFailed = menu.addItem(withTitle: "Subscription Expired (Billing Failed)", action: #selector(self.checkMenuItemSelected(_:)), keyEquivalent: "")
        subscriptionExpiredFailed.representedObject = "subscription_expired::renewalStatus:failed"
        subscriptionExpiredFailed.target = self

        self.updateState(of: menu, value: self.activateDebugString)

        return menu
    }

    @IBAction func checkMenuItemSelected(_ sender: NSMenuItem?) {
        self.checkDebugString = sender?.representedObject as? String
        self.updateState(of: sender?.menu, value: self.checkDebugString)
    }
}
#endif
