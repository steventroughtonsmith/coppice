//
//  FlippedView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 09/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class FlippedView: NSView {
    override var isFlipped: Bool {
        return true
    }
}

class FlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}
