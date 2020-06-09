//
//  SubscriptionInfo.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public struct SubscriptionInfo {
    public enum State: Equatable {
        case unknown
        case active
        case billingFailed
        case deactivated

        static func state(forResponse response: String) -> State {
            if response == "active" {
                return .active
            }
            if response == "billing_failed" {
                return .billingFailed
            }
            if response == "deactivated" {
                return .deactivated
            }
            return .unknown
        }
    }

    public var state: State
    public var subscription: Subscription?

    init?(payload: [String: Any]) {
        guard
            let response = payload["response"] as? String,
            let subscription = Subscription(payload: payload) else {
                return nil
        }

        self.state = State.state(forResponse: response)
        self.subscription = subscription
    }
}
