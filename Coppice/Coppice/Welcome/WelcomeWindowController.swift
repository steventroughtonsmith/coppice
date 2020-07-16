//
//  WelcomeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class WelcomeWindowController: NSWindowController {
    @IBOutlet weak var buttonStackView: NSStackView!

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    override var windowNibName: NSNib.Name? {
        return "WelcomeWindow"
    }
    
}
