//
//  SubscriptionPlan.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public struct SubscriptionPlan: Equatable {
    public var id: String
    public var name: String
    public var expirationDate: Date
    public var maxDeviceCount: Int
    public var currentDeviceCount: Int

    init?(payload: [String: Any]) {
        guard
            let id = payload["id"] as? String,
            let name = payload["name"] as? String,
            let expirationDateString = payload["expirationDate"] as? String,
            let maxDeviceCount = payload["maxDeviceCount"] as? Int,
            let currentDeviceCount = payload["currentDeviceCount"] as? Int else {
                return nil
        }

        let formatter = ISO8601DateFormatter()
        guard let expirationDate = formatter.date(from: expirationDateString) else {
            return nil
        }

        self.id = id
        self.name = name
        self.expirationDate = expirationDate
        self.maxDeviceCount = maxDeviceCount
        self.currentDeviceCount = currentDeviceCount
    }
}
