//
//  UpdatePreferencesViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Sparkle

class UpdatePreferencesViewController: NSViewController {

    func createTabItem() -> NSTabViewItem {
        let item = NSTabViewItem(viewController: self)
        item.label = NSLocalizedString("Updates", comment: "Updates Preferences Title")
        item.image = NSImage(named: "NSBonjour")
        return item
    }

    @IBOutlet var updaterController: SPUStandardUpdaterController!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

    }
}

