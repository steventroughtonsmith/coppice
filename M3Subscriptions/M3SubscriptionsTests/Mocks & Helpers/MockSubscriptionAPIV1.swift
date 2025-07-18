//
//  MockSubscriptionAPIV1.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 11/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
@testable import M3Subscriptions

class MockSubscriptionAPIV1: SubscriptionAPIV1 {
    typealias ActivationResponse = API.V1.ActivationResponse
    typealias ActivationRequest = API.V1.ActivationRequest

    var calledMethod: String?
    var requestArgument: ActivationRequest?
    var deviceArgument: Device?
    var tokenArgument: String?

    var checkReturnValue: ActivationResponse?
    var checkError: CheckAPI.Failure?
    func check(_ device: Device, token: String) async throws -> ActivationResponse {
        self.calledMethod = "check"
        self.deviceArgument = device
        self.tokenArgument = token
        if let checkError {
            throw checkError
        }

        guard let checkReturnValue else {
            throw NSError(domain: "com.mcubedsw.testing", code: -1234, userInfo: nil)
        }

        return checkReturnValue
    }

    var deactivateReturnValue: ActivationResponse?
    var deactivateError: DeactivateAPI.Failure?
    func deactivate(_ device: Device, token: String) async throws -> ActivationResponse {
        self.calledMethod = "deactivate"
        self.deviceArgument = device
        self.tokenArgument = token
        if let deactivateError {
            throw deactivateError
        }

        guard let deactivateReturnValue else {
            throw NSError(domain: "com.mcubedsw.testing", code: -1234, userInfo: nil)
        }

        return deactivateReturnValue
    }

    func reset() {
        self.calledMethod = nil
        self.requestArgument = nil
        self.deviceArgument = nil
        self.tokenArgument = nil

        self.checkReturnValue = nil
        self.checkError = nil
        self.deactivateReturnValue = nil
        self.deactivateError = nil
    }
}
