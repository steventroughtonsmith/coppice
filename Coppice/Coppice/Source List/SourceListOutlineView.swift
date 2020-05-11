//
//  SourceListOutlineView.swift
//  Coppice
//
//  Created by Martin Pilkington on 08/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SourceListOutlineView: NSOutlineView {
    //Remove the indent from the canvases row
    override func frameOfCell(atColumn column: Int, row: Int) -> NSRect {
        var rect = super.frameOfCell(atColumn: column, row: row)
        if row == 0 {
            rect.size.width += (rect.origin.x - 2)
            rect.origin.x = 2
        }
        return rect
    }
}
