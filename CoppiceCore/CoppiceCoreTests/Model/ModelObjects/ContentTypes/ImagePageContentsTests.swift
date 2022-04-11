//
//  ImagePageContentsTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 13/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import M3Data
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

    func test_init_setsDescriptionToValueFromMetadata() throws {
        let modelFile = ModelFile(type: "image", filename: nil, data: nil, metadata: ["description": "Hello World"])
        let content = try ImagePageContent(modelFile: modelFile)
        XCTAssertEqual(content.imageDescription, "Hello World")
    }

    func test_init_doesntSetDescriptionIfNotInMetadata() {
        let content = ImagePageContent()
        XCTAssertNil(content.imageDescription)
    }

    func test_init_setsOtherMetadataToAnyOtherValues() throws {
        let modelFile = ModelFile(type: "image", filename: nil, data: nil, metadata: ["bar": "foo", "baz": 42])
        let content = try ImagePageContent(modelFile: modelFile)
        XCTAssertEqual(content.otherMetadata?["bar"] as? String, "foo")
        XCTAssertEqual(content.otherMetadata?["baz"] as? Int, 42)
    }

    func test_init_doesntIncludeImageDescriptionInOtherMetadata() throws {
        let modelFile = ModelFile(type: "image", filename: nil, data: nil, metadata: ["description": "Hello World", "foo": 42])
        let content = try ImagePageContent(modelFile: modelFile)
        XCTAssertEqual(content.otherMetadata?.count, 1)
        XCTAssertEqual(content.otherMetadata?["foo"] as? Int, 42)
        XCTAssertNil(content.otherMetadata?["description"])
    }

    func test_init_setsTheCropRectFromMetadataIfValidString() throws {
        let modelFile = ModelFile(type: "image", filename: nil, data: nil, metadata: ["cropRect": NSStringFromRect(CGRect(x: 20, y: 30, width: 42, height: 55))])
        let content = try ImagePageContent(modelFile: modelFile)
        XCTAssertEqual(content.cropRect, CGRect(x: 20, y: 30, width: 42, height: 55))
    }

    func test_init_setsTheCropRectFromImageIfInvalidStringInMetadata() throws {
        let bundle = Bundle(for: type(of: self))
        let imageURL = bundle.url(forResource: "test-image", withExtension: "png")!
        let image = NSImage(byReferencing: imageURL)
        let imageData = try XCTUnwrap(image.pngData())

        let modelFile = ModelFile(type: "image", filename: nil, data: imageData, metadata:  ["cropRect": "hello world"])
        let content = try ImagePageContent(modelFile: modelFile)
        XCTAssertEqual(content.cropRect, CGRect(origin: .zero, size: image.size))
    }

    func test_init_setsTheCropRectFromImageIfNoStringInMetadata() throws {
        let bundle = Bundle(for: type(of: self))
        let imageURL = bundle.url(forResource: "test-image", withExtension: "png")!
        let image = NSImage(byReferencing: imageURL)
        let imageData = try XCTUnwrap(image.pngData())

        let modelFile = ModelFile(type: "image", filename: nil, data: imageData, metadata: nil)
        let content = try ImagePageContent(modelFile: modelFile)
        XCTAssertEqual(content.cropRect, CGRect(origin: .zero, size: image.size))
    }

    func test_init_setsTheCropRectToZeroIfNoImageAndNoStringInMetadata() throws {
        let modelFile = ModelFile(type: "image", filename: nil, data: nil, metadata: [:])
        let content = try ImagePageContent(modelFile: modelFile)
        XCTAssertEqual(content.cropRect, .zero)
    }

    func test_init_setsHotspotsFromMetadataIfValuesAreValid() throws {
        let modelFile = ModelFile(type: "image", filename: nil, data: nil, metadata: [
            "hotspots": [
                ["kind": "rectangle", "points": [["X": 24, "Y": 32.1], ["X": 42, "Y": 1.23]]],
                ["kind": "oval", "points": [["X": 1, "Y": 2.0], ["X": 3, "Y": 4.0]], "link": "https://coppiceapp.com"],
                ["kind": "polygon", "points": [["X": -1, "Y": -2.0], ["X": -3, "Y": -4.0]]],
            ],
        ])

        let content = try ImagePageContent(modelFile: modelFile)
        XCTAssertEqual(content.hotspots, [
            ImageHotspot(kind: .rectangle, points: [CGPoint(x: 24, y: 32.1), CGPoint(x: 42, y: 1.23)], link: nil),
            ImageHotspot(kind: .oval, points: [CGPoint(x: 1, y: 2.0), CGPoint(x: 3, y: 4.0)], link: URL(string: "https://coppiceapp.com")!),
            ImageHotspot(kind: .polygon, points: [CGPoint(x: -1, y: -2.0), CGPoint(x: -3, y: -4.0)], link: nil),
        ])
    }

    func test_init_setsHotspotsToEmptyArrayIfMetadataValueIsNotArrayOfDictionaries() throws {
        let modelFile = ModelFile(type: "image", filename: nil, data: nil, metadata: [
            "hotspots": 42,
        ])

		let content = try ImagePageContent(modelFile: modelFile)
        XCTAssertEqual(content.hotspots, [])
    }

    func test_init_setsHotspotsToEmptyArrayIfValueIsNotInMetadata() throws {
        let modelFile = ModelFile(type: "image", filename: nil, data: nil, metadata: [:])

        let content = try ImagePageContent(modelFile: modelFile)
        XCTAssertEqual(content.hotspots, [])
    }

    func test_init_throwsErrorIfHotspotDictionaryIsInvalidValue() throws {
        let modelFile = ModelFile(type: "image", filename: nil, data: nil, metadata: [
            "hotspots": [
                ["kind": "rectangle", "points": [["X": 24, "Y": 32.1], ["X": 42, "Y": 1.23]]],
                ["points": [["X": 1, "Y": 2.0], ["X": 3, "Y": 4.0]], "link": URL(string: "https://coppiceapp.com")!],
                ["kind": "polygon", "points": [["X": -1, "Y": -2.0], ["X": -3, "Y": -4.0]]],
            ],
        ])

        XCTAssertThrowsError(try ImagePageContent(modelFile: modelFile)) {
            XCTAssertEqual(($0 as? ImageHotspotErrors), .attributeNotFound("kind"))
        }
    }

    //MARK: - .image
    func test_image_cropRectIsResetToImageSizeWhenImageChanges() throws {
        let bundle = Bundle(for: type(of: self))
        let imageURL = bundle.url(forResource: "test-image", withExtension: "png")!
        let image = NSImage(byReferencing: imageURL)

        let content = ImagePageContent()
        content.cropRect = CGRect(x: 100, y: 80, width: 60, height: 40)
        content.setImage(image, operation: .replace)
        XCTAssertEqual(content.cropRect, CGRect(origin: .zero, size: image.size))
    }

    func test_image_cropRectIsNotChangedIfSettingSameImage() throws {
        let bundle = Bundle(for: type(of: self))
        let imageURL = bundle.url(forResource: "test-image", withExtension: "png")!
        let image = NSImage(byReferencing: imageURL)

        let content = ImagePageContent()
        content.setImage(image, operation: .replace)
        content.cropRect = CGRect(x: 100, y: 80, width: 60, height: 40)
        content.setImage(image, operation: .replace)
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
        content.setImage(image, operation: .replace)

        XCTAssertEqual(content.modelFile.data, expectedData)
    }

    func test_modelFile_dataIsNilIfImageIsNil() {
        let content = ImagePageContent()
        content.setImage(nil, operation: .replace)

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

    func test_modelFile_metadataContainsHotspots() throws {
        let content = ImagePageContent()
        content.hotspots = [
            ImageHotspot(kind: .rectangle, points: [CGPoint(x: 24, y: 32.1), CGPoint(x: 42, y: 1.23)], link: nil),
            ImageHotspot(kind: .oval, points: [CGPoint(x: 1, y: 2.0), CGPoint(x: 3, y: 4.0)], link: URL(string: "https://coppiceapp.com")!),
            ImageHotspot(kind: .polygon, points: [CGPoint(x: -1, y: -2.0), CGPoint(x: -3, y: -4.0)], link: nil),
        ]

        let hotspots = try XCTUnwrap(content.modelFile.metadata?["hotspots"] as? [[String: Any]])

        let hotspot1 = try XCTUnwrap(hotspots[safe: 0])
        XCTAssertEqual(hotspot1["kind"] as? String, "rectangle")
        XCTAssertEqual(hotspot1["points"] as? [[String: Double]], [["X": 24, "Y": 32.1], ["X": 42, "Y": 1.23]])
        XCTAssertNil(hotspot1["link"])

        let hotspot2 = try XCTUnwrap(hotspots[safe: 1])
        XCTAssertEqual(hotspot2["kind"] as? String, "oval")
        XCTAssertEqual(hotspot2["points"] as? [[String: Double]], [["X": 1, "Y": 2.0], ["X": 3, "Y": 4.0]])
        XCTAssertEqual(hotspot2["link"] as? String, "https://coppiceapp.com")

        let hotspot3 = try XCTUnwrap(hotspots[safe: 2])
        XCTAssertEqual(hotspot3["kind"] as? String, "polygon")
        XCTAssertEqual(hotspot3["points"] as? [[String: Double]], [["X": -1, "Y": -2.0], ["X": -3, "Y": -4.0]])
        XCTAssertNil(hotspot3["link"])
    }

    func test_modelFile_metadataContainsOtherMetadata() throws {
        let initialModelFile = ModelFile(type: "image", filename: nil, data: nil, metadata: ["bar": "foo", "baz": 42])
        let content = try ImagePageContent(modelFile: initialModelFile)
        let modelFile = content.modelFile
        XCTAssertEqual(modelFile.metadata?["bar"] as? String, "foo")
        XCTAssertEqual(modelFile.metadata?["baz"] as? Int, 42)
    }

    func test_modelFile_metadataContainsBothOtherMetadataAndDescription() throws {
        let initialModelFile = ModelFile(type: "image", filename: nil, data: nil, metadata: ["bar": "foo", "baz": 42])
        let content = try ImagePageContent(modelFile: initialModelFile)
        content.imageDescription = "Hello!"
        let modelFile = content.modelFile
        XCTAssertEqual(modelFile.metadata?["bar"] as? String, "foo")
        XCTAssertEqual(modelFile.metadata?["baz"] as? Int, 42)
        XCTAssertEqual(modelFile.metadata?["description"] as? String, "Hello!")
    }
}
