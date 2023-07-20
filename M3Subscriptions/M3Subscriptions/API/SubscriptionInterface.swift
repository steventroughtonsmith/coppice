//
//  SubscriptionAPI.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

protocol SubscriptionAPI {
    func activate(_ request: ActivationRequest, device: Device) async throws -> ActivationResponse
    func check(_ device: Device, token: String) async throws -> ActivationResponse
    func deactivate(_ device: Device, token: String) async throws -> ActivationResponse
}

class OnlineSubscriptionAPI: SubscriptionAPI {
    let networkAdapter: NetworkAdapter
    init(networkAdapter: NetworkAdapter) {
        self.networkAdapter = networkAdapter
    }

    //TODO: Make Async
    func activate(_ request: ActivationRequest, device: Device) async throws -> ActivationResponse {
        let activation = ActivateAPI(networkAdapter: self.networkAdapter, request: request, device: device)
        return try await activation.run()
    }

    //TODO: Make Async
    func check(_ device: Device, token: String) async throws -> ActivationResponse {
        let check = CheckAPI(networkAdapter: self.networkAdapter, device: device, token: token)
        return try await check.run()
    }

    //TODO: Make Async
    func deactivate(_ device: Device, token: String) async throws -> ActivationResponse {
        let deactivate = DeactivateAPI(networkAdapter: self.networkAdapter, device: device, token: token)
        return try await deactivate.run()
    }
}
