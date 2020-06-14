//
//  SubscriptionFunctionalTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 13/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions
import DVR

class SubscriptionFunctionalTests: XCTestCase {
    var licenceURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.licenceURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("com.mcubed.subscriptions").appendingPathComponent("functional-licence.txt")
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func test_activate_initialActivation() throws {
        let session = Session(cassetteName: "Subscriptions")
        let api = OnlineSubscriptionAPI(networkAdapter: URLSessionNetworkAdapter(session: session))
        let controller = SubscriptionController(licenceURL: licenceURL, subscriptionAPI: api)

        let delegate = FunctionalSubscriptionDelegate()
        controller.delegate = delegate

        self.performAndWaitFor("Delegate called", timeout: 5) { (expectation) in
            delegate.subscriptionExpectation = expectation
            controller.activate(withEmail: "test@mcubedsw.com", password: "1234567890")
        }
    }
}

class FunctionalSubscriptionDelegate: SubscriptionControllerDelegate {
    var activationResponse: ActivationResponse?
    var subscriptionExpectation: XCTestExpectation?
    func didChangeSubscription(_ info: ActivationResponse, in controller: SubscriptionController) {
        self.activationResponse = info
        subscriptionExpectation?.fulfill()
    }

    var error: NSError?
    var errorExpectation: XCTestExpectation?
    func didEncounterError(_ error: NSError, in controller: SubscriptionController) {
        self.error = error
        errorExpectation?.fulfill()
    }
}
