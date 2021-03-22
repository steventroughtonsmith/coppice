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

        let window = XCUIApplication().windows["TourWindow"]

        window.images["TourGraphicToolbar"].hover()

        let label = try XCTUnwrap(window.staticTexts["TourGraphicDetailsLabel"].value as? String)
        XCTAssertTrue(label.hasPrefix("Toolbar"))
    }

    func test_hoveringOverInspectorGraphicUpdatesText() throws {
        try self.openTourWindow()

        let window = XCUIApplication().windows["TourWindow"]

        window.images["TourGraphicInspectors"].hover()

        let label = try XCTUnwrap(window.staticTexts["TourGraphicDetailsLabel"].value as? String)
        XCTAssertTrue(label.hasPrefix("Inspectors"))
    }

    func test_hoveringOverEditorGraphicHighlightsText() throws {
        try self.openTourWindow()

        let window = XCUIApplication().windows["TourWindow"]

        window.images["TourGraphicEditor"].hover()

        let label = try XCTUnwrap(window.staticTexts["TourGraphicDetailsLabel"].value as? String)
        XCTAssertTrue(label.hasPrefix("Editor"))
    }

    func test_canMoveForwardAndBackwardThroughEntireTour() throws {
        try self.openTourWindow()

        let tourWindow = XCUIApplication()/*@START_MENU_TOKEN@*/ .windows["TourWindow"]/*[[".windows[\"Tour\"]",".windows[\"TourWindow\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let continueButton = tourWindow.buttons["TourContinue"]
        continueButton.click()
        XCTAssertTrue(tourWindow.staticTexts["Pages"].waitForExistence(timeout: 2))

        continueButton.click()
        XCTAssertTrue(tourWindow.staticTexts["Canvases"].waitForExistence(timeout: 2))

        continueButton.click()
        XCTAssertTrue(tourWindow.staticTexts["Links"].waitForExistence(timeout: 2))

        continueButton.click()
        XCTAssertTrue(tourWindow.staticTexts["Branches"].waitForExistence(timeout: 2))

        continueButton.click()
        XCTAssertTrue(tourWindow.staticTexts["Get Started"].waitForExistence(timeout: 2))


        let button = tourWindow.buttons.element(boundBy: 0)

        button.click()
        XCTAssertTrue(tourWindow.staticTexts["Branches"].waitForExistence(timeout: 2))

        button.click()
        XCTAssertTrue(tourWindow.staticTexts["Links"].waitForExistence(timeout: 2))

        button.click()
        XCTAssertTrue(tourWindow.staticTexts["Canvases"].waitForExistence(timeout: 2))

        button.click()
        XCTAssertTrue(tourWindow.staticTexts["Pages"].waitForExistence(timeout: 2))

        button.click()
        XCTAssertTrue(tourWindow.staticTexts["Welcome to Coppice"].waitForExistence(timeout: 2))
    }

    func test_getStartedOpensNewDocumentIfNoDocumentsAreOpen() throws {
        try self.openTourWindow()

        let app = XCUIApplication()
        let tourWindow = app.windows["TourWindow"]

        let continueButton = tourWindow.buttons["TourContinue"]
        continueButton.click()
        _ = tourWindow.staticTexts["Pages"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Canvases"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Links"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Branches"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Get Started"].waitForExistence(timeout: 2)
        continueButton.click()

        let documentWindows = app.windows.matching(identifier: "DocumentWindow")
        XCTAssertEqual(documentWindows.count, 1)
        XCTAssertTrue(documentWindows["Untitled"].waitForExistence(timeout: 1))
    }

    func test_getStartedDoesntOpenNewDocumentIfADocumentIsOpen() throws {
        let app = XCUIApplication()
        let menuBarsQuery = app.menuBars
        menuBarsQuery.menuBarItems["File"].click()
        menuBarsQuery/*@START_MENU_TOKEN@*/ .menuItems["New Document"]/*[[".menuBarItems[\"File\"]",".menus.menuItems[\"New Document\"]",".menuItems[\"New Document\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ .click()

        let documentWindows = app.windows.matching(identifier: "DocumentWindow")
        XCTAssertEqual(documentWindows.count, 1)

        try self.openTourWindow()

        let tourWindow = app.windows["TourWindow"]

        let continueButton = tourWindow.buttons["TourContinue"]
        continueButton.click()
        _ = tourWindow.staticTexts["Pages"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Canvases"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Links"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Branches"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Get Started"].waitForExistence(timeout: 2)
        continueButton.click()

        XCTAssertEqual(documentWindows.count, 1)
        XCTAssertTrue(documentWindows["Untitled"].waitForExistence(timeout: 1))
    }

    func test_clickingSampleDocumentOpensSampleDocument() throws {
        try self.openTourWindow()

        let app = XCUIApplication()
        let tourWindow = app.windows["TourWindow"]

        let continueButton = app.windows["TourWindow"].buttons["TourContinue"]
        continueButton.click()
        _ = tourWindow.staticTexts["Pages"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Canvases"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Links"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Branches"].waitForExistence(timeout: 2)
        continueButton.click()
        _ = tourWindow.staticTexts["Get Started"].waitForExistence(timeout: 2)

        tourWindow.buttons["View Sample Document…"].click()

        let documentWindows = app.windows.matching(identifier: "DocumentWindow")
        XCTAssertTrue(documentWindows["Sample Document.coppicedoc"].waitForExistence(timeout: 1))
    }
}
