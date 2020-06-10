//
//  SubscriptionAPI.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

protocol SubscriptionAPI {
    func activate(_ request: ActivationRequest, device: Device, completion: @escaping (Result<ActivationResponse, ActivateAPI.Failure>) -> Void)
    func check(_ device: Device, token: String, completion: @escaping (Result<ActivationResponse, CheckAPI.Failure>) -> Void)
    func deactivate(_ device: Device, token: String, completion: @escaping (Result<ActivationResponse, DeactivateAPI.Failure>) -> Void)
}

class OnlineSubscriptionAPI: SubscriptionAPI {
    let networkAdapter: NetworkAdapter
    init(networkAdapter: NetworkAdapter) {
        self.networkAdapter = networkAdapter
    }

    func activate(_ request: ActivationRequest, device: Device, completion: @escaping (Result<ActivationResponse, ActivateAPI.Failure>) -> Void) {
        let activation = ActivateAPI(networkAdapter: self.networkAdapter, request: request, device: device)
        activation.run(completion)
    }

    func check(_ device: Device, token: String, completion: @escaping (Result<ActivationResponse, CheckAPI.Failure>) -> Void) {
        let check = CheckAPI(networkAdapter: self.networkAdapter, device: device, token: token)
        check.run(completion)
    }

    func deactivate(_ device: Device, token: String, completion: @escaping (Result<ActivationResponse, DeactivateAPI.Failure>) -> Void) {
        let deactivate = DeactivateAPI(networkAdapter: self.networkAdapter, device: device, token: token)
        deactivate.run(completion)
    }
}
