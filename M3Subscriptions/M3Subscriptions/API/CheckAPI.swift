//
//  CheckAPI.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

struct CheckAPI {
    let networkAdapter: NetworkAdapter
    let device: Device
    let token: String

    enum Failure: Error {
        case noDeviceFound
        case noSubscriptionFound
        case subscriptionExpired(Subscription)
    }

    func run(_ completion: (Result<SubscriptionInfo, Failure>) -> Void) {

    }
}
