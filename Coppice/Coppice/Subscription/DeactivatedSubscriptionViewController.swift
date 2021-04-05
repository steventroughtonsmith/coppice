//
//  DeactivatedSubscriptionViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Subscriptions

class DeactivatedSubscriptionViewController: NSViewController {
    let subscriptionManager: CoppiceSubscriptionManager
    init(subscriptionManager: CoppiceSubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        super.init(nibName: "DeactivatedSubscriptionViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.passwordField.stringValue = ""
    }


    //MARK: - Outlets
    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var passwordField: NSTextField!


    //MARK: - Activate
    @IBAction func activate(_ sender: NSButton?) {
        guard
            let window = self.view.window,
            let button = sender
        else {
            return
        }
        self.subscriptionManager.activate(withEmail: self.emailField.stringValue, password: self.passwordField.stringValue, on: window) { error in
            return self.handleActivateError(error, on: button)
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

    @objc dynamic var canActivateDevice = false


    //MARK: - Pro Upsell
    @IBAction func showPro(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "https://coppiceapp.com/pro")!)
    }
}

extension DeactivatedSubscriptionViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        self.canActivateDevice = !self.emailField.stringValue.isEmpty && !self.passwordField.stringValue.isEmpty
    }
}
