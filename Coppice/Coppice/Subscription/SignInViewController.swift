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

    let subscriptionManager: CoppiceSubscriptionManager
    init(subscriptionManager: CoppiceSubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        super.init(nibName: "SignInViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var passwordField: NSTextField!

    func performAction() {
        guard let window = self.view.window else {
            return
        }
        self.subscriptionManager.activate(withEmail: self.emailField.stringValue, password: self.passwordField.stringValue, on: window)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
