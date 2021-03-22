//
//  SearchResultsViewModelTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 20/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import Coppice
@testable import CoppiceCore
import XCTest

class SearchResultsViewModelTests: XCTestCase {
    var modelController: CoppiceModelController!
    var documentViewModel: DocumentWindowViewModel!
    var viewModel: SearchResultsViewModel!

    override func setUp() {
        super.setUp()

        self.modelController = CoppiceModelController(undoManager: UndoManager())
        self.documentViewModel = DocumentWindowViewModel(modelController: self.modelController)
        self.viewModel = SearchResultsViewModel(documentWindowViewModel: self.documentViewModel)
    }


    //MARK: - clearSearch()
    func test_clearSearch_setsDocumentVMSearchStringToNil() throws {
        self.documentViewModel.searchString = "Foo"

        self.viewModel.clearSearch()

        XCTAssertNil(self.documentViewModel.searchString)
    }


    //MARK: - .selectedResults
    func test_selectedResults_updatesDocumentVMSelection() throws {
        let page = self.modelController.collection(for: Page.self).newObject()
        let result1 = PageSearchResult(match: .init(page: page, matchType: .title(NSRange(location: 0, length: 0))), searchTerm: "")

        let canvas = self.modelController.collection(for: Canvas.self).newObject()
        let result2 = CanvasSearchResult(match: .init(canvas: canvas, matchType: .title(NSRange(location: 0, length: 0))), searchTerm: "")

        self.viewModel.selectedResults = [result1, result2]

        XCTAssertEqual(self.documentViewModel.sidebarSelection, [.page(page.id), .canvas(canvas.id)])
    }


    //MARK: - .results
    func test_results_returnsEmptyArrayIfNoResults() throws {
        self.addTestData()
        self.viewModel.searchTerm = "Possum"
        XCTAssertEqual(self.viewModel.results, [])
    }

    func test_results_returnsCanvasesSearchGroupIfCanvasResults() throws {
        self.addTestData()
        self.viewModel.searchTerm = "Hello World"
        XCTAssertEqual(self.viewModel.results[safe: 0]?.title, "Canvases")
    }

    func test_results_addsResultsForAllMatchingCanvasesToCanvasResultsGroup() throws {
        self.addTestData()
        self.viewModel.searchTerm = "Hello"
        XCTAssertEqual(self.viewModel.results[safe: 0]?.results.count, 2)
    }

    func test_results_returnsPageSearchGroupIfPageResults() throws {
        self.addTestData()
        self.viewModel.searchTerm = "the"
        XCTAssertEqual(self.viewModel.results[safe: 1]?.title, "Pages")
    }

    func test_results_addsResultsForAllMatchingPagesToPageResultsGroup() throws {
        self.addTestData()
        self.viewModel.searchTerm = "hello"
        XCTAssertEqual(self.viewModel.results[safe: 0]?.results.count, 2)
        XCTAssertEqual(self.viewModel.results[safe: 1]?.results.count, 1)
    }


    //MARK: - addPages(with:to:)
    func test_addPagesWithIDsToCanvas_addsPagesToCanvas() throws {
        let (page1, page2, canvas1, _) = self.addTestData()
        XCTAssertTrue(self.viewModel.addPages(with: [page1.id, page2.id], to: canvas1))
        XCTAssertEqual(canvas1.pages.count, 2)
        XCTAssertTrue(canvas1.pages.contains(where: { $0.page == page1 }))
        XCTAssertTrue(canvas1.pages.contains(where: { $0.page == page2 }))
    }


    //MARK: - Helpers
    @discardableResult func addTestData() -> (Page, Page, Canvas, Canvas) {
        let page1 = self.modelController.collection(for: Page.self).newObject() {
            $0.title = "Hello Goodbye"
            let content = TextPageContent()
            content.text = NSAttributedString(string: "Foo Bar the Baz")
            $0.content = content
        }

        let page2 = self.modelController.collection(for: Page.self).newObject() {
            $0.title = "News of the world"
            let content = TextPageContent()
            content.text = NSAttributedString(string: "What on earth?")
            $0.content = content
        }

        let canvas1 = self.modelController.collection(for: Canvas.self).newObject() {
            $0.title = "Hello World"
        }

        let canvas2 = self.modelController.collection(for: Canvas.self).newObject() {
            $0.title = "Hello Earth"
        }

        canvas2.addPages([page2])

        return (page1, page2, canvas1, canvas2)
    }
}
