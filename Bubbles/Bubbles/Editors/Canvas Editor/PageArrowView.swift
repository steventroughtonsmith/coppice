//
//  PageArrowView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

class PageArrowView: NSView {
    var arrow: LayoutEngineArrow?
    lazy var colour: NSColor = {
        return NSColor(red: CGFloat(Int.random(in: 0...255))/255.0,
                       green: CGFloat(Int.random(in: 0...255))/255.0,
                       blue: CGFloat(Int.random(in: 0...255))/255.0,
                       alpha: 1)
    }()

    override func draw(_ dirtyRect: NSRect) {
        self.colour.set()
        self.bounds.fill()
    }
}
