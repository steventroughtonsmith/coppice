//
//  SubscriptionTableCellView.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Subscriptions

protocol DeviceTableCellViewDelegate: AnyObject {
    func didSelect(_ tableCell: DeviceTableCellView)
}


class DeviceTableCellView: NSTableCellView, TableCell {
    static let identifier = NSUserInterfaceItemIdentifier("DeviceCell")
    static var nib: NSNib? = nil

    weak var delegate: DeviceTableCellViewDelegate?

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var activationDateLabel: NSTextField!

    @IBOutlet weak var radioButton: NSButton!

    var device: API.V2.ActivatedDevice? {
        didSet {
            self.reloadData()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.reloadData()
    }

    private func reloadData() {
        guard let activatedDevice = self.device else {
            return
        }
        self.nameLabel.stringValue = activatedDevice.deviceName ?? ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let date = Date(timeIntervalSince1970: activatedDevice.timestamp)
        self.activationDateLabel.stringValue = dateFormatter.string(from: date)
    }

    @IBAction func radioClicked(_ sender: Any) {
        self.delegate?.didSelect(self)
    }
}
