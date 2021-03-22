//
//  BaseUITestCase.swift
//  CoppiceUITests
//
//  Created by Martin Pilkington on 24/11/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest

class BaseUITestCase: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments.append("-CoppiceDisableStateRestoration")
        app.launchArguments.append("true")
        try self.performAdditionalSetup(on: app)
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launch()

        // In UI tests it’s important to set the initial state required for your tests before they run. The setUp method is a good place to do this.
    }

    func performAdditionalSetup(on app: XCUIApplication) throws {}

    override func tearDownWithError() throws {}
}
