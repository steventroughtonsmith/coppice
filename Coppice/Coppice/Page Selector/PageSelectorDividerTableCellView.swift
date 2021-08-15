//
//  PageSelectorDividerTableCellView.swift
//  PageSelectorDividerTableCellView
//
//  Created by Martin Pilkington on 15/08/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa

class PageSelectorDividerTableCellView: NSTableCellView, TableCell {
    static var identifier = NSUserInterfaceItemIdentifier(rawValue: "PageSelectorDividerCell")
    static var nib = NSNib(nibNamed: "PageSelectorDividerTableCellView", bundle: nil)
}
