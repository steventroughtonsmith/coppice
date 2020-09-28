//
//  AppDelegate.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Sparkle
import CoppiceCore
import M3Subscriptions


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var newLinkedPageMenuDelegate: NewPageMenuDelegate!
    @IBOutlet weak var updaterController: SPUStandardUpdaterController!

    let subscriptionManager = CoppiceSubscriptionManager.shared

    lazy var documentController = CoppiceDocumentController()

    override init() {
        super.init()
        self.setupDefaults()
    }

    private func setupDefaults() {
        UserDefaults.standard.register(defaults: [
            .defaultFontName: Page.fallbackFontName,
            .defaultFontSize: Page.fallbackFontSize,
            .defaultCanvasTheme: Canvas.Theme.auto.rawValue,
            .autoLinkingTextPagesEnabled: true,
            .showWelcomeScreenOnLaunch: true,
            .sidebarSize: SidebarSize.system.rawValue
        ])
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let debugMenu = NSApplication.shared.mainMenu?.item(withTag: -31) {
            #if DEBUG
            debugMenu.submenu?.addItem(NSMenuItem.separator())
            let apiMenuItem = NSMenuItem(title: "API Debugging", action: nil, keyEquivalent: "")
            let apiMenu = APIDebugManager.shared.buildMenu()
            apiMenu.addItem(NSMenuItem.separator())
            let checkItem = apiMenu.addItem(withTitle: "Check Subscription", action: #selector(checkSubscription(_:)), keyEquivalent: "")
            checkItem.target = self
            apiMenuItem.submenu = apiMenu
            debugMenu.submenu?.addItem(apiMenuItem)
            #else
            NSApplication.shared.mainMenu?.removeItem(debugMenu)
            #endif
        }

        let expiryDate = ISO8601DateFormatter().date(from: "2020-10-31T00:00:00Z")?.timeIntervalSinceReferenceDate ?? 0;
        if Date.timeIntervalSinceReferenceDate >= expiryDate {
            let alert = NSAlert()
            alert.messageText = "This version has expired"
            alert.informativeText = "Please contact M Cubed Software or download the latest version"
            alert.runModal()
            NSApplication.shared.terminate(self)
        }

        self.newLinkedPageMenuDelegate.action = #selector(TextEditorViewController.createNewLinkedPage(_:))
        self.newLinkedPageMenuDelegate.includeKeyEquivalents = false

        self.subscriptionManager.delegate = self

        UserDefaults.standard.set(true, forKey: "NSTextViewAvoidLayoutWhileDrawing")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        #if TEST
        return false
        #else
        //We need to do this here as applicationDidFinishLaunching is called before any documents are restored, but applicationShouldHandleReopen is not called on launch
        if (UserDefaults.standard.bool(forKey: .showWelcomeScreenOnLaunch)) {
            self.welcomeWindow.showWindow(nil)
            return false
        }
        return true
        #endif
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard
            UserDefaults.standard.bool(forKey: .showWelcomeScreenOnLaunch),
            (flag == false)
        else {
            return true
        }

        self.welcomeWindow.showWindow(nil)
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        let pageURLs = urls.filter { $0.scheme == GlobalConstants.urlScheme }
        let documents = CoppiceDocumentController.shared.documents.compactMap { $0 as? Document }

        pageURLs.forEach { (url) in
            for document in documents {
                if document.handle(url) {
                    break
                }
            }
        }
    }

    @IBAction func betaFeedback(_ sender: Any?) {
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "Unknown"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "N/A"
        let bodyValue = "Coppice Version: \(versionString) (\(version))\nOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)\n\nPlease provide your feedback below:\n"

        let subjectItem = URLQueryItem(name: "subject", value: "[Coppice Beta Feedback]")
        let bodyItem = URLQueryItem(name: "body", value: bodyValue)

        var urlComponents = URLComponents()
        urlComponents.scheme = "mailto"
        urlComponents.path = "support@mcubedsw.com"
        urlComponents.queryItems = [subjectItem, bodyItem]
        guard let url = urlComponents.url else {
            let alert = NSAlert()
            alert.messageText = "Something went wrong"
            alert.informativeText = "Please contact M Cubed Software at support@mcubedsw.com"
            alert.runModal()
            return
        }
        NSWorkspace.shared.open(url)
    }

    //MARK: - Preferences
    lazy var preferencesWindow: PreferencesWindowController = {
        return PreferencesWindowController(updaterController: self.updaterController, subscriptionManager: self.subscriptionManager)
    }()
    @IBAction func showPreferences(_ sender: Any?) {
        self.preferencesWindow.showWindow(sender)
    }

    //MARK: - About
    lazy var aboutWindow: AboutWindowController = {
        return AboutWindowController()
    }()

    @IBAction func showAboutWindow(_ sender: Any?) {
        self.aboutWindow.showWindow(sender)
    }


    //MARK: - Welcome
    lazy var welcomeWindow: WelcomeWindowController = {
        return WelcomeWindowController()
    }()
    @IBAction func showWelcomeWindow(_ sender: Any?) {
        self.welcomeWindow.showWindow(sender)
    }


    //MARK: - Tour
    lazy var tourWindow: TourWindowController = {
        return TourWindowController()
    }()
    @IBAction func showTour(_ sender: Any?) {
        self.tourWindow.showWindow(sender)
    }

    #if DEBUG
    @IBAction func checkSubscription(_ sender: Any?) {
        self.subscriptionManager.checkSubscription()
    }
    #endif
}


extension AppDelegate: CoppiceSubscriptionManagerDelegate {
    func showCoppicePro(with error: NSError, for subscriptionManager: CoppiceSubscriptionManager) {
        self.preferencesWindow.showWindow(nil)
        self.preferencesWindow.showCoppicePro()

        let alert = NSAlert(error: error)
        if let window = self.preferencesWindow.window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}

