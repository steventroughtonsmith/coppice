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

        let v2MenuItem = NSMenuItem(title: "V2", action: nil, keyEquivalent: "")
        v2MenuItem.submenu = self.buildV2DebugMenu()
        menu.addItem(v2MenuItem)

        let v1MenuItem = NSMenuItem(title: "V1", action: nil, keyEquivalent: "")
        v1MenuItem.submenu = self.buildV1ResponsesMenu()
        menu.addItem(v1MenuItem)

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


    //MARK: - Network Adapter Debug
    enum DebugResponse {
        case none
        case data(APIData)
        case error(Error)
    }

    var debugResponse: DebugResponse = .none
    private var baseDebugResponse: DebugResponse = .none
    private var debugResponsesByEndPoint: [String: DebugResponse] = [:]

    func debugResponse(forEndpoint endpoint: String) -> DebugResponse {
        return self.debugResponsesByEndPoint[endpoint] ?? self.baseDebugResponse
    }

    func resetDebugResponses() {
        self.baseDebugResponse = .none
        self.debugResponsesByEndPoint = [:]
    }

    func setDebugResponse(_ debugResponse: DebugResponse, forEndpoint endpoint: String? = nil) {
        guard let endpoint else {
            self.baseDebugResponse = debugResponse
            return
        }
        self.debugResponsesByEndPoint[endpoint] = debugResponse
    }



    //MARK: - V2 Menu
    private func buildV2DebugMenu() -> NSMenu {
        let menu = NSMenu()
        menu.items = API.V2.Debug.shared.debugMenuItems()
        return menu
    }



    //MARK: - V1 Menu
    private func buildV1ResponsesMenu() -> NSMenu {
        let menu = NSMenu()

        let deactivateMenuItem = NSMenuItem(title: "Deactivation Errors", action: nil, keyEquivalent: "")
        deactivateMenuItem.submenu = self.buildDeactivateMenu()
        menu.addItem(deactivateMenuItem)

        let checkMenuItem = NSMenuItem(title: "Check Errors", action: nil, keyEquivalent: "")
        checkMenuItem.submenu = self.buildCheckMenu()
        menu.addItem(checkMenuItem)
        return menu
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

        self.updateState(of: menu, value: self.deactivateDebugString)

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

        self.updateState(of: menu, value: self.checkDebugString)

        return menu
    }

    @IBAction func checkMenuItemSelected(_ sender: NSMenuItem?) {
        self.checkDebugString = sender?.representedObject as? String
        self.updateState(of: sender?.menu, value: self.checkDebugString)
    }
}
#endif
