//
//  RenameDeviceViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 05/04/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Subscriptions

protocol RenameDeviceViewControllerDelegate: AnyObject {
    func didCompleteRenaming(in viewController: RenameDeviceViewController)
}

class RenameDeviceViewController: NSViewController {
    weak var delegate: RenameDeviceViewControllerDelegate?

    let subscriptionManager: CoppiceSubscriptionManager
    init(subscriptionManager: CoppiceSubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        super.init(nibName: "RenameDeviceViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet var editDeviceNameField: NSTextField!
    @IBOutlet var renameButton: NSButton!

    override func viewWillAppear() {
        super.viewWillAppear()

        self.editDeviceNameField.stringValue = self.subscriptionManager.activationResponse?.deviceName ?? ""
    }

    @IBAction func rename(_ sender: Any?) {
        self.subscriptionManager.updateDeviceName(deviceName: self.editDeviceNameField.stringValue) { result in
            switch result {
            case .success:
                self.presentingViewController?.dismiss(self)
            case .failure(let error):
                self.handleUpdateNameError(error as NSError)
            }
        }
    }

    private func handleUpdateNameError(_ error: NSError) {
        guard let errorCode = SubscriptionErrorCodes(rawValue: error.code) else {
            return
        }
        switch errorCode {
        case .noDeviceFound:
            break
        case .noSubscriptionFound:
            break
        default:
            ErrorPopoverViewController.show(error,
                                            relativeTo: self.renameButton.bounds,
                                            of: self.renameButton,
                                            preferredEdge: .maxY)
        }
    }

    @IBAction func cancel(_ sender: Any?) {
        self.presentingViewController?.dismiss(self)
    }
}
