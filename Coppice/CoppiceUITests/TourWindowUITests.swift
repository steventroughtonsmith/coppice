//
//  TourWindowUITests.swift
//  CoppiceUITests
//
//  Created by Martin Pilkington on 25/11/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest

class TourWindowUITests: BaseUITestCase {

    private func openTourWindow() throws {
        let menuBarsQuery = XCUIApplication().menuBars
        menuBarsQuery.menuBarItems["Help"].click()
        menuBarsQuery.menuBarItems["Help"].menus.menuItems["Tour Coppice…"].click()
    }

    func test_hoveringOverSidebarGraphicUpdatesText() throws {
        try self.openTourWindow()

        let window = XCUIApplication().windows["TourWindow"]

        window.images["TourGraphicSidebar"].hover()

        let label = try XCTUnwrap(window.staticTexts["TourGraphicDetailsLabel"].value as? String)
        XCTAssertTrue(label.hasPrefix("Sidebar"))
    }

    func test_hoveringOverToolbarGraphicUpdatesText() throws {
        try self.openTourWindow()
        XCTFail()
    }

    func test_hoveringOverInspectorGraphicUpdatesText() throws {
        try self.openTourWindow()
        XCTFail()
    }

    func test_hoveringOverEditorGraphicHighlightsText() throws {
        try self.openTourWindow()
        XCTFail()
    }

    func test_canMoveForwardAndBackwardThroughEntireTour() throws {
        try self.openTourWindow()
        XCTFail()
    }

    func test_getStartedOpensWelcomeWindowIfNoDocumentsAreOpen() throws {
        try self.openTourWindow()
        XCTFail()
    }

    func test_getStartedDoesntOpenWelcomeWindowIfADocumentIsOpen() throws {
        try self.openTourWindow()
        XCTFail()
    }

    func test_clickingSampleDocumentOpensSampleDocument() throws {
        try self.openTourWindow()
        XCTFail()
    }
}
