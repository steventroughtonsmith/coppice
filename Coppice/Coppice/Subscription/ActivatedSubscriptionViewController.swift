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
//        self.subscriptionDeviceLabel.stringValue = response.subscription
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        switch response.state {
        case .active:
            self.subscriptionStateLabel.stringValue = NSLocalizedString("Active", comment: "Active subscription state")
            if let expirationDate = response.subscription?.expirationDate {
                let renewsFormatString = NSLocalizedString("(Renews %@)", comment: "Active subscription info")
                self.subscriptionInfoLabel.stringValue = String(format: renewsFormatString, dateFormatter.string(from: expirationDate))
            } else {
                self.subscriptionInfoLabel.stringValue = ""
            }
        case .billingFailed:
            self.subscriptionStateLabel.stringValue = NSLocalizedString("Billing Failed", comment: "Billing Failed subscription state")
            if let expirationDate = response.subscription?.expirationDate {
                let expiresFormatString = NSLocalizedString("(Expires %@)", comment: "Expiring subscription info")
                self.subscriptionInfoLabel.stringValue = String(format: expiresFormatString, dateFormatter.string(from: expirationDate))
            } else {
                self.subscriptionInfoLabel.stringValue = ""
            }
        default:
            self.subscriptionStateLabel.stringValue = NSLocalizedString("Deactivated", comment: "Deactivated subscription state")
            self.subscriptionInfoLabel.stringValue = ""
        }
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
}
