//
//  SidebarViewModelTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 20/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class SidebarViewModelTests: XCTestCase {

    func test_tellsViewToDisplaySourceListIfSearchStringIsNil() {
        let documentViewModel = DocumentWindowViewModel(modelController: BubblesModelController(undoManager: UndoManager()))
        documentViewModel.searchString = ""
        let sidebarVM = SidebarViewModel(documentWindowViewModel: documentViewModel)
        sidebarVM.setup()

        let view = TestSidebarView()
        sidebarVM.view = view
        self.performAndWaitFor("View Called") { (expectation) in
            view.expectation = expectation
            documentViewModel.searchString = nil
        }

        XCTAssertTrue(view.displaySourceListCalled)
    }

    func test_tellsViewToDisplaySearchResultsWithSearchStringIfNotNil() {
        let documentViewModel = DocumentWindowViewModel(modelController: BubblesModelController(undoManager: UndoManager()))
        let sidebarVM = SidebarViewModel(documentWindowViewModel: documentViewModel)
        sidebarVM.setup()

        let view = TestSidebarView()
        sidebarVM.view = view
        self.performAndWaitFor("View Called") { (expectation) in
            view.expectation = expectation
            documentViewModel.searchString = "foo"
        }

        XCTAssertEqual(view.displaySearchResultsString, "foo")
    }

}

class TestSidebarView: SidebarView {
    var expectation: XCTestExpectation?

    var displaySourceListCalled = false
    func displaySourceList() {
        self.expectation?.fulfill()
        self.displaySourceListCalled = true
    }

    var displaySearchResultsString: String? = nil
    func displaySearchResults(forSearchTerm searchTerm: String) {
        self.expectation?.fulfill()
        displaySearchResultsString = searchTerm
    }
}
