//
//  CanvasPageBackgroundView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasPageBackgroundView: NSView {
    override var isFlipped: Bool {
        return true
    }

    //MARK: - Initialisation
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.blue.set()
        self.bounds.fill()
    }
    
}
