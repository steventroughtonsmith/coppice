//
//  XCTestExtensions.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 07/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest

extension XCTestCase {
    func performAndWaitFor(_ description: String, timeout seconds: TimeInterval = 1, block: (XCTestExpectation) -> Void) {
        let expectation = self.expectation(description: description)
        block(expectation)
        self.wait(for: [expectation], timeout: seconds)
    }
}


