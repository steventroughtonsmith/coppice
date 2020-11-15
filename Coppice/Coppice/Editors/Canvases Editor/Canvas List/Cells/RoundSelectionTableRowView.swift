//
//  RoundSelectionTableRowView.swift
//  Coppice
//
//  Created by Martin Pilkington on 08/05/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

class RoundSelectionTableRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        if self.isEmphasized {
            NSColor.selectedContentBackgroundColor.set()
        } else {
            NSColor.unemphasizedSelectedContentBackgroundColor.set()
        }
        let insetRect = dirtyRect.insetBy(dx: 2, dy: 2)
        let bezierPath = NSBezierPath(roundedRect: insetRect, xRadius: 4, yRadius: 4)
        bezierPath.fill()
    }
}
