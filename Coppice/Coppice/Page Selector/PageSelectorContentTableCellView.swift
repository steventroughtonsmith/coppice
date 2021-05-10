//
//  PageSelectorContentTableCellView.swift
//  Coppice
//
//  Created by Martin Pilkington on 10/05/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa

class PageSelectorContentTableCellView: NSTableCellView, TableCell {
    static var identifier = NSUserInterfaceItemIdentifier(rawValue: "PageSelectorContentCell")
    static var nib = NSNib(nibNamed: "PageSelectorContentTableCellView", bundle: nil)
    
}
