//
//  Subscription.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public struct Subscription: Equatable {
    public var name: String
    public var expirationDate: Date

    init?(payload: [String: Any]) {
        guard let name = payload["subscriptionName"] as? String,
            let expirationDateString = payload["expirationDate"] as? String else {
                return nil
        }

        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: expirationDateString) else {
            return nil
        }
        self.name = name
        self.expirationDate = date
    }
}


