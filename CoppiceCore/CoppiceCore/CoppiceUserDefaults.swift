//
//  CoppiceUserDefaults.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation


public enum UserDefaultsKeys: String {
    case debugShowCanvasOrigin
    case debugShowArrowBounds

    case useSmallCanvasCells = "M3UseSmallCanvasCells"

    case canvasListIsCompact = "M3CanvasListIsCompact"

    case defaultFontName = "M3DefaultFontName"
    case defaultFontSize = "M3DefaultFontSize"

    case defaultCanvasTheme = "M3DefaultCanvasTheme"

    case autoLinkingTextPagesEnabled = "M3AutoLinkingTextPagesEnabled"

    case showWelcomeScreenOnLaunch = "M3ShowWelcomeScreenOnLaunch"

    case sidebarSize = "M3SidebarSize"

    case currentVersion = "M3CurrentVersion"

    case showProFeaturesInInspector = "M3ShowProFeaturesInInspector"

    case runMigrations = "M3RunMigrations"

    case needsLinkUpgrade = "M3NeedsLinkUpgrade"
}

extension UserDefaults {
    public func bool(forKey key: UserDefaultsKeys) -> Bool {
        return self.bool(forKey: key.rawValue)
    }

    public func set(_ value: Bool, forKey key: UserDefaultsKeys) {
        self.set(value, forKey: key.rawValue)
    }

    public func integer(forKey key: UserDefaultsKeys) -> Int {
        return self.integer(forKey: key.rawValue)
    }

    public func float(forKey key: UserDefaultsKeys) -> Float {
        return self.float(forKey: key.rawValue)
    }

    public func set(_ value: Int, forKey key: UserDefaultsKeys) {
        self.set(value, forKey: key.rawValue)
    }

    public func string(forKey key: UserDefaultsKeys) -> String? {
        return self.string(forKey: key.rawValue)
    }

    public func array(forKey key: UserDefaultsKeys) -> [Any]? {
        return self.array(forKey: key.rawValue)
    }

    public func dictionary(forKey key: UserDefaultsKeys) -> [String: Any]? {
        return self.dictionary(forKey: key.rawValue)
    }

    public func set(_ value: Any?, forKey key: UserDefaultsKeys) {
        self.set(value, forKey: key.rawValue)
    }

    public func register(defaults defaultsDicts: [UserDefaultsKeys: Any]) {
        var defaults = [String: Any]()
        defaultsDicts.forEach { defaults[$0.rawValue] = $1 }
        self.register(defaults: defaults)
    }
}
