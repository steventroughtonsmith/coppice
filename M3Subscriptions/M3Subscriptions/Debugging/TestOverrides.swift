//
//  TestOverrides.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 14/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//
#if TEST

import Foundation

class TEST_OVERRIDES {
    static var baseURL: URL?
    static var apiVersion: String?
    static var deviceType: Device.DeviceType?
    static var deviceID: String?
    static var appVersion: String?
    static var bundleID: String?
    static var publicKey: String?
}

#endif
