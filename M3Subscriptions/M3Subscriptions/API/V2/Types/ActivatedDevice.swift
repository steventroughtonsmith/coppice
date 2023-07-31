//
//  ActivatedDevice.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 24/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V2 {
    public struct ActivatedDevice: Equatable {
        internal init(id: String, timestamp: TimeInterval, isCurrent: Bool, deviceName: String? = nil) {
            self.id = id
            self.timestamp = timestamp
            self.isCurrent = isCurrent
            self.deviceName = deviceName
        }

        init(apiDevice: [String: Any]) throws {
            guard
                let id = apiDevice["activationID"] as? String,
                let timestamp = apiDevice["activationTimestamp"] as? Int
            else {
                throw Error.invalidResponse
            }

            let isCurrent = (apiDevice["isCurrent"] as? Bool) ?? false
            self.id = id
            self.timestamp = TimeInterval(timestamp)
            self.isCurrent = isCurrent
            self.deviceName = apiDevice["name"] as? String
        }

        public var id: String
        public var timestamp: TimeInterval
        public var isCurrent: Bool

        public var deviceName: String?
    }
}
