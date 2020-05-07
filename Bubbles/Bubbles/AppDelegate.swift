//
//  AppDelegate.swift
//  Bubbles
//
//  Created by Martin Pilkington on 03/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let documentController = BubblesDocumentController()
    @IBOutlet weak var newLinkedPageMenuDelegate: NewPageMenuDelegate!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #if !DEBUG
        if let debugMenu = NSApplication.shared.mainMenu?.item(withTag: -31) {
            NSApplication.shared.mainMenu?.removeItem(debugMenu)
        }
        #endif

        //Expires 1st June 2020
        if Date.timeIntervalSinceReferenceDate >= 612705600.0 {
            let alert = NSAlert()
            alert.messageText = "This version has expired"
            alert.informativeText = "Please contact M Cubed Software or download the latest version"
            alert.runModal()
            NSApplication.shared.terminate(self)
        }

        self.newLinkedPageMenuDelegate.action = #selector(TextEditorViewController.createNewLinkedPage(_:))
        self.newLinkedPageMenuDelegate.includeKeyEquivalents = false
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
        let documents = BubblesDocumentController.shared.documents.compactMap { $0 as? Document }

        pageURLs.forEach { (url) in
            for document in documents {
                if document.handle(url) {
                    break
                }
            }
        }
    }
    
}

