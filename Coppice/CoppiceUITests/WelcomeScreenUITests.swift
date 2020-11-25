//
//  WelcomeScreenUITests.swift
//  CoppiceUITests
//
//  Created by Martin Pilkington on 24/11/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest

class WelcomeScreenUITests: BaseUITestCase {
    private func openWelcomeWindow() throws {
        let menuBarsQuery = XCUIApplication().menuBars
        menuBarsQuery.menuBarItems["Window"].click()
        menuBarsQuery.menuBarItems["Window"].menus.menuItems["Welcome to Coppice"].click()
    }

    func test_showsCorrectVersion() throws {
        try self.openWelcomeWindow()
        XCTAssertTrue(XCUIApplication().windows["Welcome to Coppice"].waitForExistence(timeout: 1))
    }

    func test_cantBeResized() throws {
        try self.openWelcomeWindow()
        XCTAssertFalse(XCUIApplication().windows["Welcome to Coppice"].buttons[XCUIIdentifierZoomWindow].isEnabled)
    }

    func test_newButtonCreatesNewDocument() throws {
        let app = XCUIApplication()
        let existingDocumentsCount = app.windows.matching(identifier: "DocumentWindow").count

        try self.openWelcomeWindow()
        XCUIApplication().windows["Welcome to Coppice"].buttons["New…"].click()

        let documentsCount = app.windows.matching(identifier: "DocumentWindow").count
        XCTAssertEqual(documentsCount, existingDocumentsCount + 1)
    }

    func test_openButtonOpensOpenPanel() throws {
        try self.openWelcomeWindow()
        XCUIApplication().windows["Welcome to Coppice"].buttons["Open…"].click()

        XCTAssertTrue(XCUIApplication().dialogs["Open"].waitForExistence(timeout: 1))
    }

    func test_tourButtonOpensTourWindow() throws {
        try self.openWelcomeWindow()
        XCUIApplication().windows["Welcome to Coppice"].buttons["Take Tour…"].click()

        XCTAssertTrue(XCUIApplication().windows["Tour"].waitForExistence(timeout: 1))
    }
}
