//
//  SubscriptionAPI.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

protocol SubscriptionAPIV1 {
    func activate(_ request: ActivationRequest, device: Device) async throws -> ActivationResponse
    func check(_ device: Device, token: String) async throws -> ActivationResponse
    func deactivate(_ device: Device, token: String) async throws -> ActivationResponse
}

extension API.Subscription {
    class V1: SubscriptionAPIV1 {
        let networkAdapter: NetworkAdapter
        init(networkAdapter: NetworkAdapter) {
            self.networkAdapter = networkAdapter
        }

        func activate(_ request: ActivationRequest, device: Device) async throws -> ActivationResponse {
            let activation = ActivateAPIV1(networkAdapter: self.networkAdapter, request: request, device: device)
            return try await activation.run()
        }

        func check(_ device: Device, token: String) async throws -> ActivationResponse {
            let check = CheckAPIV1(networkAdapter: self.networkAdapter, device: device, token: token)
            return try await check.run()
        }
         
        func deactivate(_ device: Device, token: String) async throws -> ActivationResponse {
            let deactivate = DeactivateAPIV1(networkAdapter: self.networkAdapter, device: device, token: token)
            return try await deactivate.run()
        }
    }
}
