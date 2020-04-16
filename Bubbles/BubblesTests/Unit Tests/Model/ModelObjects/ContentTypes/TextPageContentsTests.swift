//
//  TextPageContentsTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 13/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class TextPageContentsTests: XCTestCase {
    var modelController: BubblesModelController!
    var page: Page!
    var content: TextPageContent!

    override func setUp() {
        super.setUp()

        self.modelController = BubblesModelController(undoManager: UndoManager())
        self.content = TextPageContent()
        self.page = Page.create(in: self.modelController) { $0.content = self.content }
    }

    override func tearDown() {
        super.tearDown()
        self.modelController = nil
        self.content = nil
        self.page = nil
    }


    //MARK: - .text
    func test_text_notifiesOfChangeIfNewValueIsDifferent() {
        let expectation = self.expectation(description: "Called observer")
        let observer = self.modelController.collection(for: Page.self).addObserver { (change) in
            expectation.fulfill()
            XCTAssertEqual(change.changeType, .update)
            XCTAssertTrue(change.didUpdate(\.content))
        }

        self.content.text = NSAttributedString(string: "Hello World")

        self.wait(for: [expectation], timeout: 1)

        self.modelController.collection(for: Page.self).removeObserver(observer)
    }

    func test_text_doesntNotifyOfChangeIfNewValueIsTheSameAsOldValue() {
        self.content.text = NSAttributedString(string: "Hello World")
        let expectation = self.expectation(description: "Called observer")
        expectation.isInverted = true
        let observer = self.modelController.collection(for: Page.self).addObserver { (change) in
            expectation.fulfill()
        }

        self.content.text = NSAttributedString(string: "Hello World")

        self.wait(for: [expectation], timeout: 0.5)

        self.modelController.collection(for: Page.self).removeObserver(observer)
    }


    //MARK: - .contentSize
    func test_contentSize_contentSizeisAtLeastTheStandardPageSize() throws {
        let size = try XCTUnwrap(self.content.contentSize)
        XCTAssertGreaterThanOrEqual(size.width, Page.standardSize.width)
        XCTAssertGreaterThanOrEqual(size.height, Page.standardSize.height)
    }

    func test_contentSize_contentWidthIsNoLargerThan1_5TimesTheStandardWidthPlusInsets() throws {
        var string = "a b c d e"
        (0..<500).forEach { _ in string = "\(string) a b c d e"}
        self.content.text = NSAttributedString(string: string)
        let size = try XCTUnwrap(self.content.contentSize)
        let expectedMax = (Page.standardSize.width * 1.5) + GlobalConstants.textEditorInsets.horizontalInsets + 10
        XCTAssertLessThanOrEqual(size.width, expectedMax)
    }

    func test_contentSize_contentHeightIsNoLargerThan3TimesTheStandardHeightPlusInsets() throws {
        var string = "a b c d e"
        (0..<500).forEach { _ in string = "\(string) a b c d e"}
        self.content.text = NSAttributedString(string: string)
        let size = try XCTUnwrap(self.content.contentSize)
        let expectedMax = (Page.standardSize.height * 3) + GlobalConstants.textEditorInsets.verticalInsets + 10
        XCTAssertLessThanOrEqual(size.height, expectedMax)
    }


    //MARK: - init(data:)
    func test_init_createsTextBasedOnSuppliedData() throws {
        let data = try NSAttributedString(string: "Hello World").data(from: NSRange(location: 0, length: 11), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])

        let content = TextPageContent(data: data)
        XCTAssertEqual(content.text.string, "Hello World")
    }


    //MARK: - .modelFile
    func test_modelFile_typeIsTextContentType() {
        self.content.text = NSAttributedString(string: "Hello World")
        let modelFile = self.content.modelFile
        XCTAssertEqual(modelFile.type, PageContentType.text.rawValue)
    }

    func test_modelFile_fileNameContainsPageIDAndRTFExtension() {
        self.content.text = NSAttributedString(string: "Hello World")
        let modelFile = self.content.modelFile
        XCTAssertEqual((modelFile.filename! as NSString).pathExtension, "rtf")
        XCTAssertEqual((modelFile.filename! as NSString).deletingPathExtension, self.page.id.uuid.uuidString)
    }

    func test_modelFile_dataIsRTFVersionOfText() throws {
        self.content.text = NSAttributedString(string: "Hello World")
        let expectedData = try NSAttributedString(string: "Hello World").data(from: NSRange(location: 0, length: 11), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        let modelFile = self.content.modelFile
        XCTAssertEqual(modelFile.data, expectedData)
    }

    func test_modelFile_metadataIsNil() {
        self.content.text = NSAttributedString(string: "Hello World")
        let modelFile = self.content.modelFile
        XCTAssertNil(modelFile.metadata)
    }


    //MARK: - firstRangeOf(_:)
    func test_firstRangeOfSearchString_returnsRangeOfMatchInText() {
        self.content.text = NSAttributedString(string: "Hello World")

        XCTAssertEqual(self.content.firstRangeOf("lo W"), NSRange(location: 3, length: 4))
    }

    func test_firstRangeOfSearchString_ignoresCaseWhenFindingMatch() {
        self.content.text = NSAttributedString(string: "Hello World")

        XCTAssertEqual(self.content.firstRangeOf("lo w"), NSRange(location: 3, length: 4))
    }

    func test_firstRangeOfSearchString_ignoresDiacriticsWhenFindingMatch() {
        self.content.text = NSAttributedString(string: "Hellö World")

        XCTAssertEqual(self.content.firstRangeOf("lo W"), NSRange(location: 3, length: 4))
    }

    func test_firstRangeOfSearchString_returnsNSNotFoundLocationIfNoMatch() {
        self.content.text = NSAttributedString(string: "Hello World")

        XCTAssertEqual(self.content.firstRangeOf("low"), NSRange(location: NSNotFound, length: 0))
    }
}
