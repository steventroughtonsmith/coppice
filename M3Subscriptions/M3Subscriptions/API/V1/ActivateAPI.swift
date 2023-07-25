//
//  ActivateAPIV1.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V1 {
    struct ActivateAPI {
        let networkAdapter: NetworkAdapter
        let request: ActivationRequest
        let device: Device
        
        enum Failure: Error {
            case invalidRequest
            case loginFailed
            case multipleSubscriptions([Subscription])
            case noSubscriptionFound
            case subscriptionExpired(Subscription?)
            case tooManyDevices([SubscriptionDevice])
            case generic(Error?)
        }
        
        func run() async throws -> ActivationResponse {
            var body: [String: String] = [
                "email": self.request.email,
                "password": self.request.password,
                "bundleID": self.request.bundleID,
                "deviceID": self.device.id,
                "deviceType": self.device.type.rawValue,
                "version": self.device.appVersion,
            ]
            
            guard let deviceName = self.device.name else {
                throw Failure.invalidRequest
            }
            
            body["deviceName"] = deviceName
            
            if let subscriptionID = self.request.subscriptionID {
                body["subscriptionID"] = subscriptionID
            }
            
            if let deviceDeactivationToken = self.request.deviceDeactivationToken {
                body["deactivatingDeviceToken"] = deviceDeactivationToken
            }
            
#if DEBUG
            if let debugString = APIDebugManager.shared.activateDebugString {
                body["debug"] = debugString
            }
#endif
            
            let data: APIData
            do {
                data = try await self.networkAdapter.callAPI(endpoint: "activate", method: "POST", body: body)
            } catch {
                throw Failure.generic(error)
            }
            
            return try self.parse(data)
        }
        
        private func parse(_ data: APIData) throws -> ActivationResponse {
            switch data.response {
            case .active:
                guard let response = ActivationResponse(data: data) else {
                    throw Failure.generic(nil)
                }
                return response
            case .expired:
                guard let jsonSubscription = data.payload["subscription"] as? [String: Any] else {
                    throw Failure.generic(nil)
                }
                throw Failure.subscriptionExpired(Subscription(payload: jsonSubscription, hasExpired: true))
            case .loginFailed:
                throw Failure.loginFailed
            case .noSubscriptionFound:
                throw Failure.noSubscriptionFound
            case .multipleSubscriptions:
                guard let jsonSubscriptions = data.payload["subscriptions"] as? [[String: Any]] else {
                    throw Failure.generic(nil)
                }
                let subscriptions = jsonSubscriptions.compactMap { Subscription(payload: $0, hasExpired: false) }
                throw Failure.multipleSubscriptions(subscriptions)
            case .tooManyDevices:
                guard let jsonDevices = data.payload["devices"] as? [[String: Any]] else {
                    throw Failure.generic(nil)
                }
                let devices = jsonDevices.compactMap { SubscriptionDevice(payload: $0) }
                throw Failure.tooManyDevices(devices)
            default:
                throw Failure.generic(nil)
            }
        }
    }
}
