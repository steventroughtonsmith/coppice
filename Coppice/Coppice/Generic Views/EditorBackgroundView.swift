//
//  EditorBackgroundView.swift
//  Coppice
//
//  Created by Martin Pilkington on 01/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class EditorBackgroundView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor(named: "PageBackground")?.set()
        self.bounds.fill()
    }
    
}
