//
//  Page.Content.TextsTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 13/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import M3Data
import XCTest

class PageContentTextTests: XCTestCase {
    var modelController: CoppiceModelController!
    var page: Page!
    var content: Page.Content.Text!

    override func setUp() {
        super.setUp()

        self.modelController = CoppiceModelController(undoManager: UndoManager())
        self.content = Page.Content.Text()
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
        let observer = self.modelController.pageCollection.changePublisher.sink { (change) in
            expectation.fulfill()
            XCTAssertEqual(change.changeType, .update)
            XCTAssertTrue(change.didUpdate(\.content))
        }

        self.content.text = NSAttributedString(string: "Hello World")

        self.wait(for: [expectation], timeout: 1)

        observer.cancel()
    }

    func test_text_doesntNotifyOfChangeIfNewValueIsTheSameAsOldValue() {
        self.content.text = NSAttributedString(string: "Hello World")
        let expectation = self.expectation(description: "Called observer")
        expectation.isInverted = true
        let observer = self.modelController.pageCollection.changePublisher.sink { (change) in
            expectation.fulfill()
        }

        self.content.text = NSAttributedString(string: "Hello World")

        self.wait(for: [expectation], timeout: 0.5)

        observer.cancel()
    }


    //MARK: - .initialContentSize
    func test_contentSize_contentSizeisAtLeastTheStandardPageSize() throws {
        let size = try XCTUnwrap(self.content.initialContentSize)
        XCTAssertGreaterThanOrEqual(size.width, Page.standardSize.width)
        XCTAssertGreaterThanOrEqual(size.height, Page.standardSize.height)
    }

    func test_contentSize_contentWidthIsNoLargerThan1_5TimesTheStandardWidthPlusInsets() throws {
        var string = "a b c d e"
        (0..<500).forEach { _ in string = "\(string) a b c d e" }
        self.content.text = NSAttributedString(string: string)
        let size = try XCTUnwrap(self.content.initialContentSize)
        let expectedMax = (Page.standardSize.width * 1.5) + GlobalConstants.textEditorInsets().horizontalInsets + 10
        XCTAssertLessThanOrEqual(size.width, expectedMax)
    }

    func test_contentSize_contentHeightIsNoLargerThan3TimesTheStandardHeightPlusInsets() throws {
        var string = "a b c d e"
        (0..<500).forEach { _ in string = "\(string) a b c d e" }
        self.content.text = NSAttributedString(string: string)
        let size = try XCTUnwrap(self.content.initialContentSize)
        let expectedMax = (Page.standardSize.height * 3) + GlobalConstants.textEditorInsets().verticalInsets + 10
        XCTAssertLessThanOrEqual(size.height, expectedMax)
    }


    //MARK: - sizeToFitContent(currentSize:)
    func test_sizeToFitContent_doesntChangeWidth() throws {
        self.content.text = NSAttributedString(string: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec tincidunt metus vitae posuere efficitur. Aliquam eget dapibus magna. Pellentesque porttitor et sapien ac mattis. Mauris justo urna, dictum in commodo sed, laoreet a est. Vestibulum porta felis non orci egestas, sed sollicitudin dui gravida. Cras gravida dapibus magna, vel bibendum dui euismod et. Nulla pulvinar vitae eros sit amet aliquam. Donec pretium massa ac facilisis gravida. Morbi tincidunt iaculis lacus, ut sagittis ligula laoreet a.\n\nDuis id posuere justo, at mollis elit. Ut malesuada leo ante, ut molestie justo feugiat sit amet. Donec ac tortor mattis, tincidunt ligula vel, tempor dolor. Donec mattis ultricies augue. Nam semper, lectus in faucibus ultricies, nibh erat volutpat mauris, ac dapibus ligula mauris nec libero. Etiam vitae rutrum mauris. Proin in sem ac nisl dignissim lobortis. Proin placerat eros ipsum, et aliquam nibh tincidunt ut. Vivamus sed convallis nisi. Donec tincidunt, leo non sodales eleifend, urna mauris consectetur neque, eget facilisis erat sem nec tellus. Mauris a molestie quam, et facilisis nibh. Curabitur id dui nec lectus rhoncus auctor in a tellus. Cras laoreet sollicitudin est, nec pellentesque ipsum cursus ut.")

        let newSize = self.content.sizeToFitContent(currentSize: CGSize(width: 300, height: 500))
        XCTAssertEqual(newSize.width, 300)
    }

    func test_sizeToFitContent_adjustsHeightToFitTextPlusInsets() throws {
        self.content.text = NSAttributedString(string: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec tincidunt metus vitae posuere efficitur. Aliquam eget dapibus magna. Pellentesque porttitor et sapien ac mattis. Mauris justo urna, dictum in commodo sed, laoreet a est. Vestibulum porta felis non orci egestas, sed sollicitudin dui gravida. Cras gravida dapibus magna, vel bibendum dui euismod et. Nulla pulvinar vitae eros sit amet aliquam. Donec pretium massa ac facilisis gravida. Morbi tincidunt iaculis lacus, ut sagittis ligula laoreet a.\n\nDuis id posuere justo, at mollis elit. Ut malesuada leo ante, ut molestie justo feugiat sit amet. Donec ac tortor mattis, tincidunt ligula vel, tempor dolor. Donec mattis ultricies augue. Nam semper, lectus in faucibus ultricies, nibh erat volutpat mauris, ac dapibus ligula mauris nec libero. Etiam vitae rutrum mauris. Proin in sem ac nisl dignissim lobortis. Proin placerat eros ipsum, et aliquam nibh tincidunt ut. Vivamus sed convallis nisi. Donec tincidunt, leo non sodales eleifend, urna mauris consectetur neque, eget facilisis erat sem nec tellus. Mauris a molestie quam, et facilisis nibh. Curabitur id dui nec lectus rhoncus auctor in a tellus. Cras laoreet sollicitudin est, nec pellentesque ipsum cursus ut.")

        let newSize = self.content.sizeToFitContent(currentSize: CGSize(width: 300, height: 500))
        let textSize = self.content.text.boundingRect(with: CGSize(width: 300, height: 10_000_000), options: [.usesLineFragmentOrigin]).size
        let insets = GlobalConstants.textEditorInsets()
        XCTAssertEqual(newSize.height, textSize.rounded().height + insets.verticalInsets + 20)
    }


    //MARK: - init(data:)
    func test_init_createsTextBasedOnSuppliedData() throws {
        let data = try NSAttributedString(string: "Hello World").data(from: NSRange(location: 0, length: 11), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])

        let content = Page.Content.Text(data: data)
        XCTAssertEqual(content.text.string, "Hello World")
    }

    func test_init_addsAnyMetadataToOtherMetadata() throws {
        let modelFile = ModelFile(type: "text", filename: nil, data: nil, metadata: ["foo": "bar", "hello": "world"])
        let content = try Page.Content.Text(modelFile: modelFile)
        XCTAssertEqual(content.otherMetadata?["foo"] as? String, "bar")
        XCTAssertEqual(content.otherMetadata?["hello"] as? String, "world")
    }


    //MARK: - .modelFile
    func test_modelFile_typeIsTextContentType() {
        self.content.text = NSAttributedString(string: "Hello World")
        let modelFile = self.content.modelFile
        XCTAssertEqual(modelFile.type, Page.ContentType.text.rawValue)
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

    func test_modelFile_metadataIsNilForPlainFile() {
        self.content.text = NSAttributedString(string: "Hello World")
        let modelFile = self.content.modelFile
        XCTAssertNil(modelFile.metadata)
    }

    func test_modelFile_metadataIsSetToOtherMetadata() throws {
        let initialModelFile = ModelFile(type: "text", filename: nil, data: nil, metadata: ["foo": "bar", "hello": "world"])
        let content = try Page.Content.Text(modelFile: initialModelFile)

        let modelFile = content.modelFile
        XCTAssertEqual(modelFile.metadata?["foo"] as? String, "bar")
        XCTAssertEqual(modelFile.metadata?["hello"] as? String, "world")
    }


    //MARK: - firstMatch(forSearchString: :)
    func test_firstRangeOfSearchString_returnsRangeOfMatchInText() {
        self.content.text = NSAttributedString(string: "Hello World")

        XCTAssertEqual(self.content.firstMatch(forSearchString: "lo W")?.range, NSRange(location: 3, length: 4))
    }

    func test_firstRangeOfSearchString_ignoresCaseWhenFindingMatch() {
        self.content.text = NSAttributedString(string: "Hello World")

        XCTAssertEqual(self.content.firstMatch(forSearchString: "lo w")?.range, NSRange(location: 3, length: 4))
    }

    func test_firstRangeOfSearchString_ignoresDiacriticsWhenFindingMatch() {
        self.content.text = NSAttributedString(string: "Hellö World")

        XCTAssertEqual(self.content.firstMatch(forSearchString: "lo W")?.range, NSRange(location: 3, length: 4))
    }

    func test_firstRangeOfSearchString_returnsNilIfNoMatch() {
        self.content.text = NSAttributedString(string: "Hello World")

        XCTAssertNil(self.content.firstMatch(forSearchString: "low"))
    }
}
