//
//  HelpNavigationTableCellView.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class HelpNavigationTableCellView: NSTableCellView {

    override var objectValue: Any? {
        didSet {
            self.reloadData()
        }
    }

    private func reloadData() {
        guard let node = self.objectValue as? HelpNavigationViewController.NavigationNode else {
            return
        }

        self.textField?.stringValue = node.item.title
    }
    
}
