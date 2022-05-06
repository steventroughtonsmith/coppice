//
//  SidebarUITests.swift
//  CoppiceUITests
//
//  Created by Martin Pilkington on 02/05/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import XCTest

class SidebarUITests: BaseUITestCase {
    override func performAdditionalSetup(on app: XCUIApplication) throws {
        try self.cleanUpTestDocument()
        try self.createTestDocument()
        app.launchArguments = [
            "-M3DebugAPIURL",
            "https://dev-mcubedsw-com:8890/api",
            self.urlForTestDocument.path,
        ]
    }

    override func tearDownWithError() throws {
        try self.cleanUpTestDocument()
    }

    //MARK: - Create Page
    func test_createPage_creatingTextPageFromMenuBarWithMouse() throws {
        let app = XCUIApplication()
        let menuBarsQuery = app.menuBars
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        menuBarsQuery.menuBarItems["File"].click()
        menuBarsQuery.menuItems["New Page"].menuItems["Text Page"].click()
        sidebarOutline.click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertTrue(sidebarOutline.cells["Untitled Page, Text Page"].exists)
    }

    func test_createPage_creatingImagePageFromMenuBarWithMouse() throws {
        let app = XCUIApplication()
        let menuBarsQuery = app.menuBars
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        menuBarsQuery.menuBarItems["File"].click()
        menuBarsQuery.menuItems["New Page"].menuItems["Image Page"].click()
        sidebarOutline.click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertTrue(sidebarOutline.cells["Untitled Page, Image Page"].exists)
    }

    func test_createPage_creatingTextPageWithKeyboardShortcut() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        app.typeKey("n", modifierFlags: [.command, .shift])
        sidebarOutline.click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertTrue(sidebarOutline.cells["Untitled Page, Text Page"].exists)
    }

    func test_createPage_creatingImagePageWithKeyboardShortcut() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        app.typeKey("n", modifierFlags: [.command, .shift, .option])
        sidebarOutline.click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertTrue(sidebarOutline.cells["Untitled Page, Image Page"].exists)
    }

    func test_createPage_clickingOnToolbarCreatesTextPage() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        app.documentWindow.toolbars.buttons["New Page"].click()
        sidebarOutline.click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertTrue(sidebarOutline.cells["Untitled Page, Text Page"].exists)
    }

    func test_createPage_clickingAndHoldingOnToolbarAndSelectingTextPageCreatesTextPage() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        let newPageCoordinate = app.documentWindow.toolbars.buttons["New Page"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let menuCoordinate = newPageCoordinate.withOffset(CGVector(dx: 0, dy: 40))
        newPageCoordinate.click(forDuration: 1, thenDragTo: menuCoordinate)
        sidebarOutline.click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertTrue(sidebarOutline.cells["Untitled Page, Text Page"].exists)
    }

    func test_createPage_clickingAndHoldingOnToolbarAndSelectingImagePageCreatesImagePage() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        let newPageCoordinate = app.documentWindow.toolbars.buttons["New Page"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let menuCoordinate = newPageCoordinate.withOffset(CGVector(dx: 0, dy: 60))
        newPageCoordinate.click(forDuration: 1, thenDragTo: menuCoordinate)
        sidebarOutline.click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertTrue(sidebarOutline.cells["Untitled Page, Image Page"].exists)
    }

    func test_createPage_creatingImagePageAndThenClickingOnToolbarCreatesImagePage() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline
        app.typeKey("n", modifierFlags: [.command, .shift, .option])
        sidebarOutline.click()

        let cellCount = sidebarOutline.cells.count

        app.documentWindow.toolbars.buttons["New Page"].click()
        sidebarOutline.click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertTrue(sidebarOutline.cells["Untitled Page, Image Page"].exists)
    }

    //MARK: - Create Folder
    func test_createFolder_createFolderFromMenuBar() throws {
        let app = XCUIApplication()
        let menuBarsQuery = app.menuBars
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        menuBarsQuery.menuBarItems["File"].click()
        menuBarsQuery.menuItems["New Folder"].click()
        sidebarOutline.click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertTrue(sidebarOutline.cells["New Folder, Folder"].exists)
    }

    func test_createFolder_createFolderFromBottomOfSidebar() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        app.documentWindow.menuButtons["SidebarAdd"].click()
        app.documentWindow.menuItems["New Folder"].click()
        sidebarOutline.click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertTrue(sidebarOutline.cells["New Folder, Folder"].exists)
    }

    //MARK: - Create Folder From Selection
    func test_createFolderFromSelection_canCreateFolderFromSelectionAtRoot() throws {
        let app = XCUIApplication()
        let documentWindow = app.documentWindow
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        sidebarOutline.cells["Coppice Icon, Image Page"].middleCoordinate.click()
        XCUIElement.perform(withKeyModifiers: .shift) {
            sidebarOutline.cells["Canvas Page, Text Page"].middleCoordinate.click()
        }

        documentWindow.menuButtons["SidebarAdd"].click()
        documentWindow.menuItems["newFolderFromSelection:"].click()
        documentWindow.outlines["SidebarTable"].click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount - 1)
        XCTAssertTrue(sidebarOutline.cells["New Folder, Folder"].exists)
        XCTAssertFalse(sidebarOutline.cells["Coppice Icon, Image Page"].exists)
        XCTAssertFalse(sidebarOutline.cells["Canvas Page, Text Page"].exists)
    }

    func test_createFolderFromSelection_canCreateFolderFromSelectionInsideFolder() throws {
        let app = XCUIApplication()
        let documentWindow = app.documentWindow
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        sidebarOutline.cells["Folder Page 1, Text Page"].middleCoordinate.click()
        XCUIElement.perform(withKeyModifiers: .command) {
            sidebarOutline.cells["Folder Page 3, Text Page"].middleCoordinate.click()
        }

        documentWindow.menuButtons["SidebarAdd"].click()
        documentWindow.menuItems["newFolderFromSelection:"].click()
        documentWindow.outlines["SidebarTable"].click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount - 1)
        XCTAssertTrue(sidebarOutline.cells["New Folder, Folder"].exists)
        XCTAssertFalse(sidebarOutline.cells["Folder Page 1, Text Page"].exists)
        XCTAssertFalse(sidebarOutline.cells["Folder Page 3, Text Page"].exists)
    }

    func test_createFolderFromSelection_menuItemIsDisabledIfSelectionHasDifferentParents() throws {
        let app = XCUIApplication()
        let documentWindow = app.documentWindow
        let sidebarOutline = app.sidebarOutline

        sidebarOutline.cells["Canvas Page, Text Page"].middleCoordinate.click()
        XCUIElement.perform(withKeyModifiers: .command) {
            sidebarOutline.cells["Folder Page 3, Text Page"].middleCoordinate.click()
        }

        documentWindow.menuButtons["SidebarAdd"].click()
        XCTAssertFalse(documentWindow.menuItems["newFolderFromSelection:"].isEnabled)
    }

    //MARK: - Edit Title
    func test_editPageTitle_canRenamePage() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline

        let page = sidebarOutline.cells["Canvas Page, Text Page"]
        page.middleCoordinate.doubleClick()
        page.typeText("Hello World")
        page.typeKey(.enter, modifierFlags: [])

        XCTAssertFalse(page.exists)
        XCTAssertTrue(sidebarOutline.cells["Hello World, Text Page"].exists)
    }

    func test_editPageTitle_canRenameFolder() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline

        let page = sidebarOutline.cells["Folder, Folder"]
        page.middleCoordinate.doubleClick()
        page.typeText("Hello World")
        page.typeKey(.enter, modifierFlags: [])

        XCTAssertFalse(page.exists)
        XCTAssertTrue(sidebarOutline.cells["Hello World, Folder"].exists)
    }

    func test_editPageTitle_cannotRenameCanvases() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline

        let page = sidebarOutline.cells["Canvases"]
        page.middleCoordinate.doubleClick()
        page.typeText("Hello World")
        page.typeKey(.enter, modifierFlags: [])

        XCTAssertTrue(page.exists)
    }

    //MARK: - Duplicate Page
    func test_duplicatePage_duplicatingPageAtRootAddsNewPage() throws {
        let app = XCUIApplication()
        let documentWindow = app.documentWindow
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        sidebarOutline.cells["Coppice Icon, Image Page"].middleCoordinate.click()

        documentWindow.menuButtons["SidebarAction"].click()
        documentWindow.menuItems["duplicatePage:"].click()
        documentWindow.outlines["SidebarTable"].click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 3).label, sidebarOutline.cells.element(boundBy: 4).label)
    }

    func test_duplicatePage_duplicatingPageInFolderAddsNewPageInFolder() throws {
        let app = XCUIApplication()
        let documentWindow = app.documentWindow
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        sidebarOutline.cells["Folder Page 2, Text Page"].middleCoordinate.click()

        documentWindow.menuButtons["SidebarAction"].click()
        documentWindow.menuItems["duplicatePage:"].click()
        documentWindow.outlines["SidebarTable"].click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount + 1)
        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 6).label, sidebarOutline.cells.element(boundBy: 7).label)
    }

    //MARK: - Deleting
    func test_deleting_deletingPageRemovesFromSidebar() throws {
        let app = XCUIApplication()
        let documentWindow = app.documentWindow
        let sidebarOutline = app.sidebarOutline
        let cellCount = sidebarOutline.cells.count

        sidebarOutline.cells["Coppice Icon, Image Page"].middleCoordinate.click()

        documentWindow.menuButtons["SidebarAction"].click()
        documentWindow.menuItems["deleteItems:"].click()

        XCTAssertEqual(sidebarOutline.cells.count, cellCount - 1)
    }

    func test_deleting_deletingPageNotOnCanvasDoesntShowAlert() throws {
        let app = XCUIApplication()
        let documentWindow = app.documentWindow
        let sidebarOutline = app.sidebarOutline

        sidebarOutline.cells["Coppice Icon, Image Page"].middleCoordinate.click()

        documentWindow.menuButtons["SidebarAction"].click()
        documentWindow.menuItems["deleteItems:"].click()

        XCTAssertEqual(app.sheets.count, 0)
    }

    func test_deleting_deletingPageOnCanvasShowsAlert() throws {
        let app = XCUIApplication()
        let documentWindow = app.documentWindow
        let sidebarOutline = app.sidebarOutline

        sidebarOutline.cells["Canvas Page, Text Page"].middleCoordinate.click()

        documentWindow.menuButtons["SidebarAction"].click()
        documentWindow.menuItems["deleteItems:"].click()

        XCTAssertEqual(app.sheets.count, 1)
        XCTAssertTrue(app.sheets.firstMatch.buttons["Delete"].exists)
        XCTAssertTrue(app.sheets.firstMatch.buttons["Cancel"].exists)
    }

    func test_deleting_deletingFolderContainingPagesShowsAlert() throws {
        let app = XCUIApplication()
        let documentWindow = app.documentWindow
        let sidebarOutline = app.sidebarOutline

        sidebarOutline.cells["Folder, Folder"].middleCoordinate.click()

        documentWindow.menuButtons["SidebarAction"].click()
        documentWindow.menuItems["deleteItems:"].click()

        XCTAssertEqual(app.sheets.count, 1)
        XCTAssertTrue(app.sheets.firstMatch.buttons["Delete"].exists)
        XCTAssertTrue(app.sheets.firstMatch.buttons["Cancel"].exists)
    }

    func test_deleting_deletingEmptyFolderDoesntShowAlert() throws {
        let app = XCUIApplication()
        let menuBarsQuery = app.menuBars
        let documentWindow = app.documentWindow
        let sidebarOutline = app.sidebarOutline

        menuBarsQuery.menuBarItems["File"].click()
        menuBarsQuery.menuItems["New Folder"].click()
        sidebarOutline.click()

        sidebarOutline.cells["New Folder, Folder"].middleCoordinate.click()

        documentWindow.menuButtons["SidebarAction"].click()
        documentWindow.menuItems["deleteItems:"].click()

        XCTAssertEqual(app.sheets.count, 0)
    }

    //MARK: - Moving
    func test_moving_canMovePageToTop() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline

        let pageCoordinate = sidebarOutline.cells["Coppice Icon, Image Page"].middleCoordinate
        pageCoordinate.click(forDuration: 0, thenDragTo: pageCoordinate.withOffset(CGVector(dx: 0, dy: -40)))

        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 2).label, "Coppice Icon, Image Page")
        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 3).label, "Canvas Page, Text Page")
    }

    func test_moving_canMoveFolderToTop() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline

        let pageCoordinate = sidebarOutline.cells["Folder, Folder"].middleCoordinate
        pageCoordinate.click(forDuration: 0, thenDragTo: pageCoordinate.withOffset(CGVector(dx: 0, dy: -60)))

        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 2).label, "Folder, Folder")
        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 6).label, "Canvas Page, Text Page")
        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 7).label, "Coppice Icon, Image Page")
    }

    func test_moving_canMovePageIntoFolder() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline

        let pageCoordinate = sidebarOutline.cells["Canvas Page, Text Page"].middleCoordinate
        pageCoordinate.click(forDuration: 0, thenDragTo: pageCoordinate.withOffset(CGVector(dx: 0, dy: 80)))

        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 2).label, "Coppice Icon, Image Page")
        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 5).label, "Canvas Page, Text Page")
    }

    func test_moving_canMovePageOutOfFolder() throws {
        let app = XCUIApplication()
        let sidebarOutline = app.sidebarOutline

        let pageCoordinate = sidebarOutline.cells["Folder Page 2, Text Page"].middleCoordinate
        pageCoordinate.click(forDuration: 0, thenDragTo: pageCoordinate.withOffset(CGVector(dx: 0, dy: -80)))

        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 2).label, "Canvas Page, Text Page")
        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 3).label, "Folder Page 2, Text Page")
        XCTAssertEqual(sidebarOutline.cells.element(boundBy: 4).label, "Coppice Icon, Image Page")
    }
}


//MARK: - Helpers
extension SidebarUITests {
    private var urlForTestDocument: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("SidebarUITestsDocument.coppicedoc")
    }

    private func createTestDocument() throws {
        guard let url = self.testBundle.url(forResource: "SidebarUITestsDocument", withExtension: "coppicedoc") else {
            XCTFail("Document not found")
            return
        }
        try FileManager.default.copyItem(at: url, to: self.urlForTestDocument)
    }

    private func cleanUpTestDocument() throws {
        guard FileManager.default.fileExists(atPath: self.urlForTestDocument.path) else {
            return
        }
        try FileManager.default.removeItem(at: self.urlForTestDocument)
    }
}

extension XCUIElement {
    var middleCoordinate: XCUICoordinate {
        return self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    }
}

extension XCUIApplication {
    fileprivate var documentWindow: XCUIElement {
        return self.windows["DocumentWindow"].firstMatch
    }

    fileprivate var sidebarOutline: XCUIElement {
        return self.documentWindow.outlines["SidebarTable"]
    }
}
