//
//  ActivatedSubscriptionViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import M3Subscriptions

class ActivatedSubscriptionViewController: NSViewController {
    @IBOutlet weak var subscriptionNameLabel: NSTextField!
    @IBOutlet weak var subscriptionStateLabel: NSTextField!
    @IBOutlet weak var subscriptionDeviceLabel: NSTextField!
    @IBOutlet weak var subscriptionInfoLabel: NSTextField!
    @IBOutlet weak var billingFailedHelpButton: NSButton!

    let subscriptionManager: CoppiceSubscriptionManager
    init(subscriptionManager: CoppiceSubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        super.init(nibName: "ActivatedSubscriptionViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        self.startObserving()
    }

    //MARK: - Observe Subscription
    private var activationObserver: AnyCancellable?
    private func startObserving() {
        self.activationObserver = self.subscriptionManager.$activationResponse.sink { [weak self] (response) in
            self?.update(with: response)
        }
    }

    private func update(with activationResponse: ActivationResponse?) {
        guard let response = activationResponse else {
            return
        }

        self.subscriptionNameLabel.stringValue = response.subscription?.name ?? NSLocalizedString("No Subscription Found", comment: "'No subscription' subscription name")
        self.subscriptionStateLabel.stringValue = self.localizedState(for: response.subscription)
        self.subscriptionInfoLabel.stringValue = self.localizedInfo(for: response.subscription)

        self.subscriptionDeviceLabel.stringValue = response.deviceName ?? "Unknown"

        self.billingFailedHelpButton.isHidden = !(response.subscription?.renewalStatus == .failed)
    }

    private func localizedState(for subscription: M3Subscriptions.Subscription?) -> String {
        guard let subscription = subscription else {
            return NSLocalizedString("Deactivated", comment: "Deactivated subscription state")
        }
        if subscription.hasExpired {
            return NSLocalizedString("Expired", comment: "Expired subscription state")
        }
        if subscription.renewalStatus == .failed {
            return NSLocalizedString("Billing Failed", comment: "Billing Failed subscription state")
        }

        return NSLocalizedString("Active", comment: "Active subscription state")
    }

    private func localizedInfo(for subscription: M3Subscriptions.Subscription?) -> String {
        guard let subscription = subscription else {
            return ""
        }

        let format: String
        if subscription.hasExpired {
            format = NSLocalizedString("(expired on %@)", comment: "'expired on <date>' expired subscription info label")
        } else {
            switch subscription.renewalStatus {
            case .renew:
                format = NSLocalizedString("(will renew on %@)", comment: "'will renew on <date>' active subscription info label")
            case .cancelled, .failed:
                format = NSLocalizedString("(will expire on %@)", comment: "'will expire on <date>' active subscription that will expire (due to billing failure or the user cancelling) info label")
            default:
                return ""
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none

        return String(format: format, dateFormatter.string(from: subscription.expirationDate))
    }

    //MARK: - Actions
    @IBAction func deactivate(_ sender: Any) {
        guard let window = self.view.window else {
            return
        }
        self.subscriptionManager.deactivate(on: window)
    }

    @IBAction func editDeviceName(_ sender: Any) {
    }

    private enum BillingFailedAlert: Int {
        case cancel = 0
        case goToAccount = 1
        case contactSupport = 2
    }

    @IBAction func billingFailedHelp(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("A Billing Problem Has Occured", comment: "Billing failure alert title")
        alert.informativeText = NSLocalizedString("An issue has occured while attempting to renew your subscription. Please log into your M Cubed account and check your billing details are up-to-date. \n\nIf the problem persists, please contact M Cubed Software for support", comment: "Billing failure alert body")
        alert.addButton(withTitle: NSLocalizedString("Go to Account", comment: "Go to Account billing failure alert button title")).tag = BillingFailedAlert.goToAccount.rawValue
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel")).tag = BillingFailedAlert.cancel.rawValue
        alert.addButton(withTitle: NSLocalizedString("Contact Support", comment: "Contact support billing failure alert button title")).tag = BillingFailedAlert.contactSupport.rawValue

        if let window = self.view.window {
            alert.beginSheetModal(for: window) { (response) in
                self.performBillingFailedAction(for: response)
            }
        } else {
            self.performBillingFailedAction(for: alert.runModal())
        }
    }

    private func performBillingFailedAction(for response: NSApplication.ModalResponse) {
        guard let alert = BillingFailedAlert(rawValue: response.rawValue) else {
            return
        }
        switch alert {
        case .goToAccount:
            NSWorkspace.shared.open(URL(string: "https://www.mcubedsw.com/account")!)
        case .contactSupport:
            NSWorkspace.shared.open(URL(string: "mailto:support@mcubedsw.com")!)
        case .cancel:
            break
        }
    }
}
