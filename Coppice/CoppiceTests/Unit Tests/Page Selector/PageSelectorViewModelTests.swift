//
//  PageSelectorViewModelTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 20/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

@testable import Coppice
@testable import CoppiceCore
import XCTest

class PageSelectorViewModelTests: XCTestCase {
    var modelController: CoppiceModelController!
    var documentWindowViewModel: DocumentWindowViewModel!
    var applePage: Page!
    var raspberryPage: Page!
    var strawberryPage: Page!
    var bananaPage: Page!

    let expectedAdditionalRows = (Page.ContentType.allCases.count + 2)

    override func setUp() {
        super.setUp()

        self.modelController = CoppiceModelController(undoManager: UndoManager())
        self.documentWindowViewModel = DocumentWindowViewModel(modelController: self.modelController)
        self.applePage = self.modelController.collection(for: Page.self).newObject()
        self.applePage.title = "Apple"

        self.raspberryPage = self.modelController.collection(for: Page.self).newObject()
        self.raspberryPage.title = "Raspberry"

        self.strawberryPage = self.modelController.collection(for: Page.self).newObject()
        self.strawberryPage.title = "Strawberry"

        self.bananaPage = self.modelController.collection(for: Page.self).newObject()
        self.bananaPage.title = "Banana"
    }

    override func tearDown() {
        super.tearDown()
        self.modelController = nil
    }


    //MARK: - .rows (Pages)
    func test_rows_returnsAllPagesAfterInit() {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }

        let matchingPages = viewModel.rows.map { $0.rowType }
        XCTAssertTrue(matchingPages.contains(.page(self.applePage)))
        XCTAssertTrue(matchingPages.contains(.page(self.raspberryPage)))
        XCTAssertTrue(matchingPages.contains(.page(self.strawberryPage)))
        XCTAssertTrue(matchingPages.contains(.page(self.bananaPage)))
    }

    func test_rows_returnsAllPagesIfSearchStringIsEmptyString() {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }
        viewModel.searchString = "berry"
        viewModel.searchString = ""

        let matchingPages = viewModel.rows.map { $0.rowType }
        XCTAssertTrue(matchingPages.contains(.page(self.applePage)))
        XCTAssertTrue(matchingPages.contains(.page(self.raspberryPage)))
        XCTAssertTrue(matchingPages.contains(.page(self.strawberryPage)))
        XCTAssertTrue(matchingPages.contains(.page(self.bananaPage)))
    }

    func test_rows_returnsAllPagesIfSearchStringHasOneCharacter() {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }
        viewModel.searchString = "berry"
        viewModel.searchString = "b"

        let matchingPages = viewModel.rows.map { $0.rowType }
        XCTAssertTrue(matchingPages.contains(.page(self.applePage)))
        XCTAssertTrue(matchingPages.contains(.page(self.raspberryPage)))
        XCTAssertTrue(matchingPages.contains(.page(self.strawberryPage)))
        XCTAssertTrue(matchingPages.contains(.page(self.bananaPage)))
    }

    func test_rows_allPagesAreSortedByTitle() {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }

        let matchingPages = viewModel.rows[0..<4].map { $0.rowType }
        let expectedPages: [PageSelectorRow.RowType] = [
            .page(self.applePage),
            .page(self.bananaPage),
            .page(self.raspberryPage),
            .page(self.strawberryPage),
        ]

        XCTAssertEqual(matchingPages, expectedPages)
    }

    func test_rows_filtersPagesByTitleIfSearchStringHasMoreThanOneCharacter() {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }
        viewModel.searchString = "be"

        let matchingPages = viewModel.rows.map { $0.rowType }

        XCTAssertTrue(matchingPages.contains(.page(self.raspberryPage)))
        XCTAssertTrue(matchingPages.contains(.page(self.strawberryPage)))
        XCTAssertEqual(matchingPages.count, 2 + self.expectedAdditionalRows)
    }

    func test_rows_searchStringIsCaseInsensitivelySearched() {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }
        viewModel.searchString = "apple"
        XCTAssertEqual(viewModel.rows.count, 1 + self.expectedAdditionalRows)
        XCTAssertEqual(viewModel.rows.first?.rowType, .page(self.applePage))

        viewModel.searchString = "" // Clear

        viewModel.searchString = "Apple"
        XCTAssertEqual(viewModel.rows.count, 1 + self.expectedAdditionalRows)
        XCTAssertEqual(viewModel.rows.first?.rowType, .page(self.applePage))
    }

    func test_rows_titleIsCaseInsensitivelySearched() {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }
        viewModel.searchString = "apple"
        XCTAssertEqual(viewModel.rows.count, 1 + self.expectedAdditionalRows)
        XCTAssertEqual(viewModel.rows.first?.rowType, .page(self.applePage))

        viewModel.searchString = "" // Clear

        self.applePage.title = "apple"
        viewModel.searchString = "Apple"
        XCTAssertEqual(viewModel.rows.count, 1 + self.expectedAdditionalRows)
        XCTAssertEqual(viewModel.rows.first?.rowType, .page(self.applePage))
    }

    func test_rows_sortsFilteredPages() {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }
        viewModel.searchString = "be"

        let matchingPages = viewModel.rows[0..<2].map { $0.rowType }
        let expectedPages: [PageSelectorRow.RowType] = [.page(self.raspberryPage), .page(self.strawberryPage)]
        XCTAssertEqual(matchingPages, expectedPages)
    }


    //MARK: - .row (ContentType)
    func test_rows_includesHeaderRowAfterPages() throws {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }

        XCTAssertEqual(viewModel.rows[safe: 5]?.title, "Create New…")
        XCTAssertEqual(viewModel.rows[safe: 5]?.rowType, .header)
    }

    func test_rows_includesContentTypesAfterHeaderRow() throws {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }

        let contentTypeRows = viewModel.rows.filter { row in
            if case .contentType = row.rowType {
                return true
            }
            return false
        }
        XCTAssertEqual(contentTypeRows.first, try XCTUnwrap(viewModel.rows[safe: 6]))
        XCTAssertEqual(contentTypeRows.count, Page.ContentType.allCases.count)
        for contentType in Page.ContentType.allCases {
            XCTAssertTrue(contentTypeRows.contains(where: { $0.rowType == .contentType(contentType) }))
        }
    }

    func test_rows_includesAllContentTypesIfPagesAreFiltered() throws {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }
        viewModel.searchString = "be"

        let contentTypeRows = viewModel.rows.filter { row in
            if case .contentType = row.rowType {
                return true
            }
            return false
        }
        XCTAssertEqual(contentTypeRows.count, Page.ContentType.allCases.count)
        for contentType in Page.ContentType.allCases {
            XCTAssertTrue(contentTypeRows.contains(where: { $0.rowType == .contentType(contentType) }))
        }
    }

    func test_rows_includesAllContentTypesIfNoPagesAreVisible() throws {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (_) in }
        viewModel.searchString = "mcubedsw"

        let contentTypeRows = viewModel.rows.filter { row in
            if case .contentType = row.rowType {
                return true
            }
            return false
        }
        XCTAssertEqual(contentTypeRows.count, Page.ContentType.allCases.count)
        for contentType in Page.ContentType.allCases {
            XCTAssertTrue(contentTypeRows.contains(where: { $0.rowType == .contentType(contentType) }))
        }
    }


    //MARK: - Confirm Selection
    func test_confirmSelection_selectingPageCallsSelectionBlockWithPageFromSuppliedResult() {
        var selectedPage: Page?
        self.performAndWaitFor("Selector Block called", timeout: 0.5) { expectation in
            let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (result) in
                if case .page(let page) = result {
                    selectedPage = page
                }
                expectation.fulfill()
            }

            let pageResult = PageSelectorRow(page: self.raspberryPage)
            viewModel.confirmSelection(of: pageResult)
        }
        XCTAssertEqual(selectedPage, self.raspberryPage)
    }

    func test_confirmSelection_selectingHeaderDoesNothing() throws {
        var selectedPage: Page?
        self.performAndWaitFor("Selector Block called", timeout: 0.5) { expectation in
            expectation.isInverted = true
            let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (result) in
                if case .page(let page) = result {
                    selectedPage = page
                }
                expectation.fulfill()
            }

            let pageResult = PageSelectorRow(title: "", body: nil, image: nil, rowType: .header)
            viewModel.confirmSelection(of: pageResult)
        }
        XCTAssertNil(selectedPage)
    }

    func test_confirmSelection_selectingContentTypeCreatesPageOfTypeWithTitleAndPassesToSelectionBlock() throws {
        var selectedPage: Page?
        self.performAndWaitFor("Selector Block called", timeout: 0.5) { expectation in
            let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.documentWindowViewModel) { (result) in
                if case .page(let page) = result {
                    selectedPage = page
                }
                expectation.fulfill()
            }

            viewModel.searchString = "Berry"

            let pageResult = PageSelectorRow(contentType: .image)
            viewModel.confirmSelection(of: pageResult)
        }

        let page = try XCTUnwrap(modelController.pageCollection.all.first(where: { $0.title == "Berry" }))
        XCTAssertEqual(selectedPage, page)
        XCTAssertTrue(page.content is Page.Content.Image)
    }
}
