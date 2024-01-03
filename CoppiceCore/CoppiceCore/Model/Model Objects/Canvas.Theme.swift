//
//  Canvas.Theme.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 02/01/2024.
//

import Foundation
import M3Data

extension Canvas {
    public enum Theme: String, CaseIterable, PlistConvertable {
        case auto
        case dark
        case light

        public var localizedName: String {
            switch self {
            case .auto: return NSLocalizedString("Automatic", comment: "Automatic theme name")
            case .dark: return NSLocalizedString("Dark", comment: "Dark theme name")
            case .light: return NSLocalizedString("Light", comment: "Light theme name")
            }
        }

        public func toPlistValue() throws -> PlistValue {
            return self.rawValue
        }

        public static func fromPlistValue(_ plistValue: PlistValue) throws -> Theme {
            guard
                let value = plistValue as? String,
                let theme = Theme(rawValue: value)
            else {
                throw PlistConvertableError.invalidConversionFromPlistValue
            }
            return theme
        }
    }
}

