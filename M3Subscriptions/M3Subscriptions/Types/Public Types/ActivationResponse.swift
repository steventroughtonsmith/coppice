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

        static func state(forResponse response: APIData.Response) -> State {
            switch response {
            case .active:
                return .active
            case .billingFailed:
                return .billingFailed
            case .deactivated:
                return .deactivated
            default:
                return .unknown
            }
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
    public var payload: [String: Any]
    public var signature: String

    static func deactivated() -> ActivationResponse? {
        guard let data = APIData(json: ["payload": ["response": "deactivated"], "signature": "2FK5GJmiT6C4aLZTWq8R0d+sEXWLORh0iQnHKritAfySu+W/wvhlblSXy2hUqKiRjHuOWIcz+f4wjMBTuoki7SAV78LElaPxor2hIEB8eqtaX3P+foAY0s/XpnlXWXg7YrUD53YsCRaZR47rLfLBsS9iCcKPRIWz8xXgyev4sbwt2Td3EvFukIasGRsTMe9Jvt0Qi1euyN8yKB7kYPqH43Oaua0rdxUN8BjoiTmUHwq7Z3gBn2+3K7DzhfRoYY7AAqZDO9FwDrcrwI5b5M5eXG9ZLSCdYJadeW6VfFLc/6Mtnt59EHzazbmzkfUwYw0y0+Cbvj8eb/+eiN8a/ALgBg=="]) else {
            return nil
        }
        return ActivationResponse(data: data)
    }

    init?(url: URL) {
        guard
            let data = try? Data(contentsOf: url),
            let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
            let apiData = APIData(json: json) else {
            return nil
        }

        self.init(data: apiData)
    }

    init?(data: APIData) {
        let state = State.state(forResponse: data.response)
        let subscription = Subscription(payload: data.payload)
        if state.requiresSubscription && (subscription == nil) {
            return nil
        }

        self.state = state
        self.token = data.payload["token"] as? String
        self.subscription = subscription
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
}
