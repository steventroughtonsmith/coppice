//
//  GeneralPreferencesViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class GeneralPreferencesViewController: NSViewController {

    func createTabItem() -> NSTabViewItem {
        let item = NSTabViewItem(viewController: self)
        item.label = NSLocalizedString("General", comment: "General Preferences Title")
        item.image = NSImage(named: "NSPreferencesGeneral")
        return item
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
