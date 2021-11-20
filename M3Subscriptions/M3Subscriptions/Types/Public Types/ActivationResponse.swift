//
//  ActivationResponse.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public struct ActivationResponse {
    public var token: String?
    public var subscription: Subscription?
    public var previousSubscription: Subscription?
    public var deviceName: String?
    public var payload: [String: Any]
    public var signature: String
    private var response: APIData.Response


    /// Has the device being activated on a subscription
    public var deviceIsActivated: Bool {
        return (self.token != nil)
    }

    /// Is the user's subscription active and therefore should all functionality be unlocked
    public var isActive: Bool {
        return (self.response == .active) && self.deviceIsActivated && (self.subscription?.hasExpired == false)
    }

    public static func deactivated() -> Self {
        return ActivationResponse()
    }

    private init() {
        self.response = .deactivated
        self.payload = ["response": "deactivated"]
        self.signature = ""
    }

    init?(url: URL) {
        guard
            let data = try? Data(contentsOf: url),
            let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
            let apiData = APIData(json: json)
        else {
            return nil
        }

        self.init(data: apiData)
    }

    init?(data: APIData) {
        self.response = data.response

        var subscription: Subscription? = nil
        if let subscriptionPayload = data.payload["subscription"] as? [String: Any] {
            subscription = Subscription(payload: subscriptionPayload, hasExpired: (data.response == .expired))
        }
        //We need a subscription if we're active or have expired
        if (data.response == .active || data.response == .expired) && (subscription == nil) {
            return nil
        }

        self.token = data.payload["token"] as? String
        self.subscription = subscription
        self.deviceName = (data.payload["device"] as? [String: Any])?["name"] as? String
        self.payload = data.payload
        self.signature = data.signature
    }

    func write(to url: URL) {
        let json: [String: Any] = ["payload": self.payload, "signature": self.signature]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .sortedKeys) else {
            return
        }
        try? data.write(to: url)
    }

    mutating func reevaluateSubscription() {
        guard var subscription = self.subscription else {
            return
        }
        subscription.hasExpired = subscription.expirationDate < Date()
        self.subscription = subscription
    }
}
