//
//  ModelSettings.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

class ModelSettings {
    struct Setting: Hashable, Equatable, RawRepresentable {
        typealias RawValue = String
        let rawValue: String
        init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    private var settings = [Setting : Any]()

    func value(for setting: Setting) -> Any? {
        return self.settings[setting]
    }

    func set(_ value: Any?, for setting: Setting) {
        self.settings[setting] = value
    }

    func set(_ modelID: ModelID?, for setting: Setting) {
        self.settings[setting] = modelID?.stringRepresentation
    }


    //MARK: - Typed Setting Accessors
    func string(for setting: Setting) -> String? {
        return self.value(for: setting) as? String
    }

    func integer(for setting: Setting) -> Int? {
        return self.value(for: setting) as? Int
    }

    func bool(for setting: Setting) -> Bool? {
        return self.value(for: setting) as? Bool
    }

    func modelID(for setting: Setting) -> ModelID? {
        guard let value = self.value(for: setting) as? String else {
            return nil
        }
        return ModelID(string: value)
    }


    //MARK: - Plist Conversion
    var plistRepresentation: [String: Any] {
        var plist = [String: Any]()
        self.settings.forEach { plist[$0.rawValue] = $1 }
        return plist
    }

    func update(withPlist plist: [String: Any]) {
        var newSettings = [Setting: Any]()
        plist.forEach { newSettings[Setting(rawValue: $0)] = $1 }
        self.settings = newSettings
    }
}
