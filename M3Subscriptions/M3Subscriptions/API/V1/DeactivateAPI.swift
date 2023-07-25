//
//  DeactivateAPIV1.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V1 {
    struct DeactivateAPI {
        let networkAdapter: NetworkAdapter
        let device: Device
        let token: String

        enum Failure: Error {
            case noDeviceFound
            case generic(Error?)
        }

        func run() async throws -> ActivationResponse {
            #if DEBUG
            var body = [
                "deviceID": self.device.id,
                "token": self.token,
            ]
            if let debugString = APIDebugManager.shared.deactivateDebugString {
                body["debug"] = debugString
            }
            #else
            let body = [
                "deviceID": self.device.id,
                "token": self.token,
            ]
            #endif

            let data: APIData
            do {
                 data = try await self.networkAdapter.callAPI(endpoint: "deactivate", method: "POST", body: body)
            } catch {
                throw Failure.generic(error)
            }

            return try self.parse(data)
    }

        private func parse(_ data: APIData) throws -> ActivationResponse {
            switch data.response {
            case .deactivated:
                guard let info = ActivationResponse(data: data) else {
                    throw Failure.generic(nil)
                }
                return info
            case .noDeviceFound:
                return ActivationResponse.deactivated() //If no device is found then we don't want to be activated anyway
            default:
                throw Failure.generic(nil)
            }
        }
    }
}
