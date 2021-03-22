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
        #if TEST
        if let type = TEST_OVERRIDES.deviceType {
            return type
        }
        #endif
        return .mac
    }

    var id: String {
        #if TEST
        if let id = TEST_OVERRIDES.deviceID {
            return id
        }
        #endif

        let expert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        let number = IORegistryEntryCreateCFProperty(expert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
        IOObjectRelease(expert)
        return (number?.takeUnretainedValue() as? String) ?? ""
    }

    var appVersion: String {
        #if TEST
        if let version = TEST_OVERRIDES.appVersion {
            return version
        }
        #endif
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return "unknown"
        }
        return version
    }
}
