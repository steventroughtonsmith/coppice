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

    weak var delegate: SubscriptionTableCellViewDelegate?

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var activationsLabel: NSTextField!
    @IBOutlet weak var stateLabel: NSTextField!
    @IBOutlet weak var infoLabel: NSTextField!

    @IBOutlet weak var radioButton: NSButton!

    var subscription: M3Subscriptions.Subscription? {
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
        self.stateLabel.stringValue = subscription.localizedState
        self.infoLabel.stringValue = subscription.localizedInfo
        if let currentCount = subscription.currentDeviceCount, let maxDeviceCount = subscription.maxDeviceCount {
            self.activationsLabel.stringValue = "\(currentCount)/\(maxDeviceCount)"
        }
    }

    @IBAction func radioClicked(_ sender: Any) {
        self.delegate?.didSelect(self)
    }
}
