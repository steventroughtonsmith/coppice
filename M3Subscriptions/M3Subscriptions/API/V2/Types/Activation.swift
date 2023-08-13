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
        public var secondaryState: SecondaryState = .none
        var apiData: APIData

        init(url: URL) throws {
            let data = try Data(contentsOf: url)
            guard 
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let apiData = APIData(json: json)
            else {
                throw Error.notActivated
            }
            try self.init(apiData: apiData)
        }

        init(apiData: APIData) throws {
            let payload = apiData.payload
            guard
                let activationID = payload["activationID"] as? String,
                let device = payload["device"] as? [String: String],
                let deviceName = device["name"],
                let apiSubscription = payload["subscription"] as? [String: Any]
            else {
                throw Error.invalidResponse
            }

            let subscription = try Subscription(apiSubscription: apiSubscription)
            self.subscription = subscription
            self.activationID = activationID
            self.deviceName = deviceName
            self.apiData = apiData
        }

        func write(to url: URL) throws {
            try self.apiData.write(to: url)
        }

        var isTrial: Bool {
            return self.subscription.renewalStatus == .trial
        }
    }
}

extension API.V2.Activation {
    public enum SecondaryState {
        case none
        case justExpired
        case justRenewed
        case billingFailed
    }
}
