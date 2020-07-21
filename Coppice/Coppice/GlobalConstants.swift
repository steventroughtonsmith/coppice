//
//  GlobalConstants.swift
//  Coppice
//
//  Created by Martin Pilkington on 14/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

extension GlobalConstants {
    static let newWindowSize = CGSize(width: 900, height: 600)
}

extension NSColor {
    static let canvasBackgroundDark = NSColor(named: "CanvasBackgroundDark") ?? .clear
    static let canvasBackgroundLight = NSColor(named: "CanvasBackgroundLight") ?? .clear

    static let arrowDark = NSColor(named: "ArrowColourDark") ?? .white
    static let arrowLight = NSColor(named: "ArrowColourLight") ?? .black
}
