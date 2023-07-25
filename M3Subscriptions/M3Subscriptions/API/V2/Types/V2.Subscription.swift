//
//  Subscription.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 24/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V2 {
    public struct Subscription {
        public enum RenewalStatus: String {
            case unknown
            case renew
            case cancelled
            case failed
        }

        internal init(id: String, expirationTimestamp: TimeInterval, name: String, renewalStatus: RenewalStatus, maxDeviceCount: Int? = nil, currentDeviceCount: Int? = nil) {
            self.id = id
            self.expirationTimestamp = expirationTimestamp
            self.name = name
            self.renewalStatus = renewalStatus
            self.maxDeviceCount = maxDeviceCount
            self.currentDeviceCount = currentDeviceCount
        }
        
        public var id: String
        public var expirationTimestamp: TimeInterval
        public var name: String
        public var renewalStatus: RenewalStatus

        public var maxDeviceCount: Int?
        public var currentDeviceCount: Int?
    }
}
