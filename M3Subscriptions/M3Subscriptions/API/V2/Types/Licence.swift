//
//  Licence.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 24/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V2 {
    public struct Licence {
        public var licenceID: String
        public var subscription: Subscription
        public var expirationTimestamp: TimeInterval

        public init(url: URL) {
            self.licenceID = ""
            self.subscription = Subscription(id: "", expirationTimestamp: 0, name: "", renewalStatus: .unknown)
            self.expirationTimestamp = 0
        }
    }
}
