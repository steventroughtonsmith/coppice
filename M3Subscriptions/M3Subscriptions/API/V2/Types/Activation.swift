//
//  Activation.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 24/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V2 {
    public struct Activation {
        public var activationID: String
        public var subscription: Subscription
        public var deviceName: String
    }
}
