//
//  LinkUpgradeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 23/10/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa

class LinkUpgradeViewController: NSViewController {
    var callback: (() -> Void)?

    @IBAction func okClicked(_ sender: Any) {
        self.callback?()
    }
}
