//
//  SignInViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SignInViewController: NSViewController, DeactivatedSubscriptionMode {
    let header = NSLocalizedString("Activate Pro", comment: "")
    let subheader = NSLocalizedString("Sign in to your M Cubed account to activate your device", comment: "")
    let actionName = NSLocalizedString("Activate Device", comment: "")
    let toggleName = NSLocalizedString("Not subscribed? Find out more", comment: "")

    func performAction() {
        print("sign in")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
