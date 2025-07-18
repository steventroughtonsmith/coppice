//
//  RequestTypes.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V1 {
    struct ActivationRequest {
        var email: String
        var password: String
        var bundleID: String
        var subscriptionID: String? = nil
        var deviceDeactivationToken: String? = nil
    }
}
