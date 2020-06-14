//
//  DeactivateAPI.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

struct DeactivateAPI {
    typealias APIResult = Result<ActivationResponse, Failure>
    let networkAdapter: NetworkAdapter
    let device: Device
    let token: String

    enum Failure: Error {
        case noDeviceFound
        case generic(Error?)
    }

    func run(_ completion: @escaping (APIResult) -> Void) {
        let body = [
            "deviceID": self.device.id,
            "token": self.token
        ]
        self.networkAdapter.callAPI(endpoint: "deactivate", method: "POST", body: body) { result in
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
        case .deactivated:
            guard let info = ActivationResponse(data: data) else {
                return .failure(.generic(nil))
            }
            return .success(info)
        case .noDeviceFound:
            return .failure(.noDeviceFound)
        default:
            return .failure(.generic(nil))
        }
    }
}
