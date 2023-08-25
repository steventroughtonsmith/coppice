//
//  PageSelectorTableRowView.swift
//  Coppice
//
//  Created by Martin Pilkington on 04/07/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa

class PageSelectorTableRowView: NSTableRowView {
    override var isEmphasized: Bool {
        get { return self.isSelected }
        set {}
    }

    var cornerRadius: CGFloat = 5

    override func drawSelection(in dirtyRect: NSRect) {
        let color: NSColor = self.isEmphasized ? .selectedContentBackgroundColor : .unemphasizedSelectedContentBackgroundColor
        color.setFill()
        NSBezierPath(roundedRect: dirtyRect, xRadius: self.cornerRadius, yRadius: self.cornerRadius).fill()
    }
}
