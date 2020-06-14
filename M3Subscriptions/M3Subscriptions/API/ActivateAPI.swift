//
//  ActivateAPI.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

struct ActivateAPI {
    typealias APIResult = Result<ActivationResponse, Failure>

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

    func run(_ completion: @escaping (APIResult) -> Void) {
        var body: [String: String] = [
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

        body["deviceName"] = deviceName

        if let subscriptionID = self.request.subscriptionID {
            body["subscriptionID"] = subscriptionID
        }

        if let deviceDeactivationToken = self.request.deviceDeactivationToken {
            body["deactivatingDeviceToken"] = deviceDeactivationToken
        }

        self.networkAdapter.callAPI(endpoint: "activate", method: "POST", body: body) { result in
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
        case .active, .billingFailed:
            guard let response = ActivationResponse(data: data) else {
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
