//
//  AppDelegate.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let documentController = CoppiceDocumentController()
    @IBOutlet weak var newLinkedPageMenuDelegate: NewPageMenuDelegate!

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

    lazy var preferencesWindow = PreferencesWindowController()
    @IBAction func showPreferences(_ sender: Any?) {
        self.preferencesWindow.showWindow(sender)
    }
}

