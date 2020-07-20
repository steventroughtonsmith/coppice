//
//  ModelObjects+SearchingTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 15/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import CoppiceCore

class ModelObjects_SearchingTests: XCTestCase {

    //MARK: - Page

    //MARK: - Page.Match.compare
    func test_pageMatch_compare_titleIsLowerThanContent() {
        let page1 = Page()
        page1.title = "Foo"
        let match1 = Page.Match(page: page1, matchType: .title(NSRange(location: 0, length: 3)))

        let page2 = Page()
        page2.title = "Bar"
        let match2 = Page.Match(page: page2, matchType: .content(NSRange(location: 0, length: 3)))

        XCTAssertTrue(match1 < match2)
    }

    func test_pageMatch_compare_titlesAreSortedByString() {
        let page1 = Page()
        page1.title = "Foo"
        let match1 = Page.Match(page: page1, matchType: .title(NSRange(location: 0, length: 3)))

        let page2 = Page()
        page2.title = "Bar"
        let match2 = Page.Match(page: page2, matchType: .title(NSRange(location: 1, length: 2)))

        XCTAssertTrue(match2 < match1)
    }

    func test_pageMatch_compare_contentIsSortedByMatchLocation() {
        let page1 = Page()
        page1.title = "Foo"
        let match1 = Page.Match(page: page1, matchType: .content(NSRange(location: 3, length: 3)))

        let page2 = Page()
        page2.title = "Bar"
        let match2 = Page.Match(page: page2, matchType: .content(NSRange(location: 0, length: 3)))

        XCTAssertTrue(match2 < match1)
    }


    //MARK: - Page.match(forSearchTerm:)
    func test_page_matchForSearchTerm_returnsMatchInTitle() {
        let page = Page()
        page.title = "Foo Bar Baz"

        let match = page.match(forSearchTerm: "Bar")
        XCTAssertEqual(match?.page, page)
        XCTAssertEqual(match?.matchType, .title(NSRange(location: 4, length: 3)))
    }

    func test_page_matchForSearchTerm_ignoresCaseForTitleMatching() {
        let page = Page()
        page.title = "Foo Bar Baz"

        let match = page.match(forSearchTerm: "BAR")
        XCTAssertEqual(match?.page, page)
        XCTAssertEqual(match?.matchType, .title(NSRange(location: 4, length: 3)))
    }

    func test_page_matchForSearchTerm_ignroesDiacriticsForTitleMatching() {
        let page = Page()
        page.title = "Foo Bár Baz"

        let match = page.match(forSearchTerm: "Bar")
        XCTAssertEqual(match?.page, page)
        XCTAssertEqual(match?.matchType, .title(NSRange(location: 4, length: 3)))
    }

    func test_page_matchForSearchTerm_returnsMatchInTitleEvenIfAlsoMatchInContent() {
        let mockPageContent = MockPageContent()
        mockPageContent.searchRange = NSRange(location: 4, length: 10)
        let page = Page()
        page.title = "Hello World"
        page.content = mockPageContent

        let match = page.match(forSearchTerm: "World")
        XCTAssertEqual(match?.page, page)
        XCTAssertEqual(match?.matchType, .title(NSRange(location: 6, length: 5)))
    }

    func test_page_matchForSearchTerm_returnsMatchInContentIfNoneInTitle() {
        let mockPageContent = MockPageContent()
        mockPageContent.searchRange = NSRange(location: 4, length: 10)
        let page = Page()
        page.title = "Hello World"
        page.content = mockPageContent

        let match = page.match(forSearchTerm: "Bar")
        XCTAssertEqual(match?.page, page)
        XCTAssertEqual(match?.matchType, .content(NSRange(location: 4, length: 10)))
    }


    //MARK: - ModelCollection<Page>.matches(forSearchTerm)
    func test_modelCollectionPage_matchesForSearchTerm_returnsPagesThatMatchInOrderOfBestMatch() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let page1 = Page.create(in: modelController) {
            $0.title = "Foo Bar Baz"
            $0.content = TextPageContent()
        }

        _ = Page.create(in: modelController) {
            $0.title = "No Matches"
            $0.content = TextPageContent()
        }

        let page3 = Page.create(in: modelController) {
            $0.title = "No Match in title"
            let page3Content = TextPageContent()
            page3Content.text = NSAttributedString(string: "A brief history of bars")
            $0.content = page3Content
        }

        let page4 = Page.create(in: modelController) {
            $0.title = "A cool bar"
            $0.content = TextPageContent()
        }

        let page5 = Page.create(in: modelController) {
            $0.title = "No Match in title"
            let page5Content = TextPageContent()
            page5Content.text = NSAttributedString(string: "This, bar none!")
            $0.content = page5Content
        }


        let matches = modelController.collection(for: Page.self).matches(forSearchTerm: "Bar")
        let pages = matches.map(\.page)
        XCTAssertEqual(pages, [page4, page1, page5, page3])
    }



    //MARK: - Canvas

    //MARK: - Canvas.Match.compare
    func test_canvasMatch_compare_titleIsLowerThanPages() {
        let canvas1 = Canvas()
        canvas1.title = "Foo"
        let match1 = Canvas.Match(canvas: canvas1, matchType: .title(NSRange(location: 0, length: 3)))

        let canvas2 = Canvas()
        canvas2.title = "Bar"
        let match2 = Canvas.Match(canvas: canvas2, matchType: .pages(4))

        XCTAssertTrue(match1 < match2)
    }

    func test_canvasMatch_compare_titlesAreSortedByString() {
        let canvas1 = Canvas()
        canvas1.title = "Foo"
        let match1 = Canvas.Match(canvas: canvas1, matchType: .title(NSRange(location: 0, length: 3)))

        let canvas2 = Canvas()
        canvas2.title = "Bar"
        let match2 = Canvas.Match(canvas: canvas2, matchType: .title(NSRange(location: 4, length: 3)))

        XCTAssertTrue(match2 < match1)
    }

    func test_canvasMatch_compare_pagesAreSortedByCount() {
        let canvas1 = Canvas()
        canvas1.title = "Foo"
        let match1 = Canvas.Match(canvas: canvas1, matchType: .pages(8))

        let canvas2 = Canvas()
        canvas2.title = "Bar"
        let match2 = Canvas.Match(canvas: canvas2, matchType: .pages(4))

        XCTAssertTrue(match1 < match2)
    }


    //MARK: - Canvas.match(forSearchTerm:)
    func test_canvas_matchForSearchTerm_returnsMatchInTitle() {
        let canvas = Canvas()
        canvas.title = "OMG Possum!"

        let match = canvas.match(forSearchTerm: "Possum")
        XCTAssertEqual(match?.canvas, canvas)
        XCTAssertEqual(match?.matchType, .title(NSRange(location: 4, length: 6)))
    }

    func test_canvas_matchForSearchTerm_ignoresCaseForTitleMatching() {
        let canvas = Canvas()
        canvas.title = "OMG Possum!"

        let match = canvas.match(forSearchTerm: "POSSUM")
        XCTAssertEqual(match?.canvas, canvas)
        XCTAssertEqual(match?.matchType, .title(NSRange(location: 4, length: 6)))
    }

    func test_canvas_matchForSearchTerm_ignoresDiacriticsForTitleMatching() {
        let canvas = Canvas()
        canvas.title = "OMG Pössüm!"

        let match = canvas.match(forSearchTerm: "Possum")
        XCTAssertEqual(match?.canvas, canvas)
        XCTAssertEqual(match?.matchType, .title(NSRange(location: 4, length: 6)))
    }

    func test_canvas_matchForSearchTerm_returnsMatchInTitleEvenIfAlsoMatchesInPages() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let page = Page.create(in: modelController) { $0.title = "possums" }
        let canvas = Canvas.create(in: modelController) { $0.title = "OMG Possums!" }
        _ = CanvasPage.create(in: modelController) {
            $0.page = page
            $0.canvas = canvas
        }
        canvas.title = "OMG Possum!"

        let match = canvas.match(forSearchTerm: "Possum")
        XCTAssertEqual(match?.canvas, canvas)
        XCTAssertEqual(match?.matchType, .title(NSRange(location: 4, length: 6)))
    }

    func test_canvas_matchForSearchTerm_returnsMatchInPagesIfNoneInTitle() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let page = Page.create(in: modelController) { $0.title = "possums" }
        let canvas = Canvas.create(in: modelController) { $0.title = "OMG Possums!" }
        _ = CanvasPage.create(in: modelController) {
            $0.page = page
            $0.canvas = canvas
        }
        canvas.title = "No Match!"

        let match = canvas.match(forSearchTerm: "Possum")
        XCTAssertEqual(match?.canvas, canvas)
        XCTAssertEqual(match?.matchType, .pages(1))
    }

    //MARK: - ModelCollection<Canvas>.matches(forSearchTerm:)
    func test_modelCollectionCanvas_matchesForSearchTerm_returnsCanvasesThatMatchInOrderOfBestMatch() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas1 = Canvas.create(in: modelController) { $0.title = "Some Possum content" }
        let canvas2 = Canvas.create(in: modelController) { $0.title = "Page match 1" }
        _ = Canvas.create(in: modelController) { $0.title = "No matches" }
        let canvas4 = Canvas.create(in: modelController) { $0.title = "Page match 2" }
        let canvas5 = Canvas.create(in: modelController) { $0.title = "Look, Possums!" }

        let page1 = Page.create(in: modelController) { $0.title = "My Possum" }
        let page2 = Page.create(in: modelController) { $0.title = "Your Possum" }
        let page3 = Page.create(in: modelController) { $0.title = "All our Possums!" }
        let page4 = Page.create(in: modelController) { $0.title = "Badger!" }

        CanvasPage.create(in: modelController) {
            $0.canvas = canvas2
            $0.page = page1
        }

        CanvasPage.create(in: modelController) {
            $0.canvas = canvas2
            $0.page = page4
        }

        CanvasPage.create(in: modelController) {
            $0.canvas = canvas4
            $0.page = page2
        }

        CanvasPage.create(in: modelController) {
            $0.canvas = canvas4
            $0.page = page3
        }


        let matches = modelController.collection(for: Canvas.self).matches(forSearchTerm: "possum")
        let canvases = matches.map(\.canvas)
        XCTAssertEqual(canvases, [canvas5, canvas1, canvas4, canvas2])
    }
}
