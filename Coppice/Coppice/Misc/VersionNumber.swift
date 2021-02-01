//
//  VersionNumber.swift
//  Coppice
//
//  Created by Martin Pilkington on 01/02/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Foundation

struct VersionNumber {
    static var appVersion: VersionNumber? {
        guard let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return nil
        }

        return VersionNumber.with(versionString)
    }

    static func with(_ versionString: String) -> VersionNumber? {
        let components = versionString.components(separatedBy: ".")
        guard components.count >= 2 else {
            return nil
        }

        guard
            let year = Int(components[0]),
            let version = Int(components[1])
        else {
            return nil
        }

        var bugfix = 0
        var subversion = ""
        if (components.count >= 3) {
            let lastComponents = components[2].components(separatedBy: " ")
            bugfix = Int(lastComponents[0]) ?? 0
            if (lastComponents.count > 1) {
                subversion = lastComponents[1...].joined(separator: " ")
            }
        }

        return VersionNumber(year: year, version: version, bugfix: bugfix, subversion: subversion)
    }

    var year: Int
    var version: Int
    var bugfix: Int
    var subversion: String
}
