//
//  Mocking.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 27/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
import Foundation

class MockDetails<Arguments, Return> {
    var expectation: XCTestExpectation?
    var arguments = [Arguments]()
    var returnValue: Return?

    private(set) var wasCalled: Bool = false

    @discardableResult func called(withArguments argument: Arguments) -> Return? {
        self.arguments.append(argument)
        self.wasCalled = true
        self.expectation?.fulfill()
        return self.returnValue
    }
}

extension MockDetails where Arguments == Void {
    @discardableResult func called() -> Return? {
        self.expectation?.fulfill()
        self.wasCalled = true
        return self.returnValue
    }
}
