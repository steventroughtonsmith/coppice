//
//  ImagePageContentsTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 13/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

class ImagePageContentsTests: XCTestCase {
    var modelController: CoppiceModelController!

    override func setUp() {
        super.setUp()
        self.modelController = CoppiceModelController(undoManager: UndoManager())
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

    func test_init_setsOtherMetadataToAnyOtherValues() throws {
        let content = ImagePageContent(metadata: ["bar": "foo", "baz": 42])
        XCTAssertEqual(content.otherMetadata?["bar"] as? String, "foo")
        XCTAssertEqual(content.otherMetadata?["baz"] as? Int, 42)
    }

    func test_init_doesntIncludeImageDescriptionInOtherMetadata() throws {
        let content = ImagePageContent(metadata: ["description": "Hello World", "foo": 42])
        XCTAssertEqual(content.otherMetadata?.count, 1)
        XCTAssertEqual(content.otherMetadata?["foo"] as? Int, 42)
        XCTAssertNil(content.otherMetadata?["description"])
    }

    func test_init_setsTheCropRectFromMetadataIfValidString() throws {
        let content = ImagePageContent(metadata: ["cropRect": NSStringFromRect(CGRect(x: 20, y: 30, width: 42, height: 55))])
        XCTAssertEqual(content.cropRect, CGRect(x: 20, y: 30, width: 42, height: 55))
    }

    func test_init_setsTheCropRectFromImageIfInvalidStringInMetadata() throws {
        let bundle = Bundle(for: type(of: self))
        let imageURL = bundle.url(forResource: "test-image", withExtension: "png")!
        let image = NSImage(byReferencing: imageURL)
        let imageData = try XCTUnwrap(image.pngData())

        let content = ImagePageContent(data: imageData, metadata: ["cropRect": "hello world"])
        XCTAssertEqual(content.cropRect, CGRect(origin: .zero, size: image.size))
    }

    func test_init_setsTheCropRectFromImageIfNoStringInMetadata() throws {
        let bundle = Bundle(for: type(of: self))
        let imageURL = bundle.url(forResource: "test-image", withExtension: "png")!
        let image = NSImage(byReferencing: imageURL)
        let imageData = try XCTUnwrap(image.pngData())

        let content = ImagePageContent(data: imageData)
        XCTAssertEqual(content.cropRect, CGRect(origin: .zero, size: image.size))
    }

    func test_init_setsTheCropRectToZeroIfNoImageAndNoStringInMetadata() throws {
        let content = ImagePageContent(metadata: [:])
        XCTAssertEqual(content.cropRect, .zero)
    }

    //MARK: - .image
    func test_image_cropRectIsResetToImageSizeWhenImageChanges() throws {
        let bundle = Bundle(for: type(of: self))
        let imageURL = bundle.url(forResource: "test-image", withExtension: "png")!
        let image = NSImage(byReferencing: imageURL)

        let content = ImagePageContent()
        content.cropRect = CGRect(x: 100, y: 80, width: 60, height: 40)
        content.image = image
        XCTAssertEqual(content.cropRect, CGRect(origin: .zero, size: image.size))
    }

    func test_image_cropRectIsNotChangedIfSettingSameImage() throws {
        let bundle = Bundle(for: type(of: self))
        let imageURL = bundle.url(forResource: "test-image", withExtension: "png")!
        let image = NSImage(byReferencing: imageURL)

        let content = ImagePageContent()
        content.image = image
        content.cropRect = CGRect(x: 100, y: 80, width: 60, height: 40)
        content.image = image
        XCTAssertEqual(content.cropRect, CGRect(x: 100, y: 80, width: 60, height: 40))
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

    func test_modelFile_metadataContainsCropRect() {
        let content = ImagePageContent()
        content.cropRect = CGRect(x: 20, y: 40, width: 66, height: 88)

        XCTAssertEqual(content.modelFile.metadata?["cropRect"] as? String, NSStringFromRect(CGRect(x: 20, y: 40, width: 66, height: 88)))
    }

    func test_modelFile_metadataContainsOtherMetadata() throws {
        let content = ImagePageContent(metadata: ["bar": "foo", "baz": 42])
        let modelFile = content.modelFile
        XCTAssertEqual(modelFile.metadata?["bar"] as? String, "foo")
        XCTAssertEqual(modelFile.metadata?["baz"] as? Int, 42)
    }

    func test_modelFile_metadataContainsBothOtherMetadataAndDescription() throws {
        let content = ImagePageContent(metadata: ["bar": "foo", "baz": 42])
        content.imageDescription = "Hello!"
        let modelFile = content.modelFile
        XCTAssertEqual(modelFile.metadata?["bar"] as? String, "foo")
        XCTAssertEqual(modelFile.metadata?["baz"] as? Int, 42)
        XCTAssertEqual(modelFile.metadata?["description"] as? String, "Hello!")
    }
}
