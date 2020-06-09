//
//  Device.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

struct Device {
    enum DeviceType: String {
        case mac
        case ipad
    }
    var name: String?

    var type: DeviceType {
        return .mac
    }

    var id: String {
        let expert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        let number = IORegistryEntryCreateCFProperty(expert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
        IOObjectRelease(expert)
        return (number?.takeUnretainedValue() as? String) ?? ""
    }

    var appVersion: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return "unknown"
        }
        return version
    }
}
