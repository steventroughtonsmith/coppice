//
//  SystemProfileInfoViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class SystemProfileInfoViewController: NSViewController {

    let systemInfo: [SystemProfileInfoItem]
    init(systemInfo: [SystemProfileInfoItem]) {
        self.systemInfo = systemInfo
        super.init(nibName: "SystemProfileInfoViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func ok(_ sender: Any) {
        self.dismiss(self)
    }

    @IBOutlet weak var tableView: NSTableView!

    @IBOutlet weak var dataTypeSegmentedControl: NSSegmentedControl!
    @IBAction func dataTypeChanged(_ sender: Any) {
        self.tableView.reloadData()
    }

    private var showRawData: Bool {
        return (self.dataTypeSegmentedControl.selectedSegment == 0)
    }
}


extension SystemProfileInfoViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.systemInfo.count
    }
}


extension SystemProfileInfoViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let infoItem = self.systemInfo[safe: row] else {
            return nil
        }

        let identifier = (tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "name")) ? "KeyCell" : "ValueCell"

        let infoCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier), owner: nil) as? SystemProfileInfoTableCell
        infoCell?.infoItem = infoItem
        infoCell?.showRawData = self.showRawData
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "name") {
            infoCell?.cellType = .key
        }
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "value") {
            infoCell?.cellType = .value
        }
        return infoCell
    }
}
