//
//  HelpViewerUITests.swift
//  CoppiceUITests
//
//  Created by Martin Pilkington on 28/11/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest

class HelpViewerUITests: BaseUITestCase {
    private func openHelpWindow() throws {
        let menuBarsQuery = XCUIApplication().menuBars
        menuBarsQuery.menuBarItems["Help"].click()
        menuBarsQuery.menuBarItems["Help"].menus.menuItems["Coppice Help"].click()
    }

    private func isShowingTopic(withTitle title: String) -> Bool {
        return XCUIApplication().windows["Coppice Help"].webViews.element(boundBy: 0).staticTexts[title].exists
    }

    func test_openingHelpFirstTimeOpensWelcomeScreen() throws {
        try self.openHelpWindow()

        XCTAssertTrue(self.isShowingTopic(withTitle: "Coppice User Guide"))
    }

    func test_clickingOnTopicShowsTopic() throws {
        try self.openHelpWindow()

        XCUIApplication().windows["Coppice Help"].outlines.cells.staticTexts["Create a Blank Page"].click()
        XCTAssertTrue(self.isShowingTopic(withTitle: "Create a Blank Page"))
    }

    func test_clickingHomeButtonGoesBackToWelcomePage() throws {
        try self.openHelpWindow()

        let coppiceHelpWindow = XCUIApplication().windows["Coppice Help"]
        coppiceHelpWindow.outlines.cells.staticTexts["Customise the Toolbar"].click()
        XCTAssertTrue(self.isShowingTopic(withTitle: "Customise the Toolbar"))

        coppiceHelpWindow.toolbars.buttons["Home"].click()
        XCTAssertTrue(self.isShowingTopic(withTitle: "Coppice User Guide"))
    }

    func test_sidebarButtonTogglesSidebar() throws {
        try self.openHelpWindow()

        let coppiceHelpWindow = XCUIApplication().windows["Coppice Help"]
        let sidebarButton = coppiceHelpWindow.toolbars.buttons["Sidebar"]
        sidebarButton.click()

        let splitter = coppiceHelpWindow.splitters.element(boundBy: 0)
        XCTAssertLessThanOrEqual(try XCTUnwrap(splitter.value as? Int), 0)

        sidebarButton.click()
        XCTAssertGreaterThan(try XCTUnwrap(splitter.value as? Int), 0)
    }
}
