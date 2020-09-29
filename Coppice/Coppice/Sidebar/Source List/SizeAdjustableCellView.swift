//
//  SizeAdjustableCellView.swift
//  Coppice
//
//  Created by Martin Pilkington on 29/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SizeAdjustableCellView: NSTableCellView, SidebarSizable {
    var activeSidebarSize: ActiveSidebarSize = .medium {
        didSet {
            self.textField?.font = NSFont.controlContentFont(ofSize: self.activeSidebarSize.smallRowFontSize)
        }
    }
}
