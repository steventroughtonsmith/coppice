//
//  SidebarHeaderView.swift
//  Coppice
//
//  Created by Martin Pilkington on 13/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

@IBDesignable
class SidebarHeaderView: NSView {

    @IBInspectable var drawTopBorder: Bool = true

    override func draw(_ dirtyRect: NSRect) {
        if (self.drawTopBorder) {
            let rect = CGRect(x: 0, y: self.bounds.height - 1, width: self.bounds.width, height: 1)
            NSColor(named: "SidebarHeaderHighlight")?.set()
            rect.fill()
        }

        let rect = CGRect(x: 0, y: 0, width: self.bounds.width, height: 1)
        NSColor(named: "SidebarHeaderShadow")?.set()
        rect.fill()
    }
    
}
