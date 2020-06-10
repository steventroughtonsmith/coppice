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
        case subscriptionExpired(Subscription?)
        case generic(Error?)
    }

    func run(_ completion: @escaping (Result<ActivationResponse, Failure>) -> Void) {
        var json = [
            "token": self.token,
            "deviceType": self.device.type.rawValue,
            "deviceID": self.device.id,
            "version": self.device.appVersion,
        ]
        if let deviceName = self.device.name {
            json["deviceName"] = deviceName
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .sortedKeys)
            networkAdapter.callAPI(endpoint: "check", method: "POST", body: data) { result in
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
        case .expired:
            return .failure(.subscriptionExpired(Subscription(payload: data.payload)))
        case .noDeviceFound:
            return .failure(.noDeviceFound)
        case .noSubscriptionFound:
            return .failure(.noSubscriptionFound)
        default:
            return .failure(.generic(nil))
        }
    }
}
