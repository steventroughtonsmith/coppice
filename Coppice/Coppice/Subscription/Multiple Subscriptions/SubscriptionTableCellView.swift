//
//  SubscriptionTableCellView.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Subscriptions

protocol SubscriptionTableCellViewDelegate: AnyObject {
    func didSelect(_ tableCell: SubscriptionTableCellView)
}


class SubscriptionTableCellView: NSTableCellView, TableCell {
    static let identifier = NSUserInterfaceItemIdentifier("SubscriptionCell")
    static var nib: NSNib? = nil

    weak var delegate: SubscriptionTableCellViewDelegate?

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var activationsLabel: NSTextField!
    @IBOutlet weak var stateLabel: NSTextField!
    @IBOutlet weak var infoLabel: NSTextField!

    @IBOutlet weak var radioButton: NSButton!

    var subscription: API.V2.Subscription? {
        didSet {
            self.reloadData()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.reloadData()
    }

    private func reloadData() {
        guard let subscription = self.subscription else {
            return
        }
        self.nameLabel.stringValue = subscription.name
        self.stateLabel.stringValue = CoppiceProViewModel.localizedStatus(expirationTimestamp: subscription.expirationTimestamp,
                                                                          renewalStatus: subscription.renewalStatus)
        self.infoLabel.stringValue = CoppiceProViewModel.localizedStatusDetails(expirationTimestamp: subscription.expirationTimestamp,
                                                                                renewalStatus: subscription.renewalStatus)
        if let currentCount = subscription.currentDeviceCount {
            self.activationsLabel.stringValue = "\(currentCount)/\(subscription.maxDeviceCount)"
        }
    }

    @IBAction func radioClicked(_ sender: Any) {
        self.delegate?.didSelect(self)
    }
}
