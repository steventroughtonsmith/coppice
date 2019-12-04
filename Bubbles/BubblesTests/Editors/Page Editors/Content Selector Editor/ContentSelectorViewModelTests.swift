//
//  ContentSelectorViewModelTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 04/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class ContentSelectorViewModelTests: XCTestCase {

    private class TestDelegate: ContentSelectorViewModelDelegate {
        var calledSelectedType = false
        func selectedType(in viewModel: ContentSelectorViewModel) {
            self.calledSelectedType = true
        }
    }

    var page: Page!
    var modelController: ModelController!
    var viewModel: ContentSelectorViewModel!

    override func setUp() {
        super.setUp()

        self.modelController = BubblesModelController(undoManager: UndoManager())
        self.page = self.modelController.collection(for: Page.self).newObject()
        self.viewModel = ContentSelectorViewModel(page: self.page, modelController: self.modelController)
    }

    //MARK: - selectType(_:)
    func test_selectType_updatesThePageContent() {
        XCTAssertEqual(self.page.content.contentType, .empty)

        self.viewModel.selectType(ContentTypeModel(type: .text, localizedName: "", iconName: ""))

        XCTAssertEqual(self.page.content.contentType, .text)
    }

    func test_selectType_informsDelegateOfContentChange() {
        let delegate = TestDelegate()
        self.viewModel.delegate = delegate

        self.viewModel.selectType(ContentTypeModel(type: .image, localizedName: "", iconName: ""))

        XCTAssertTrue(delegate.calledSelectedType)
    }


    //MARK: - canCreateContent(fromFileAt:)
    func test_canCreateContent_returnsFalseIfTypeIDCantBeFound() {
        let url = URL(string: "http://www.mcubedsw.com")!
        XCTAssertFalse(self.viewModel.canCreateContent(fromFileAt: url))
    }

    func test_canCreateContent_returnsFalseIfContentCannotBeCreatedFromTypeID() {
        let url = Bundle(for: type(of: self)).url(forResource: "test-zip", withExtension: "zip")!
        XCTAssertFalse(self.viewModel.canCreateContent(fromFileAt: url))
    }

    func test_canCreateContent_returnsTrueIfContentCanBeCreatedFromTypeID() {
        let url = Bundle(for: type(of: self)).url(forResource: "test-image", withExtension: "png")!
        XCTAssertTrue(self.viewModel.canCreateContent(fromFileAt: url))
    }


    //MARK: - createContent(fromFileAt:)
    func test_createContent_returnsFalseAndDoesntChangePageIfTypeIDCannotBeFound() {
        let url = URL(string: "http://www.mcubedsw.com")!
        XCTAssertFalse(self.viewModel.createContent(fromFileAt: url))
        XCTAssertEqual(self.page.content.contentType, .empty)
    }

    func test_createContent_returnsFalseAndDoesntChangePageIfContentCannotBeCreatedFromTypeID() {
        let url = Bundle(for: type(of: self)).url(forResource: "test-zip", withExtension: "zip")!
        XCTAssertFalse(self.viewModel.createContent(fromFileAt: url))
        XCTAssertEqual(self.page.content.contentType, .empty)
    }

    func test_createContent_updatesPageWithContentForImageFileAtURL() {
        let url = Bundle(for: type(of: self)).url(forResource: "test-image", withExtension: "png")!
        XCTAssertTrue(self.viewModel.createContent(fromFileAt: url))
        XCTAssertEqual(self.page.content.contentType, .image)
        XCTAssertNotNil((self.page.content as! ImagePageContent).image)
    }

    func test_createContent_updatesPageWithContentForTextFileAtURL() {
        let url = Bundle(for: type(of: self)).url(forResource: "test-rtf", withExtension: "rtf")!
        XCTAssertTrue(self.viewModel.createContent(fromFileAt: url))
        XCTAssertEqual(self.page.content.contentType, .text)
        XCTAssertTrue((self.page.content as! TextPageContent).text.length > 0)
    }

    func test_createContent_informsDelegateOfContentChange() {
        let delegate = TestDelegate()
        self.viewModel.delegate = delegate
        let url = Bundle(for: type(of: self)).url(forResource: "test-image", withExtension: "png")!
        XCTAssertTrue(self.viewModel.createContent(fromFileAt: url))
        XCTAssertTrue(delegate.calledSelectedType)
    }
}
