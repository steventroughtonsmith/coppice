//
//  CoppiceUITests.swift
//  CoppiceUITests
//
//  Created by Martin Pilkington on 03/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest

class CoppiceUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let app = XCUIApplication()
        let menuBarsQuery = app.menuBars
        menuBarsQuery.menuBarItems["Window"].click()
        menuBarsQuery/*@START_MENU_TOKEN@*/.menuItems["Welcome to Coppice"]/*[[".menuBarItems[\"Window\"]",".menus.menuItems[\"Welcome to Coppice\"]",".menuItems[\"Welcome to Coppice\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.click()
        app.windows["Welcome to Coppice"].buttons["New…"].click()

        XCTAssertTrue(app.windows["Untitled"].waitForExistence(timeout: 1))
    }

}
