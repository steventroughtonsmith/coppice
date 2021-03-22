//
//  Mocking.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 27/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import XCTest

class MockDetails<Arguments, Return> {
    var expectation: XCTestExpectation?
    var arguments = [Arguments]()
    var returnValue: Return?
    var method: ((Arguments) -> Return)?

    private(set) var wasCalled: Bool = false

    @discardableResult func called(withArguments arguments: Arguments) -> Return? {
        self.arguments.append(arguments)
        self.wasCalled = true
        self.expectation?.fulfill()
        if let method = self.method {
            return method(arguments)
        }
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
