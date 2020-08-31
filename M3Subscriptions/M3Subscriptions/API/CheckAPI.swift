//
//  CheckAPI.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

struct CheckAPI {
    typealias APIResult = Result<ActivationResponse, Failure>

    let networkAdapter: NetworkAdapter
    let device: Device
    let token: String

    enum Failure: Error {
        case noDeviceFound
        case noSubscriptionFound
        case subscriptionExpired(Subscription?)
        case generic(Error?)
    }

    func run(_ completion: @escaping (APIResult) -> Void) {
        var body = [
            "token": self.token,
            "deviceType": self.device.type.rawValue,
            "deviceID": self.device.id,
            "version": self.device.appVersion,
        ]
        if let deviceName = self.device.name {
            body["deviceName"] = deviceName
        }
        self.networkAdapter.callAPI(endpoint: "check", method: "POST", body: body) { result in
            switch result {
            case .success(let apiData):
                completion(self.parse(apiData))
            case .failure(let error):
                completion(.failure(.generic(error)))
            }
        }
    }

    private func parse(_ data: APIData) -> APIResult {
        switch data.response {
        case .active, .expired:
            guard let response = ActivationResponse(data: data) else {
                return .failure(.generic(nil))
            }
            return .success(response)
        case .noDeviceFound:
            return .failure(.noDeviceFound)
        case .noSubscriptionFound:
            return .failure(.noSubscriptionFound)
        default:
            return .failure(.generic(nil))
        }
    }
}
