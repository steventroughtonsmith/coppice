//
//  ActivateAPI.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

struct ActivateAPI {
    let networkAdapter: NetworkAdapter
    let request: ActivationRequest
    let device: Device

    enum Failure: Error {
        case loginFailed
        case multipleSubscriptions([SubscriptionPlan])
        case noSubscriptionFound
        case subscriptionExpired(Subscription)
        case tooManyDevices([SubscriptionDevice])
    }

    func run(_ completion: (Result<SubscriptionInfo, Failure>) -> Void) {

    }
}
