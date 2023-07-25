//
//  Activations.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

protocol SubscriptionAPIV1 {
    func activate(_ request: API.V1.ActivationRequest, device: Device) async throws -> API.V1.ActivationResponse
    func check(_ device: Device, token: String) async throws -> API.V1.ActivationResponse
    func deactivate(_ device: Device, token: String) async throws -> API.V1.ActivationResponse
}

extension API.V1 {
    class Activations: SubscriptionAPIV1 {
        let networkAdapter: NetworkAdapter
        init(networkAdapter: NetworkAdapter) {
            self.networkAdapter = networkAdapter
        }

        func activate(_ request: ActivationRequest, device: Device) async throws -> ActivationResponse {
            let activation = ActivateAPI(networkAdapter: self.networkAdapter, request: request, device: device)
            return try await activation.run()
        }

        func check(_ device: Device, token: String) async throws -> ActivationResponse {
            let check = CheckAPI(networkAdapter: self.networkAdapter, device: device, token: token)
            return try await check.run()
        }

        func deactivate(_ device: Device, token: String) async throws -> ActivationResponse {
            let deactivate = DeactivateAPI(networkAdapter: self.networkAdapter, device: device, token: token)
            return try await deactivate.run()
        }
    }
}
