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
    private var previousState: CoppiceSubscriptionManager.State?

    func configureForPro() throws {
        if self.previousState == nil {
            self.previousState = CoppiceSubscriptionManager.shared.state
        }
        CoppiceSubscriptionManager.shared.debug_updateState(.enabled)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        if let previousState = self.previousState {
            CoppiceSubscriptionManager.shared.debug_updateState(previousState)
        }
    }
}
