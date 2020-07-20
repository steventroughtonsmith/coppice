//
//  ModelSettings.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public class ModelSettings {
    public struct Setting: Hashable, Equatable, RawRepresentable {
        public typealias RawValue = String
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public init() {}

    private var settings = [Setting : Any]()

    public func value(for setting: Setting) -> Any? {
        return self.settings[setting]
    }

    public func set(_ value: Any?, for setting: Setting) {
        self.settings[setting] = value
    }


    //MARK: - Typed Setting Accessors
    public func string(for setting: Setting) -> String? {
        return self.value(for: setting) as? String
    }

    public func integer(for setting: Setting) -> Int? {
        return self.value(for: setting) as? Int
    }

    public func bool(for setting: Setting) -> Bool? {
        return self.value(for: setting) as? Bool
    }

    public func modelID(for setting: Setting) -> ModelID? {
        guard let value = self.value(for: setting) as? String else {
            return nil
        }
        return ModelID(string: value)
    }

    public func set(_ modelID: ModelID?, for setting: Setting) {
        self.settings[setting] = modelID?.stringRepresentation
    }


    //MARK: - Plist Conversion
    public var plistRepresentation: [String: Any] {
        var plist = [String: Any]()
        self.settings.forEach { plist[$0.rawValue] = $1 }
        return plist
    }

    public func update(withPlist plist: [String: Any]) {
        var newSettings = [Setting: Any]()
        plist.forEach { newSettings[Setting(rawValue: $0)] = $1 }
        self.settings = newSettings
    }
}
