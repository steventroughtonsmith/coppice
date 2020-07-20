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

    let systemInfo: [[String: Any]]
    init(systemInfo: [[String: Any]]) {
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

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let infoItem = self.systemInfo[safe: row] else {
            return nil
        }

        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "name") {
            return infoItem[(self.showRawData ? "key" : "displayKey")]
        }
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "value") {
            return infoItem[(self.showRawData ? "value" : "displayValue")]
        }
        return nil
    }
}
