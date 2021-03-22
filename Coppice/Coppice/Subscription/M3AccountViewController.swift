//
//  M3AccountViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class CoppiceProViewController: NSViewController {
    func createTabItem() -> NSTabViewItem {
        let item = NSTabViewItem(viewController: self)
        item.label = NSLocalizedString("Coppice Pro", comment: "Pro Preferences Title")
        item.image = NSImage(named: "PrefsPro")
        return item
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
}
