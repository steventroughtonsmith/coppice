//
//  ModelObjects+AppKit.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

extension Folder {
    static var icon: NSImage? {
        return NSImage.symbol(withName: Symbols.Page.folder(.small))
    }
}


extension Canvas.Theme {
    public var arrowColour: NSColor {
        switch self {
        case .dark:
            return NSColor.arrowDark
        case .light:
            return NSColor.arrowLight
        case .auto:
            return NSColor(name: "ArrowColour") { (appearance) -> NSColor in
                return (appearance.name == .darkAqua) ? NSColor.arrowDark : NSColor.arrowLight
            }
        }
    }

    public var canvasBackgroundColor: NSColor {
        switch self {
        case .dark:
            return NSColor.canvasBackgroundDark
        case .light:
            return NSColor.canvasBackgroundLight
        case .auto:
            return NSColor(name: "CanvasBackground") { (appearance) -> NSColor in
                return (appearance.name == .darkAqua) ? NSColor.canvasBackgroundDark : NSColor.canvasBackgroundLight
            }
        }
    }
}
