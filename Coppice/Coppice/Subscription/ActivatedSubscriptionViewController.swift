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
    @IBOutlet weak var editDeviceNameButton: NSButton!

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
        self.subscriptionStateLabel.stringValue = response.subscription?.localizedState ?? NSLocalizedString("Deactivated", comment: "Deactivated subscription state")
        self.subscriptionInfoLabel.stringValue = response.subscription?.localizedInfo ?? ""

        self.subscriptionDeviceLabel.stringValue = response.deviceName ?? "Unknown"

        self.billingFailedHelpButton.isHidden = !(response.subscription?.renewalStatus == .failed)
        self.updateEditDeviceButton()
    }



    //MARK: - Billing Failed
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

    //MARK: - Deactivation
    @IBOutlet weak var deactivateButton: NSButton!
    @IBAction func deactivate(_ sender: Any) {
        guard let window = self.view.window else {
            return
        }
        self.subscriptionManager.deactivate(on: window) { error in
            return self.handleDeactivationError(error)
        }
    }

    private func handleDeactivationError(_ error: NSError) -> Bool {
        guard let errorCode = SubscriptionErrorCodes(rawValue: error.code) else {
            return false
        }
        switch errorCode {
        case .noDeviceFound:
            break
        default:
            ErrorPopoverViewController.show(error,
                                            relativeTo: self.deactivateButton.bounds,
                                            of: self.deactivateButton,
                                            preferredEdge: .maxY)
        }

        return true
    }


    //MARK: - Device Name
    @IBOutlet weak var deviceNameLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var editDeviceNameField: NSTextField!
    var isHoveredOverDeviceName: Bool = false {
        didSet {
            guard oldValue != self.isHoveredOverDeviceName else {
                return
            }
            self.updateEditDeviceButton()
        }
    }
    var isEditingDeviceName: Bool = false {
        didSet {
            guard oldValue != self.isEditingDeviceName else {
                return
            }
            self.updateEditDeviceButton()
            self.updateDeviceNameLabelEditability()
        }
    }


    @IBAction func editDeviceName(_ sender: Any) {
        self.isEditingDeviceName = true
    }

    private func updateEditDeviceButton() {
        let showEditButton = self.isHoveredOverDeviceName && !self.isEditingDeviceName
        self.editDeviceNameButton.isHidden = !showEditButton
    }

    private func updateDeviceNameLabelEditability() {
        if (self.isEditingDeviceName) {
            self.editDeviceNameField.stringValue = self.subscriptionDeviceLabel.stringValue
            self.subscriptionDeviceLabel.isHidden = true
            self.editDeviceNameField.isHidden = false
        } else {
            self.subscriptionDeviceLabel.isHidden = false
            self.editDeviceNameField.isHidden = true
        }
    }

    private func handleUpdateNameError(_ error: NSError) -> Bool {
        guard let errorCode = SubscriptionErrorCodes(rawValue: error.code) else {
            return false
        }
        switch errorCode {
        case .noDeviceFound:
            break
        case .noSubscriptionFound:
            break
        default:
            ErrorPopoverViewController.show(error,
                                            relativeTo: self.subscriptionDeviceLabel.bounds,
                                            of: self.subscriptionDeviceLabel,
                                            preferredEdge: .maxY)
        }

        return true
    }
}

extension ActivatedSubscriptionViewController: HoverViewDelegate {
    func mouseDidEnter(_ hoverView: HoverView) {
        self.isHoveredOverDeviceName = true
    }

    func mouseDidExit(_ hoverView: HoverView) {
        self.isHoveredOverDeviceName = false
    }
}


extension ActivatedSubscriptionViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(cancelOperation(_:))) {
            self.isEditingDeviceName = false
            self.update(with: self.subscriptionManager.activationResponse)
            return true
        } else if (commandSelector == #selector(insertNewline(_:))) {
            if let window = self.view.window {
                self.subscriptionManager.updateDeviceName(deviceName: self.editDeviceNameField.stringValue, on: window) { error in
                    return self.handleUpdateNameError(error)
                }
                self.isEditingDeviceName = false
            }
            return true
        }
        return false
    }
}
