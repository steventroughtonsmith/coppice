//
//  ImagePageContentsTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 13/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class ImagePageContentsTests: XCTestCase {

    var modelController: BubblesModelController!

    override func setUp() {
        super.setUp()
        self.modelController = BubblesModelController(undoManager: UndoManager())
    }

    override func tearDown() {
        super.tearDown()
        self.modelController = nil
    }


    //MARK: - .init(data:metadata:)
    func test_init_createsImageFromSuppliedData() throws {
        let bundle = Bundle(for: type(of: self))
        let imageURL = bundle.url(forResource: "test-image", withExtension: "png")!
        let image = NSImage(byReferencing: imageURL)
        let imageData = try XCTUnwrap(image.pngData())

        let content = ImagePageContent(data: imageData)
        XCTAssertEqual(content.image?.pngData(), imageData)
    }

    func test_init_setsDescriptionToValueFromMetadata() {
        let content = ImagePageContent(metadata: ["description": "Hello World"])
        XCTAssertEqual(content.imageDescription, "Hello World")
    }

    func test_init_doesntSetDescriptionIfNotInMetadata() {
        let content = ImagePageContent()
        XCTAssertNil(content.imageDescription)
    }


    //MARK: - .modelFile
    func test_modelFile_typeIsSetToImageType() {
        let content = ImagePageContent()

        XCTAssertEqual(content.modelFile.type, PageContentType.image.rawValue)
    }

    func test_modelFile_filenameContainsPageIDAndPNGExtension() throws {
        let content = ImagePageContent()
        let page = Page()
        content.page = page

        let filename = try XCTUnwrap(content.modelFile.filename)
        XCTAssertEqual((filename as NSString).pathExtension, "png")
        XCTAssertEqual((filename as NSString).deletingPathExtension, page.id.uuid.uuidString)
    }

    func test_modelFile_dataIsPNGRepresentationOfImage() {
        let bundle = Bundle(for: type(of: self))
        let imageURL = bundle.url(forResource: "test-image", withExtension: "png")!
        let image = NSImage(byReferencing: imageURL)
        let expectedData = image.pngData()

        let content = ImagePageContent()
        content.image = image

        XCTAssertEqual(content.modelFile.data, expectedData)
    }

    func test_modelFile_dataIsNilIfImageIsNil() {
        let content = ImagePageContent()
        content.image = nil

        XCTAssertNil(content.modelFile.data)
    }

    func test_modelFile_metadataContainsDescriptionIfOneIsSet() {
        let content = ImagePageContent()
        content.imageDescription = "Hello World"

        XCTAssertEqual(content.modelFile.metadata?["description"] as? String, "Hello World")
    }

    func test_modelFile_metadataDoesntContainDescriptionIfOneIsntSet() {
        let content = ImagePageContent()
        content.imageDescription = nil

        XCTAssertNil(content.modelFile.metadata?["description"])
    }

}
