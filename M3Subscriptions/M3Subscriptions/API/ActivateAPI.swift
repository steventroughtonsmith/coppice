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
        case invalidRequest
        case loginFailed
        case multipleSubscriptions([SubscriptionPlan])
        case noSubscriptionFound
        case subscriptionExpired(Subscription?)
        case tooManyDevices([SubscriptionDevice])
        case generic(Error?)
    }

    func run(_ completion: @escaping (Result<ActivationResponse, Failure>) -> Void) {
        var json: [String: Any] = [
            "email": self.request.email,
            "password": self.request.password,
            "bundleID": self.request.bundleID,
            "deviceID": self.device.id,
            "deviceType": self.device.type.rawValue,
            "version": self.device.appVersion
        ]

        guard let deviceName = self.device.name else {
            completion(.failure(.invalidRequest))
            return
        }

        json["deviceName"] = deviceName

        if let subscriptionID = self.request.subscriptionID {
            json["subscriptionID"] = subscriptionID
        }

        if let deviceDeactivationToken = self.request.deviceDeactivationToken {
            json["deactivatingDeviceToken"] = deviceDeactivationToken
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .sortedKeys)
            networkAdapter.callAPI(endpoint: "activate", method: "POST", body: data) { result in
                switch result {
                case .success(let apiData):
                    completion(self.parse(apiData))
                case .failure(let error):
                    completion(.failure(.generic(error)))
                }
            }
        } catch let e {
            completion(.failure(.generic(e)))
        }
    }

    private func parse(_ data: APIData) -> Result<ActivationResponse, Failure> {
        switch data.response {
        case .active, .billingFailed:
            guard let response = ActivationResponse(payload: data.payload) else {
                return .failure(.generic(nil))
            }
            return .success(response)
        case .loginFailed:
            return .failure(.loginFailed)
        case .noSubscriptionFound:
            return .failure(.noSubscriptionFound)
        case .multipleSubscriptions:
            guard let jsonSubscriptions = data.payload["subscriptions"] as? [[String: Any]] else {
                return .failure(.generic(nil))
            }
            let subscriptions = jsonSubscriptions.compactMap { SubscriptionPlan(payload: $0) }
            return .failure(.multipleSubscriptions(subscriptions))
        case .expired:
            return .failure(.subscriptionExpired(Subscription(payload: data.payload)))
        case .tooManyDevices:
            guard let jsonDevices = data.payload["devices"] as? [[String: Any]] else {
                return .failure(.generic(nil))
            }
            let devices = jsonDevices.compactMap { SubscriptionDevice(payload: $0) }
            return .failure(.tooManyDevices(devices))
        default:
            return .failure(.generic(nil))
        }
    }
}
