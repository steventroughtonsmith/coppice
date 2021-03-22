//
//  ModelObjects+Defaults.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

extension Page {
    public static var fallbackFontName: String { "Helvetica Neue" }
    public static var fallbackFontSize: Float { 13.0 }

    public static var defaultFont: NSFont {
        let fontName = UserDefaults.standard.string(forKey: .defaultFontName) ?? self.fallbackFontName
        var fontSize = UserDefaults.standard.float(forKey: .defaultFontSize)
        if fontSize == 0 {
            fontSize = self.fallbackFontSize
        }


        guard let font = NSFont(name: fontName, size: CGFloat(fontSize)) else {
            guard let fallbackFont = NSFont(name: self.fallbackFontName, size: CGFloat(self.fallbackFontSize)) else {
                return NSFont.systemFont(ofSize: NSFont.systemFontSize)
            }
            return fallbackFont
        }
        return font
    }
}

extension Canvas {
    public static var defaultTheme: Theme {
        guard let rawDefaultTheme = UserDefaults.standard.string(forKey: .defaultCanvasTheme) else {
            return .auto
        }
        return Canvas.Theme(rawValue: rawDefaultTheme) ?? .auto
    }
}
