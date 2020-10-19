//
//  SignInViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Subscriptions

class SignInViewController: NSViewController, DeactivatedSubscriptionMode {
    let header = NSLocalizedString("Activate Pro", comment: "")
    let subheader = NSLocalizedString("Sign in to your M Cubed account to activate your device", comment: "")
    let actionName = NSLocalizedString("Activate Device", comment: "")
    let toggleName = NSLocalizedString("Don't have Pro? Find out more", comment: "")

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

    func performAction(_ sender: NSButton) {
        guard let window = self.view.window else {
            return
        }
        self.subscriptionManager.activate(withEmail: self.emailField.stringValue, password: self.passwordField.stringValue, on: window) { error in
            return self.handleActivateError(error, on: sender)
        }
    }


    private func handleActivateError(_ error: NSError, on button: NSButton) -> Bool {
        guard let errorCode = SubscriptionErrorCodes(rawValue: error.code) else {
            return false
        }

        switch errorCode {
        case .noSubscriptionFound, .subscriptionExpired:
            ErrorPopoverViewController.show(error,
                                            relativeTo: button.bounds,
                                            of: button,
                                            preferredEdge: .maxX) //Show to the right so the user knows to select the button below
        default:
            ErrorPopoverViewController.show(error,
                                            relativeTo: button.bounds,
                                            of: button,
                                            preferredEdge: .maxY)
        }

        return true
    }
}
