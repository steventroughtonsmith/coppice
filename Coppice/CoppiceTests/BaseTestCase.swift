//
//  BaseTestCase.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 19/11/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Foundation
import XCTest

@testable import Coppice
@testable import M3Subscriptions

class BaseTestCase: XCTestCase {
    private var previousResponse: ActivationResponse?

    func configureForPro() throws {
        guard let url = self.testBundle.url(forResource: "test-api-response-success", withExtension: "json") else {
            XCTFail("Couldn't find api json")
            return
        }
        let apiResponseData = try Data(contentsOf: url)
        guard
            let json = try JSONSerialization.jsonObject(with: apiResponseData, options: []) as? [String: Any],
            let apiData = APIData(json: json)
        else {
            XCTFail("Couldn't convert to json dictionary")
            return
        }
        if self.previousResponse == nil {
            self.previousResponse = CoppiceSubscriptionManager.shared.activationResponse
        }
        CoppiceSubscriptionManager.shared.activationResponse = ActivationResponse(data: apiData)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        if let previousResponse = self.previousResponse {
            CoppiceSubscriptionManager.shared.activationResponse = previousResponse
        }
    }
}
