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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let documentController = CoppiceDocumentController()
    @IBOutlet weak var newLinkedPageMenuDelegate: NewPageMenuDelegate!
    @IBOutlet weak var updaterController: SPUStandardUpdaterController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #if !DEBUG
        if let debugMenu = NSApplication.shared.mainMenu?.item(withTag: -31) {
            NSApplication.shared.mainMenu?.removeItem(debugMenu)
        }
        #endif

        let expiryDate = ISO8601DateFormatter().date(from: "2020-08-01T00:00:00Z")?.timeIntervalSinceReferenceDate ?? 0;
        if Date.timeIntervalSinceReferenceDate >= expiryDate {
            let alert = NSAlert()
            alert.messageText = "This version has expired"
            alert.informativeText = "Please contact M Cubed Software or download the latest version"
            alert.runModal()
            NSApplication.shared.terminate(self)
        }

        self.newLinkedPageMenuDelegate.action = #selector(TextEditorViewController.createNewLinkedPage(_:))
        self.newLinkedPageMenuDelegate.includeKeyEquivalents = false

        UserDefaults.standard.set(true, forKey: "NSTextViewAvoidLayoutWhileDrawing")

        UserDefaults.standard.register(defaults: [
            .defaultFontName: Page.fallbackFontName,
            .defaultFontSize: Page.fallbackFontSize,
            .defaultCanvasTheme: Canvas.Theme.auto.rawValue,
            .autoLinkingTextPagesEnabled: true
        ])
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    #if TEST
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }
    #endif

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

    //MARK: - Preferences
    lazy var preferencesWindow: PreferencesWindowController = {
        return PreferencesWindowController(updaterController: self.updaterController)
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
}

