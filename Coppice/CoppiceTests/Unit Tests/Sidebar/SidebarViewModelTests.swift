//
//  SidebarViewModelTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 20/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import Coppice
@testable import CoppiceCore
import XCTest

class SidebarViewModelTests: XCTestCase {
    func test_tellsViewToDisplaySourceListIfSearchStringIsNil() {
        let documentViewModel = DocumentWindowViewModel(modelController: CoppiceModelController(undoManager: UndoManager()))
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
        let documentViewModel = DocumentWindowViewModel(modelController: CoppiceModelController(undoManager: UndoManager()))
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
    func displaySearchResults(forSearchString searchString: String) {
        self.expectation?.fulfill()
        self.displaySearchResultsString = searchString
    }
}
