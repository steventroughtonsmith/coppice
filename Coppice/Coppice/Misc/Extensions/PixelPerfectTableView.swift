//
//  PixelPerfectTableView.swift
//  Coppice
//
//  Created by Martin Pilkington on 08/05/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

class PixelPerfectTableView: NSTableView {
    override func rect(ofRow row: Int) -> NSRect {
        return super.rect(ofRow: row).rounded(.up)
    }
}
