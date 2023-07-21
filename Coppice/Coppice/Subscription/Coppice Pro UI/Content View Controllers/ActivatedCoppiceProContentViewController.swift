//
//  ActivatedCoppiceProContentViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa

class ActivatedCoppiceProContentViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    //Setup
        //Show activation details

    //on deactivate
        //Call deactivate
}

extension ActivatedCoppiceProContentViewController: CoppiceProContentView {
    var leftActionTitle: String {
        return "Deactivate Device"
    }

    var leftActionIcon: NSImage {
        return NSImage(systemSymbolName: "display", accessibilityDescription: nil)!
    }

    func performLeftAction(in viewController: CoppiceProViewController) {
        viewController.currentContentView = .login
    }

    var rightActionTitle: String {
        return "View Account…"
    }

    var rightActionIcon: NSImage {
        return NSImage(systemSymbolName: "person.fill", accessibilityDescription: nil)!
    }

    func performRightAction(in viewController: CoppiceProViewController) {
        NSWorkspace.shared.open(.mcubedAccount)
    }
}
