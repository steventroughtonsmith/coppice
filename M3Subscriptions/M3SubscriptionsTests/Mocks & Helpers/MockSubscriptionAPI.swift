//
//  MockSubscriptionAPI.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 11/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
@testable import M3Subscriptions

class MockSubscriptionAPI: SubscriptionAPI {
    var calledMethod: String?
    var requestArgument: ActivationRequest?
    var deviceArgument: Device?
    var tokenArgument: String?

    var activateResponse: ActivateAPI.APIResult?
    var checkResponse: CheckAPI.APIResult?
    var deactivateResponse: DeactivateAPI.APIResult?

    func activate(_ request: ActivationRequest, device: Device, completion: @escaping (ActivateAPI.APIResult) -> Void) {
        self.calledMethod = "activate"
        self.requestArgument = request
        self.deviceArgument = device
        let response = self.activateResponse ?? .failure(.generic(nil))
        completion(response)
    }

    func check(_ device: Device, token: String, completion: @escaping (CheckAPI.APIResult) -> Void) {
        self.calledMethod = "check"
        self.deviceArgument = device
        self.tokenArgument = token
        let response = self.checkResponse ?? .failure(.generic(nil))
        completion(response)
    }

    func deactivate(_ device: Device, token: String, completion: @escaping (DeactivateAPI.APIResult) -> Void) {
        self.calledMethod = "deactivate"
        self.deviceArgument = device
        self.tokenArgument = token
        let response = self.deactivateResponse ?? .failure(.generic(nil))
        completion(response)
    }

    func reset() {
        self.calledMethod = nil
        self.requestArgument = nil
        self.deviceArgument = nil
        self.tokenArgument = nil

        self.activateResponse = nil
        self.checkResponse = nil
        self.deactivateResponse = nil
    }
}
