//
//  SubscriptionDevice.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public struct SubscriptionDevice: Equatable {
    public var deactivationToken: String
    public var name: String
    public var activationDate: Date

    init?(payload: [String: Any]) {
        guard
            let deactivationToken = payload["deactivationToken"] as? String,
            let name = payload["name"] as? String,
            let activationDateString = payload["activationDate"] as? String
        else {
                return nil
        }

        let formatter = ISO8601DateFormatter()
        guard let activationDate = formatter.date(from: activationDateString) else {
            return nil
        }

        self.deactivationToken = deactivationToken
        self.name = name
        self.activationDate = activationDate
    }
}
