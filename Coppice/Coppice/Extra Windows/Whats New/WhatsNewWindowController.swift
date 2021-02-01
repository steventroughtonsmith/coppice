//
//  WhatsNewWindowController.swift
//  Coppice
//
//  Created by Martin Pilkington on 01/02/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa

class WhatsNewWindowController: NSWindowController {

    override var windowNibName: NSNib.Name? {
        return "WhatsNewWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    func showIfNeeded() {
        guard let appVersion = VersionNumber.appVersion else {
            return
        }


        guard (UserDefaults.standard.bool(forKey: "SUHasLaunchedBefore") == true) else {
            UserDefaults.standard.set("\(appVersion.year).\(appVersion.version)", forKey: .currentVersion)
            return
        }

        //If we have launched before but don't have a currentVersion then the only version we can be is 2020.1.x
        let currentVersionString = UserDefaults.standard.string(forKey: .currentVersion) ?? "2020.0"
        guard let currentVersion = VersionNumber.with(currentVersionString) else {
            return
        }

        //Handle older year
        if (appVersion.year < currentVersion.year) {
            return
        }

        //Handle same year but older version
        if (appVersion.year == currentVersion.year) && (appVersion.version <= currentVersion.version) {
            return
        }

        //Update prefs so we don't show again
        UserDefaults.standard.set("\(appVersion.year).\(appVersion.version)", forKey: .currentVersion)

        //Show after a delay
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.showWindow(self)
            self.window?.makeKeyAndOrderFront(self)
        }
    }
    
    @IBAction func seeReleaseNotes(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://coppiceapp.com/release_notes")!)
    }
}
