//
//  PageTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import M3Data
import XCTest

class PageTests: XCTestCase {
    //MARK: - .plistRepresentation
    func test_plistRepresentation_containsID() throws {
        let page = Page()
        XCTAssertEqual(try page.plistRepresentation[.id], page.id.stringRepresentation)
    }

    func test_plistRepresentation_containsTitle() throws {
        let page = Page()
        page.title = "Foobar"
        XCTAssertEqual(try page.plistRepresentation[Page.PlistKeys.title], "Foobar")
    }

    func test_plistRepresentation_containsDateCreated() throws {
        let page = Page()
        page.dateCreated = Date(timeIntervalSinceReferenceDate: 31)
        XCTAssertEqual(try page.plistRepresentation[Page.PlistKeys.dateCreated], Date(timeIntervalSinceReferenceDate: 31))
    }

    func test_plistRepresentation_containsDateModified() throws {
        let page = Page()
        page.dateModified = Date(timeIntervalSinceReferenceDate: 12345)
        XCTAssertEqual(try page.plistRepresentation[Page.PlistKeys.dateModified], Date(timeIntervalSinceReferenceDate: 12345))
    }

    func test_plistRepresentation_containsUserPreferredSizeIfSet() throws {
        let page = Page()
        page.contentSize = CGSize(width: 200, height: 300)
        XCTAssertEqual(try page.plistRepresentation[Page.PlistKeys.userPreferredSize], CGSize(width: 200, height: 300))
    }

    func test_plistRepresentation_doesntContainUserPreferredSizeIfSet() throws {
        let page = Page()
        let preferredSize: CGSize? = try page.plistRepresentation[Page.PlistKeys.userPreferredSize]
        XCTAssertNil(preferredSize)
    }

    func test_plistRepresentation_containsContentForTextContent() throws {
        let textContent = Page.Content.Text()
        textContent.text = NSAttributedString(string: "foobar")
        let page = Page()
        page.content = textContent

        let expectedContent = ModelFile(type: Page.ContentType.text.rawValue,
                                        filename: "\(page.id.uuid.uuidString).rtf",
                                        data: try textContent.text.data(from: NSRange(location: 0, length: 6), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]),
                                        metadata: nil)

        let content: ModelFile = try page.plistRepresentation[required: Page.PlistKeys.content]
        XCTAssertEqual(content.type, expectedContent.type)
        XCTAssertEqual(content.filename, expectedContent.filename)
        XCTAssertEqual(content.data, expectedContent.data)
    }

    func test_plistRepresentation_containsContentForImageContent() throws {
        let imageContent = Page.Content.Image()
        imageContent.setImage(NSImage(named: "NSAddTemplate"), operation: .replace)
        imageContent.imageDescription = "Foo Bar Baz"
        let page = Page()
        page.content = imageContent

        let expectedContent = ModelFile(type: Page.ContentType.image.rawValue,
                                        filename: "\(page.id.uuid.uuidString).png",
                                        data: imageContent.image?.pngData(),
                                        metadata: ["description": "Foo Bar Baz"])

        let content: ModelFile = try page.plistRepresentation[required: Page.PlistKeys.content]
        XCTAssertEqual(content.type, expectedContent.type)
        XCTAssertEqual(content.filename, expectedContent.filename)
        XCTAssertEqual(content.data, expectedContent.data)
        XCTAssertEqual(content.metadata?["description"] as? String, "Foo Bar Baz")
    }

    func test_plistRepresentation_includesAnyOtherProperties() throws {
        let page = Page()
        page.contentSize = CGSize(width: 3, height: 4)
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1238),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9872),
            Page.PlistKeys.content: ModelFile(type: "text", filename: nil, data: nil, metadata: nil),
            ModelPlistKey(rawValue: "foo"): "bar",
            ModelPlistKey(rawValue: "testing"): Date(timeIntervalSinceReferenceDate: 11),
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)))

        let plistRepresentation = try page.plistRepresentation

        XCTAssertEqual(try plistRepresentation[ModelPlistKey(rawValue: "foo")], "bar")
        XCTAssertEqual(try plistRepresentation[ModelPlistKey(rawValue: "testing")], Date(timeIntervalSinceReferenceDate: 11))
    }


    //MARK: - update(fromPlistRepresentation:)
    func test_updateFromPlistRepresentation_doesntUpdateIfIDsDontMatch() {
        let page = Page()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: "foobar",
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1234),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9876),
            Page.PlistKeys.content: ModelFile(type: "text", filename: nil, data: nil, metadata: nil),
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .idsDontMatch)
        }
    }

    func test_updateFromPlistRepresentation_updatesTitle() {
        let page = Page()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1235),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9875),
            Page.PlistKeys.content: ModelFile(type: "text", filename: nil, data: nil, metadata: nil),
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)))

        XCTAssertEqual(page.title, "Lorem Ipsum")
    }

    func test_updateFromPlistRepresentation_throwsIfTitleMissing() {
        let page = Page()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1235),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9875),
            Page.PlistKeys.content: ModelFile(type: "text", filename: nil, data: nil, metadata: nil),
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("title"))
        }
    }

    func test_updateFromPlistRepresentation_updatesDateCreated() {
        let page = Page()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1236),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9874),
            Page.PlistKeys.content: ModelFile(type: "text", filename: nil, data: nil, metadata: nil),
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)))

        XCTAssertEqual(page.dateCreated, Date(timeIntervalSinceReferenceDate: 1236))
    }

    func test_updateFromPlistRepresentation_throwsIfDateCreatedMissing() {
        let page = Page()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9874),
            Page.PlistKeys.content: ModelFile(type: "text", filename: nil, data: nil, metadata: nil),
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("dateCreated"))
        }
    }

    func test_updateFromPlistRepresentation_updatesDateModified() {
        let page = Page()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1237),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9873),
            Page.PlistKeys.content: ModelFile(type: "text", filename: nil, data: nil, metadata: nil),
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)))

        XCTAssertEqual(page.dateModified, Date(timeIntervalSinceReferenceDate: 9873))
    }

    func test_updateFromPlistRepresentation_throwsIfDateModifiedMissing() {
        let page = Page()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1237),
            Page.PlistKeys.content: ModelFile(type: "empty", filename: nil, data: nil, metadata: nil),
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("dateModified"))
        }
    }

    func test_updateFromPlistRepresentation_updatesUserPreferredSizeIfInPlist() {
        let page = Page()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1238),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9872),
            Page.PlistKeys.userPreferredSize: NSStringFromSize(CGSize(width: 320, height: 480)),
            Page.PlistKeys.content: ModelFile(type: "text", filename: nil, data: nil, metadata: nil),
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)))

        XCTAssertEqual(page.contentSize, CGSize(width: 320, height: 480))
    }

    func test_updateFromPlistRepresentation_setsUserPreferredSizeToNilIfNotInPlist() {
        let page = Page()
        page.contentSize = CGSize(width: 3, height: 4)
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1238),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9872),
            Page.PlistKeys.content: ModelFile(type: "text", filename: nil, data: nil, metadata: nil),
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)))

        XCTAssertEqual(page.contentSize, Page.standardSize)
    }

    func test_updateFromPlistRepresentation_updatesContentToTextContentIfTextContentInPlist() throws {
        let page = Page()
        let data = try NSAttributedString(string: "Foobar Baz", attributes: [.font: NSFont.systemFont(ofSize: 5)]).data(from: NSRange(location: 0, length: 10),
                                                                                                                        documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1238),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9872),
            Page.PlistKeys.content: ModelFile(type: "text", filename: "\(page.id.uuid.uuidString).rtf", data: data, metadata: nil),
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)))

        XCTAssertEqual(page.content.contentType, .text)
        let expectedString = try NSAttributedString(data: data, options: [:], documentAttributes: nil)
        XCTAssertEqual((page.content as? Page.Content.Text)?.text, expectedString)
    }

    func test_updateFromPlistRepresentation_updatesContentToImageContentIfImageContentInPlist() {
        let page = Page()
        guard let data = NSImage(named: "NSAddTemplate")?.pngData() else {
            XCTFail("Couldn't generate PDF data")
            return
        }
        let image = NSImage(data: data)
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1238),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9872),
            Page.PlistKeys.content: ModelFile(type: "image", filename: "\(page.id.uuid.uuidString).png", data: data, metadata: ["description": "Hello World"]),
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)))

        XCTAssertEqual(page.content.contentType, .image)
        XCTAssertEqual((page.content as? Page.Content.Image)?.image?.tiffRepresentation, image?.tiffRepresentation)
        XCTAssertEqual((page.content as? Page.Content.Image)?.imageDescription, "Hello World")
    }

    func test_updateFromPlistRepresentation_throwsIfContentMissing() {
        let page = Page()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1239),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9871),
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("content"))
        }
    }

    func test_updateFromPlistRepresentation_throwsIfContentTypeIsNotValid() {
        let page = Page()
        page.content = Page.Content.Text()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1238),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9872),
            Page.PlistKeys.content: ModelFile(type: "foobar", filename: nil, data: nil, metadata: nil),
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("content"))
        }
    }

    func test_updateFromPlistRepresentation_addsAnythingElseInPlistToOtherProperties() throws {
        let page = Page()
        page.contentSize = CGSize(width: 3, height: 4)
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            ModelPlistKey(rawValue: "testing"): Date(timeIntervalSinceReferenceDate: 11),
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1238),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9872),
            Page.PlistKeys.content: ModelFile(type: "text", filename: nil, data: nil, metadata: nil),
            ModelPlistKey(rawValue: "foo"): "bar",
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)))

        XCTAssertEqual(page.otherProperties[ModelPlistKey(rawValue: "foo")] as? String, "bar")
        XCTAssertEqual(page.otherProperties[ModelPlistKey(rawValue: "testing")] as? Date, Date(timeIntervalSinceReferenceDate: 11))
    }

    func test_updateFromPlistRepresentation_doesntIncludeAnySupportPlistKeysInOtherProperties() throws {
        let page = Page()
        page.contentSize = CGSize(width: 3, height: 4)
        let plist: [ModelPlistKey: PlistValue] = [
            .id: page.id.stringRepresentation,
            ModelPlistKey(rawValue: "testing"): Date(timeIntervalSinceReferenceDate: 11),
            Page.PlistKeys.title: "Lorem Ipsum",
            Page.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 1238),
            Page.PlistKeys.dateModified: Date(timeIntervalSinceReferenceDate: 9872),
            Page.PlistKeys.content: ModelFile(type: "text", filename: nil, data: nil, metadata: nil),
            ModelPlistKey(rawValue: "foo"): "bar",
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: .init(id: page.id, plist: plist)))

        XCTAssertEqual(page.otherProperties.count, 2)
        for key in Page.PlistKeys.all {
            XCTAssertNil(page.otherProperties[key])
        }
    }


    //MARK: - updatePageSizes()
    func test_updatePagesSizes_doesntUpdateAnySizesIfUserPreferredSizeIsSet() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let page = modelController.collection(for: Page.self).newObject() {
            let content = Page.Content.Image()
            content.setImage(NSImage(size: NSSize(width: 50, height: 30)), operation: .replace)
            $0.content = content
        }
        let canvas1 = modelController.collection(for: Canvas.self).newObject()
        let canvas2 = modelController.collection(for: Canvas.self).newObject()
        let canvasPage1 = try XCTUnwrap(canvas1.addPages([page]).first)
        let canvasPage2 = try XCTUnwrap(canvas2.addPages([page]).first)

        canvasPage1.frame = CGRect(x: 20, y: 30, width: 40, height: 50)
        canvasPage2.frame = CGRect(x: 60, y: 70, width: 80, height: 90)

        page.contentSize = CGSize(width: 50, height: 40)

        page.updatePageSizes()

        XCTAssertEqual(canvasPage1.frame, CGRect(x: 20, y: 30, width: 40, height: 50))
        XCTAssertEqual(canvasPage2.frame, CGRect(x: 60, y: 70, width: 80, height: 90))
    }

    func test_updatePageSizes_updatesFrameSizeOfPageOnAllCanvasesIfUserPreferredSizeIsNotSet() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let page = modelController.collection(for: Page.self).newObject() {
            let content = Page.Content.Image()
            content.setImage(NSImage(size: NSSize(width: 50, height: 30)), operation: .replace)
            $0.content = content
        }
        let canvas1 = modelController.collection(for: Canvas.self).newObject()
        let canvas2 = modelController.collection(for: Canvas.self).newObject()
        let canvasPage1 = try XCTUnwrap(canvas1.addPages([page]).first)
        let canvasPage2 = try XCTUnwrap(canvas2.addPages([page]).first)

        canvasPage1.frame = CGRect(x: 20, y: 30, width: 40, height: 50)
        canvasPage2.frame = CGRect(x: 60, y: 70, width: 80, height: 90)

        page.updatePageSizes()

        XCTAssertEqual(canvasPage1.frame, CGRect(x: 20, y: 30, width: 50, height: 30))
        XCTAssertEqual(canvasPage2.frame, CGRect(x: 60, y: 70, width: 50, height: 30))
    }


    //MARK: - .sortType
    func test_sortType_textPageAppearsAboveImagePage() {
        let textPage = Page()
        textPage.content = Page.Content.Text()

        let imagePage = Page()
        imagePage.content = Page.Content.Image()

        XCTAssertTrue(textPage.sortType < imagePage.sortType)
    }


    //MARK: - ModelCollection<Page>

    //MARK: - setContentValue(_:for:ofPageWithID:)
    func test_setContentValueForKeyPathOfPageWithID_updatesTheContentIfPageExists() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let collection = modelController.collection(for: Page.self)
        let content = Page.Content.Text()
        content.text = NSAttributedString(string: "Foo Bar")
        let page = collection.newObject() {
            $0.content = content
        }

        let newValue = NSAttributedString(string: "Hello World")
        collection.setContentValue(newValue, for: \ Page.Content.Text.text, ofPageWithID: page.id)
        XCTAssertEqual(content.text, newValue)
    }

    func test_setContentValueForKeyPathOfPageWithID_doesntUpdateTheContentIfPageCantBeFound() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let collection = modelController.collection(for: Page.self)
        let content = Page.Content.Text()
        content.text = NSAttributedString(string: "Foo Bar")
        _ = collection.newObject() {
            $0.content = content
        }

        let newValue = NSAttributedString(string: "Hello World")
        collection.setContentValue(newValue, for: \ Page.Content.Text.text, ofPageWithID: Page.modelID(with: UUID()))
        XCTAssertEqual(content.text, NSAttributedString(string: "Foo Bar"))
    }
}
