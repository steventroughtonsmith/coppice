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

    func run() async throws -> ActivationResponse {
        var body = [
            "token": self.token,
            "deviceType": self.device.type.rawValue,
            "deviceID": self.device.id,
            "version": self.device.appVersion,
        ]
        if let deviceName = self.device.name {
            body["deviceName"] = deviceName
        }

        #if DEBUG
        if let debugString = APIDebugManager.shared.checkDebugString {
            body["debug"] = debugString
        }
        #endif

        let data: APIData
        do {
            data = try await self.networkAdapter.callAPI(endpoint: "check", method: "POST", body: body)
        } catch {
            throw Failure.generic(error)
        }

        return try self.parse(data)
    }

    private func parse(_ data: APIData) throws -> ActivationResponse {
        switch data.response {
        case .active, .expired:
            guard let response = ActivationResponse(data: data) else {
                throw Failure.generic(nil)
            }
            return response
        case .noDeviceFound:
            throw Failure.noDeviceFound
        case .noSubscriptionFound:
            throw Failure.noSubscriptionFound
        default:
            throw Failure.generic(nil)
        }
    }
}
