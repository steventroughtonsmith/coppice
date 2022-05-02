//
//  HotspotTypeProOverlay.swift
//  Coppice
//
//  Created by Martin Pilkington on 25/04/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit

class HotspotTypeProOverlayView: NSView {
    override func draw(_ rect: CGRect) {
        NSColor.black.withAlphaComponent(0.6).setFill()
        NSBezierPath(roundedRect: self.bounds, topLeftRadius: 0, topRightRadius: 8, bottomLeftRadius: 0, bottomRightRadius: 8).fill()
    }
}
