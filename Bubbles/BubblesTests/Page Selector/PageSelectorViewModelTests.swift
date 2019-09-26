//
//  PageSelectorViewModelTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 20/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class PageSelectorViewModelTests: XCTestCase {

    var modelController: ModelController!
    var applePage: Page!
    var raspberryPage: Page!
    var strawberryPage: Page!
    var bananaPage: Page!

    override func setUp() {
        super.setUp()

        self.modelController = BubblesModelController(undoManager: UndoManager())
        self.applePage = self.modelController.collection(for: Page.self).newPage()
        self.applePage.title = "Apple"

        self.raspberryPage = self.modelController.collection(for: Page.self).newPage()
        self.raspberryPage.title = "Raspberry"

        self.strawberryPage = self.modelController.collection(for: Page.self).newPage()
        self.strawberryPage.title = "Strawberry"

        self.bananaPage = self.modelController.collection(for: Page.self).newPage()
        self.bananaPage.title = "Banana"
    }

    override func tearDown() {
        super.tearDown()
        self.modelController = nil
    }


    //MARK: - matchingPages
    func test_matchingPages_returnsAllPagesAfterInit() {
        let viewModel = PageSelectorViewModel(title: "", modelController: self.modelController) { (_) in }

        let matchingPages = viewModel.matchingPages.map { $0.page }
        XCTAssertTrue(matchingPages.contains(self.applePage))
        XCTAssertTrue(matchingPages.contains(self.raspberryPage))
        XCTAssertTrue(matchingPages.contains(self.strawberryPage))
        XCTAssertTrue(matchingPages.contains(self.bananaPage))
    }

    func test_matchingPages_returnsAllPagesIfSearchTermIsEmptyString() {
        let viewModel = PageSelectorViewModel(title: "", modelController: self.modelController) { (_) in }
        viewModel.searchTerm = "berry"
        viewModel.searchTerm = ""

        let matchingPages = viewModel.matchingPages.map { $0.page }
        XCTAssertTrue(matchingPages.contains(self.applePage))
        XCTAssertTrue(matchingPages.contains(self.raspberryPage))
        XCTAssertTrue(matchingPages.contains(self.strawberryPage))
        XCTAssertTrue(matchingPages.contains(self.bananaPage))
    }

    func test_matchingPages_returnsAllPagesIfSearchTermHasOneCharacter() {
        let viewModel = PageSelectorViewModel(title: "", modelController: self.modelController) { (_) in }
        viewModel.searchTerm = "berry"
        viewModel.searchTerm = "b"

        let matchingPages = viewModel.matchingPages.map { $0.page }
        XCTAssertTrue(matchingPages.contains(self.applePage))
        XCTAssertTrue(matchingPages.contains(self.raspberryPage))
        XCTAssertTrue(matchingPages.contains(self.strawberryPage))
        XCTAssertTrue(matchingPages.contains(self.bananaPage))
    }

    func test_matchingPages_allPagesAreSortedByTitle() {
        let viewModel = PageSelectorViewModel(title: "", modelController: self.modelController) { (_) in }

        let matchingPages = viewModel.matchingPages.map { $0.page }
        let expectedPages = [self.applePage, self.bananaPage, self.raspberryPage, self.strawberryPage]

        XCTAssertEqual(matchingPages, expectedPages)
    }

    func test_matchingPages_filtersPagesByTitleIfSearchTermHasMoreThanOneCharacter() {
        let viewModel = PageSelectorViewModel(title: "", modelController: self.modelController) { (_) in }
        viewModel.searchTerm = "be"

        let matchingPages = viewModel.matchingPages.map { $0.page }

        XCTAssertTrue(matchingPages.contains(self.raspberryPage))
        XCTAssertTrue(matchingPages.contains(self.strawberryPage))
        XCTAssertEqual(matchingPages.count, 2)
    }

    func test_matchingPages_searchTermIsCaseInsensitivelySearched() {
        let viewModel = PageSelectorViewModel(title: "", modelController: self.modelController) { (_) in }
        viewModel.searchTerm = "apple"
        XCTAssertEqual(viewModel.matchingPages.count, 1)
        XCTAssertEqual(viewModel.matchingPages.first?.page, self.applePage)

        viewModel.searchTerm = "" // Clear

        viewModel.searchTerm = "Apple"
        XCTAssertEqual(viewModel.matchingPages.count, 1)
        XCTAssertEqual(viewModel.matchingPages.first?.page, self.applePage)
    }

    func test_matchingPages_titleIsCaseInsensitivelySearched() {
        let viewModel = PageSelectorViewModel(title: "", modelController: self.modelController) { (_) in }
        viewModel.searchTerm = "apple"
        XCTAssertEqual(viewModel.matchingPages.count, 1)
        XCTAssertEqual(viewModel.matchingPages.first?.page, self.applePage)

        viewModel.searchTerm = "" // Clear

        self.applePage.title = "apple"
        viewModel.searchTerm = "Apple"
        XCTAssertEqual(viewModel.matchingPages.count, 1)
        XCTAssertEqual(viewModel.matchingPages.first?.page, self.applePage)
    }

    func test_matchingPages_sortsFilteredPages() {
        let viewModel = PageSelectorViewModel(title: "", modelController: self.modelController) { (_) in }
        viewModel.searchTerm = "be"

        let matchingPages = viewModel.matchingPages.map { $0.page }
        let expectedPages = [self.raspberryPage, self.strawberryPage]
        XCTAssertEqual(matchingPages, expectedPages)
    }


    //MARK: - Confirm Selection
    func test_confirmSelection_callsSelectionBlockWithPageFromSuppliedResult() {
        let expectation = self.expectation(description: "Selector Block called")
        var selectedPage: Page?
        let viewModel = PageSelectorViewModel(title: "", modelController: self.modelController) { (page) in
            selectedPage = page
            expectation.fulfill()
        }

        let pageResult = PageSelectorResult(page: self.raspberryPage)
        viewModel.confirmSelection(of: pageResult)
        self.wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual(selectedPage, self.raspberryPage)
    }

}
