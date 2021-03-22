//
//  TooManyDevicesViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Subscriptions

class TooManyDevicesViewController: NSViewController {
    typealias Completion = (M3Subscriptions.SubscriptionDevice?) -> Void

    let devices: [M3Subscriptions.SubscriptionDevice]
    let completion: Completion
    init(devices: [M3Subscriptions.SubscriptionDevice], completion: @escaping Completion) {
        self.devices = devices
        self.completion = completion
        super.init(nibName: "TooManyDevicesView", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadData()
    }

    @IBOutlet var activateButton: NSButton!
    @IBOutlet var tableView: NSTableView!

    @IBAction func activate(_ sender: Any) {
        self.completion(self.selectedDevice)
        self.presentingViewController?.dismiss(self)
    }

    @IBAction func cancel(_ sender: Any) {
        self.completion(nil)
        self.presentingViewController?.dismiss(self)
    }

    var selectedDevice: M3Subscriptions.SubscriptionDevice? {
        didSet {
            self.reloadData()
        }
    }

    private func reloadData() {
        self.tableView.reloadData()
        self.activateButton.isEnabled = (self.selectedDevice != nil)
    }
}

extension TooManyDevicesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.devices.count
    }
}

extension TooManyDevicesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(of: DeviceTableCellView.self) else {
            return nil
        }
        let device = self.devices[row]
        cell.device = device
        cell.delegate = self
        cell.radioButton.state = (device == self.selectedDevice) ? .on : .off
        return cell
    }
}


extension TooManyDevicesViewController: DeviceTableCellViewDelegate {
    func didSelect(_ tableCell: DeviceTableCellView) {
        self.selectedDevice = tableCell.device
    }
}
