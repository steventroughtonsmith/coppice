//
//  SparkleDelegate.swift
//  Coppice
//
//  Created by Martin Pilkington on 27/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Sparkle

class SparkleDelegate: NSObject, SPUUpdaterDelegate {
    func allowedSystemProfileKeys(for updater: SPUUpdater) -> [String] {
        return ["osVersion", "cputype", "model", "lang", "appVersion"]
    }

    func feedParameters(for updater: SPUUpdater, sendingSystemProfile sendingProfile: Bool) -> [[String : String]] {
        if sendingProfile, let bundleID = Bundle.main.bundleIdentifier {
            return [["key": "bundleID", "value": bundleID, "displayKey": "Bundle ID", "displayValue": bundleID]]
        }
        return []
    }
    
}
