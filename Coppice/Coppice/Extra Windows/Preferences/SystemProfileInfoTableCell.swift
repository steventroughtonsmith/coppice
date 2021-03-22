//
//  SystemProfileInfoKeyCell.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SystemProfileInfoTableCell: NSTableCellView {
    enum CellType {
        case key
        case value
    }

    var cellType = CellType.key {
        didSet {
            self.reloadData()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.reloadData()
    }

    var infoItem: SystemProfileInfoItem? {
        didSet {
            self.reloadData()
        }
    }

    var showRawData = true {
        didSet {
            self.reloadData()
        }
    }

    private func reloadData() {
        guard let infoItem = self.infoItem else {
            return
        }
        switch self.cellType {
        case .key:
            self.textField?.stringValue = (self.showRawData ? infoItem.key : infoItem.displayKey)
        case .value:
            self.textField?.objectValue = (self.showRawData ? infoItem.value : infoItem.displayValue)
        }
    }

    @IBAction func showInfo(_ sender: Any) {
        guard
            let infoItem = self.infoItem,
            let button = sender as? NSButton
        else {
            return
        }

        let info = infoItem.info

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = SimpleLabelPopoverViewController(label: info)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxX)
    }
}
