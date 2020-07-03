//
//  TextEditorViewModel.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class TextEditorViewModelTests: XCTestCase {

    var modelController: CoppiceModelController!
    var page: Page!
    var textContent: TextPageContent!
    var documentWindowViewModel: MockDocumentWindowViewModel!

    var viewModel: TextEditorViewModel!

    override func setUp() {
        super.setUp()
        self.modelController = CoppiceModelController(undoManager: UndoManager())
        self.textContent = TextPageContent()

        self.page = Page.create(in: self.modelController) {
            $0.content = self.textContent
        }

        self.documentWindowViewModel = MockDocumentWindowViewModel(modelController: self.modelController)
        self.viewModel = TextEditorViewModel(textContent: self.textContent,
                                             documentWindowViewModel: self.documentWindowViewModel,
                                             pageLinkManager: PageLinkManager(pageID: self.page.id, modelController: self.modelController))
    }

    override func tearDown() {
        super.tearDown()

        self.modelController = nil
        self.textContent = nil

        self.viewModel = nil
    }


    //MARK: - .attributedText
    func test_attributedText_returnsContentsText() {
        let expectedText = NSAttributedString(string: "Hello World!")
        self.textContent.text = expectedText

        XCTAssertEqual(self.viewModel.attributedText, expectedText)
    }

    func test_attributedText_setsContentsText() {
        let expectedText = NSAttributedString(string: "Hello World!")
        self.viewModel.attributedText = expectedText

        XCTAssertEqual(self.textContent.text, expectedText)
    }


    //MARK: - createNewLinkedPage(for:)
    func test_createNewLinkedPage_createsNewPageUsingSelectedTextAsTitle() throws {
        self.textContent.text = NSAttributedString(string: "Hello World!")

        let page = self.viewModel.createNewLinkedPage(ofType: .text, from: NSMakeRange(6, 5))
        XCTAssertEqual(page.title, "World")
    }

    func test_createNewLinkedPage_addsLinkToNewPageInContentText() throws {
        let view = MockEditorView()
        self.viewModel.view = view
        self.textContent.text = NSAttributedString(string: "Hello World!")

        let page = self.viewModel.createNewLinkedPage(ofType: .text, from: NSMakeRange(6, 5))

        let (url, range) = try XCTUnwrap(view.addedLink)
        XCTAssertEqual(url, page.linkToPage(from: self.page).url)
        XCTAssertEqual(range, NSMakeRange(6, 5))
    }


    //MARK: - link(to:, for:)
    func test_linkToPage_addsLinkForSuppliedPageToContentText() throws {
        let view = MockEditorView()
        self.viewModel.view = view
        self.textContent.text = NSAttributedString(string: "Hello World!")

        let page = self.modelController.collection(for: Page.self).newObject()
        let expectedTitle = page.title

        self.viewModel.link(to: page, for: NSMakeRange(2, 3))

        XCTAssertEqual(page.title, expectedTitle)

        let (url, range) = try XCTUnwrap(view.addedLink)
        XCTAssertEqual(url, page.linkToPage(from: self.page).url)
        XCTAssertEqual(range, NSMakeRange(2, 3))
    }


    //MARK: - .highligtedRange
    func test_highlightedRange_returnsNilIfNoSearchTerm() {
        self.documentWindowViewModel.searchString = nil

        XCTAssertNil(self.viewModel.highlightedRange)
    }

    func test_highlightedRange_returnsNilIfSearchTermNotFound() {
        self.textContent.text = NSAttributedString(string: "Hello World!")
        self.documentWindowViewModel.searchString = "Foo"

        XCTAssertNil(self.viewModel.highlightedRange)
    }

    func test_highlightedRange_returnsRangeOfFirstMatchInAttributedText() {
        self.textContent.text = NSAttributedString(string: "Hello World!")
        self.documentWindowViewModel.searchString = "World"

        XCTAssertEqual(self.viewModel.highlightedRange, NSRange(location: 6, length: 5))
    }
}

private class MockEditorView: TextEditorView {
    func prepareForDisplay(withSafeAreaInsets safeAreaInsets: NSEdgeInsets) {   
    }

    var addedLink: (URL, NSRange)?
    func addLink(with url: URL, to range: NSRange) {
        self.addedLink = (url, range)
    }


    //Editor
    var inspectors: [Inspector] = []
    var parentEditor: Editor?
    var childEditors: [Editor] = []
    func inspectorsDidChange() {
    }
    func open(_ link: PageLink) {
    }
    var enabled: Bool = true
}
