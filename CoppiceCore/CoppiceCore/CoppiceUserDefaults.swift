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

    case useSmallCanvasCells = "M3UseSmallCanvasCells"

    case canvasListIsCompact = "M3CanvasListIsCompact"

    case defaultFontName = "M3DefaultFontName"
    case defaultFontSize = "M3DefaultFontSize"

    case defaultCanvasTheme = "M3DefaultCanvasTheme"

    case autoLinkingTextPagesEnabled = "M3AutoLinkingTextPagesEnabled"

    case showWelcomeScreenOnLaunch = "M3ShowWelcomeScreenOnLaunch"
}

public extension UserDefaults {
    func bool(forKey key: UserDefaultsKeys) -> Bool {
        return self.bool(forKey: key.rawValue)
    }

    func set(_ value: Bool, forKey key: UserDefaultsKeys) {
        self.set(value, forKey: key.rawValue)
    }

    func integer(forKey key: UserDefaultsKeys) -> Int {
        return self.integer(forKey: key.rawValue)
    }

    func float(forKey key: UserDefaultsKeys) -> Float {
        return self.float(forKey: key.rawValue)
    }

    func set(_ value: Int, forKey key: UserDefaultsKeys) {
        self.set(value, forKey: key.rawValue)
    }

    func string(forKey key: UserDefaultsKeys) -> String? {
        return self.string(forKey: key.rawValue)
    }

    func array(forKey key: UserDefaultsKeys) -> [Any]? {
        return self.array(forKey: key.rawValue)
    }

    func dictionary(forKey key: UserDefaultsKeys) -> [String: Any]? {
        return self.dictionary(forKey: key.rawValue)
    }

    func set(_ value: Any?, forKey key: UserDefaultsKeys) {
        self.set(value, forKey: key.rawValue)
    }

    func register(defaults defaultsDicts: [UserDefaultsKeys: Any]) {
        var defaults = [String: Any]()
        defaultsDicts.forEach { defaults[$0.rawValue] = $1 }
        self.register(defaults: defaults)
    }
}
