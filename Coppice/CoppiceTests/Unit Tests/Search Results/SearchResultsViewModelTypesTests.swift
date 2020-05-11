//
//  SearchResultsViewModelTypesTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 20/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class PageSearchResultTests: XCTestCase {
    //MARK: - .title
    func test_title_returnsPageTitle() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.collection(for: Page.self).newObject() { $0.title = "Foo Bar Baz" }
        let result = PageSearchResult(match: .init(page: page, matchType: .title(NSRange(location: 4, length: 3))), searchTerm: "Bar")

        XCTAssertEqual(result.title?.string, page.title)
    }


    //MARK: - .body
    func test_body_returnsNilIfContentIsImage() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.collection(for: Page.self).newObject() {
            $0.title = "Foo Bar Baz"
            $0.content = ImagePageContent()
        }
        let result = PageSearchResult(match: .init(page: page, matchType: .title(NSRange(location: 4, length: 3))), searchTerm: "Bar")

        XCTAssertNil(result.body)
    }

    func test_body_returnsBodyTextIfNotContentMatch() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.collection(for: Page.self).newObject() {
            $0.title = "Foo Bar Baz"
            let content = TextPageContent()
            content.text = NSAttributedString(string: "The quick brown fox jumped over the lazy dog")
            $0.content = content
        }
        let result = PageSearchResult(match: .init(page: page, matchType: .title(NSRange(location: 4, length: 3))), searchTerm: "Bar")

        XCTAssertEqual(result.body?.string, "The quick brown fox jumped over the lazy dog")
    }

    func test_body_startsFromStartOfContentIfRangeWithinFirst20Characters() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.collection(for: Page.self).newObject() {
            $0.title = "Foo Bar Baz"
            let content = TextPageContent()
            content.text = NSAttributedString(string: "The quick brown fox jumped over the lazy dog")
            $0.content = content
        }
        let result = PageSearchResult(match: .init(page: page, matchType: .content(NSRange(location: 4, length: 5))), searchTerm: "quick")

        XCTAssertEqual(result.body?.string, "The quick brown fox jumped over the lazy dog")
    }

    func test_body_startsFromStartOfMatchRangeIfOutsideFirst20Characters() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let page = modelController.collection(for: Page.self).newObject() {
            $0.title = "Foo Bar Baz"
            let content = TextPageContent()
            content.text = NSAttributedString(string: "The quick brown fox jumped over the lazy dog")
            $0.content = content
        }
        let result = PageSearchResult(match: .init(page: page, matchType: .content(NSRange(location: 16, length: 5))), searchTerm: "fox j")

        XCTAssertEqual(result.body?.string, "… fox jumped over the lazy dog")
    }
}


class CanvasSearchResultTests: XCTestCase {
    //MARK: - .title
    func test_title_returnsCanvasTitle() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let canvas = modelController.collection(for: Canvas.self).newObject() { $0.title = "Foo Bar Baz" }
        let result = CanvasSearchResult(match: .init(canvas: canvas, matchType: .title(NSRange(location: 4, length: 3))), searchTerm: "Bar")

        XCTAssertEqual(result.title?.string, canvas.title)
    }

    //MARK: - .body
    func test_body_returnsNilIfTitleMatch() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let canvas = modelController.collection(for: Canvas.self).newObject() { $0.title = "Foo Bar Baz" }
        let result = CanvasSearchResult(match: .init(canvas: canvas, matchType: .title(NSRange(location: 4, length: 3))), searchTerm: "Bar")

        XCTAssertNil(result.body)
    }

    func test_body_returnsNumberOfMatchingPagesIfPageMatch() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let canvas = modelController.collection(for: Canvas.self).newObject() { $0.title = "Foo Bar Baz" }
        let result = CanvasSearchResult(match: .init(canvas: canvas, matchType: .pages(4)), searchTerm: "Bar")

        XCTAssertEqual(result.body?.string, "4 matching pages")
    }
}
