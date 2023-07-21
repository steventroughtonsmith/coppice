//
//  LoginCoppiceProContentViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa

class LoginCoppiceProContentViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    //TODO
    //- On activate
        //login
        //on fail
            //Show errors
        //on success, get subscription list
        //on fail
            //show errors
        //on >1 sub
            //Show subs
            //let user select
            //on cancel, log out
        //on success, activate
        //on fail
            //show errors
        //on too many devices
            //fetch device list
            //on cancel, log out
            //on selection, deactivate device
            //attempt activation again
        //on success finish activation
}

extension LoginCoppiceProContentViewController: CoppiceProContentView {
    var leftActionTitle: String {
        return "Use Licence"
    }

    var leftActionIcon: NSImage {
        return NSImage(systemSymbolName: "doc", accessibilityDescription: nil)!
    }

    func performLeftAction(in viewController: CoppiceProViewController) {
        viewController.currentContentView = .licence
    }

    var rightActionTitle: String {
        return "Learn About Pro…"
    }

    var rightActionIcon: NSImage {
        return NSImage(named: "Pro-Tree-Icon")!
    }

    func performRightAction(in viewController: CoppiceProViewController) {
        NSWorkspace.shared.open(.coppicePro)
    }
}
