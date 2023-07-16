//
//  CoppiceGreenView.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

class CoppiceGreenView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        guard let color = NSColor(named: "CoppiceGreen") else {
            return
        }
        color.set()
        self.bounds.fill()

        NSGradient(colors: [.clear, .black.withAlphaComponent(0.09)])?.draw(in: self.bounds, angle: -90)
    }
}
