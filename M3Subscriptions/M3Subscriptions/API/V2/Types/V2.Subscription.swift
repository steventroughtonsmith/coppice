//
//  Subscription.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 24/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V2 {
    public struct Subscription: Equatable {
        internal init(id: String, expirationTimestamp: TimeInterval, name: String, renewalStatus: RenewalStatus, maxDeviceCount: Int? = nil, currentDeviceCount: Int? = nil) {
            self.id = id
            self.expirationTimestamp = expirationTimestamp
            self.name = name
            self.renewalStatus = renewalStatus
            self.maxDeviceCount = maxDeviceCount
            self.currentDeviceCount = currentDeviceCount
        }

        init(apiSubscription: [String: Any]) throws {
            guard
                let id = apiSubscription["id"] as? String,
                let name = apiSubscription["name"] as? String,
                let expirationTimestamp = apiSubscription["expirationTimestamp"] as? Int,
                let rawRenewalStatus = apiSubscription["renewalStatus"] as? String
            else {
                throw Error.invalidResponse
            }

            self.id = id
            self.expirationTimestamp = TimeInterval(expirationTimestamp)
            self.name = name
            self.renewalStatus = RenewalStatus(rawValue: rawRenewalStatus) ?? .unknown

            self.maxDeviceCount = apiSubscription["maxDeviceCount"] as? Int
            self.currentDeviceCount = apiSubscription["currentDeviceCount"] as? Int
        }

        public var id: String
        public var expirationTimestamp: TimeInterval
        public var name: String
        public var renewalStatus: RenewalStatus

        public var maxDeviceCount: Int?
        public var currentDeviceCount: Int?
    }
}
