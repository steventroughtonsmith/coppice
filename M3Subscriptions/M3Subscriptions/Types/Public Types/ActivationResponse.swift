//
//  ActivationResponse.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public struct ActivationResponse {
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

        var requiresSubscription: Bool {
            switch self {
            case .active, .billingFailed:
                return true
            default:
                return false
            }
        }
    }

    public var state: State
    public var token: String?
    public var subscription: Subscription?

    init?(payload: [String: Any]) {
        guard let response = payload["response"] as? String else {
            return nil
        }

        let state = State.state(forResponse: response)
        let subscription = Subscription(payload: payload)
        if state.requiresSubscription && (subscription == nil) {
            return nil
        }

        self.state = state
        self.token = payload["token"] as? String
        self.subscription = subscription
    }
}
