//
//  SubscriptionPlan.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public struct Subscription: Equatable {
    public enum RenewalStatus: String {
        case unknown
        case renew = "renew"
        case cancelled = "cancelled"
        case failed = "failed"
    }

    public var id: String?
    public var name: String
    public var expirationDate: Date
    public var hasExpired: Bool
    public var renewalStatus: RenewalStatus
    public var maxDeviceCount: Int?
    public var currentDeviceCount: Int?

    init?(payload: [String: Any], hasExpired: Bool) {
        guard
            let name = payload["name"] as? String,
            let expirationDateString = payload["expirationDate"] as? String,
            let renewalStatusString = payload["renewalStatus"] as? String
        else {
                return nil
        }

        let formatter = ISO8601DateFormatter()
        guard let expirationDate = formatter.date(from: expirationDateString) else {
            return nil
        }

        self.id = payload["id"] as? String
        self.name = name
        self.expirationDate = expirationDate
        self.hasExpired = hasExpired
        self.renewalStatus = RenewalStatus(rawValue: renewalStatusString) ?? .unknown
        self.maxDeviceCount = payload["maxDeviceCount"] as? Int
        self.currentDeviceCount = payload["currentDeviceCount"] as? Int
    }
}
