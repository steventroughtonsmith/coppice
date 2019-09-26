//
//  TextEditorViewModel.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class TextEditorViewModelTests: XCTestCase {

    var modelController: ModelController!
    var textContent: TextPageContent!

    var viewModel: TextEditorViewModel!

    override func setUp() {
        super.setUp()
        self.modelController = BubblesModelController(undoManager: UndoManager())
        self.textContent = TextPageContent()

        self.viewModel = TextEditorViewModel(textContent: self.textContent, modelController: self.modelController)
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

        XCTAssertEqual(self.modelController.collection(for: Page.self).all.count, 0)

        self.viewModel.createNewLinkedPage(for: NSMakeRange(6, 5))

        let page = try XCTUnwrap(Array(self.modelController.collection(for: Page.self).all).first)
        XCTAssertEqual(page.title, "World")
    }

    func test_createNewLinkedPage_addsLinkToNewPageInContentText() throws {
        self.textContent.text = NSAttributedString(string: "Hello World!")

        XCTAssertEqual(self.modelController.collection(for: Page.self).all.count, 0)

        self.viewModel.createNewLinkedPage(for: NSMakeRange(6, 5))

        let page = try XCTUnwrap(Array(self.modelController.collection(for: Page.self).all).first)

        var rangePointer: NSRange = NSMakeRange(0, 0)
        let attribute = self.textContent.text.attribute(.link, at: 6, effectiveRange: &rangePointer)

        XCTAssertEqual((attribute as? URL), page.linkingURL)
        XCTAssertEqual(rangePointer, NSMakeRange(6, 5))
    }


    //MARK: - link(to:, for:)
    func test_linkToPage_addsLinkForSuppliedPageToContentText() {
        self.textContent.text = NSAttributedString(string: "Hello World!")

        let page = self.modelController.collection(for: Page.self).newPage()
        let expectedTitle = page.title

        self.viewModel.link(to: page, for: NSMakeRange(2, 3))

        XCTAssertEqual(page.title, expectedTitle)

        var rangePointer: NSRange = NSMakeRange(0, 0)
        let attribute = self.textContent.text.attribute(.link, at: 2, effectiveRange: &rangePointer)

        XCTAssertEqual((attribute as? URL), page.linkingURL)
        XCTAssertEqual(rangePointer, NSMakeRange(2, 3))
    }
}
