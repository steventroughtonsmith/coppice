//
//  ActivatedDevice.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 24/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V2 {
    public struct ActivatedDevice {
        internal init(id: String, timestamp: TimeInterval, isCurrent: Bool, deviceName: String? = nil) {
            self.id = id
            self.timestamp = timestamp
            self.isCurrent = isCurrent
            self.deviceName = deviceName
        }

        public var id: String
        public var timestamp: TimeInterval
        public var isCurrent: Bool

        public var deviceName: String?
    }
}
