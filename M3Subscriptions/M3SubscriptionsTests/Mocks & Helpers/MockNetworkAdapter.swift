//
//  MockNetworkAdapter.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
@testable import M3Subscriptions

class MockNetworkAdapter: NetworkAdapter {
    var calledEndpoint: String?
    var calledMethod: String?
    var calledBody: [String: String]?

    var baseURL: URL {
        return URL(string: "http://localhost:8080/api")!
    }

    var version: String {
        return "v1"
    }

    var returnValue: APIData?
    var apiError: Error?
    func callAPI(endpoint: String, method: String = "POST", body: [String: String], headers: [String: String]?) throws -> APIData {
        self.calledEndpoint = endpoint
        self.calledMethod = method
        self.calledBody = body

        if let apiError {
            throw apiError
        }

        guard let returnValue else {
            throw NSError(domain: "com.mcubedsw.testing", code: -1234, userInfo: nil)
        }

        return returnValue
    }
}
