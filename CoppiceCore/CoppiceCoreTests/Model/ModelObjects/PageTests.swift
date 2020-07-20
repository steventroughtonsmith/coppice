//
//  PageTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import CoppiceCore

class PageTests: XCTestCase {

    //MARK: - .plistRepresentation
    func test_plistRepresentation_containsID() throws {
        let page = Page()
        let id = try XCTUnwrap(page.plistRepresentation["id"] as? String)
        XCTAssertEqual(id, page.id.stringRepresentation)
    }

    func test_plistRepresentation_containsTitle() throws {
        let page = Page()
        page.title = "Foobar"
        let title = try XCTUnwrap(page.plistRepresentation["title"] as? String)
        XCTAssertEqual(title, "Foobar")
    }

    func test_plistRepresentation_containsDateCreated() throws {
        let page = Page()
        page.dateCreated = Date(timeIntervalSinceReferenceDate: 31)
        let date = try XCTUnwrap(page.plistRepresentation["dateCreated"] as? Date)
        XCTAssertEqual(date, Date(timeIntervalSinceReferenceDate: 31))
    }

    func test_plistRepresentation_containsDateModified() throws {
        let page = Page()
        page.dateModified = Date(timeIntervalSinceReferenceDate: 12345)
        let date = try XCTUnwrap(page.plistRepresentation["dateModified"] as? Date)
        XCTAssertEqual(date, Date(timeIntervalSinceReferenceDate: 12345))
    }

    func test_plistRepresentation_containsUserPreferredSizeIfSet() throws {
        let page = Page()
        page.contentSize = CGSize(width: 200, height: 300)
        let size = try XCTUnwrap(page.plistRepresentation["userPreferredSize"] as? String)
        XCTAssertEqual(size, NSStringFromSize(CGSize(width: 200, height: 300)))
    }

    func test_plistRepresentation_doesntContainUserPreferredSizeIfSet() {
        let page = Page()
        XCTAssertNil(page.plistRepresentation["userPreferredSize"])
    }

    func test_plistRepresentation_containsContentForTextContent() throws {
        let textContent = TextPageContent()
        textContent.text = NSAttributedString(string: "foobar")
        let page = Page()
        page.content = textContent

        let expectedContent = ModelFile(type: PageContentType.text.rawValue,
                                        filename: "\(page.id.uuid.uuidString).rtf",
                                        data: try textContent.text.data(from: NSRange(location: 0, length: 6), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]),
                                        metadata: nil)

        let content = try XCTUnwrap(page.plistRepresentation["content"] as? ModelFile)
        XCTAssertEqual(content.type, expectedContent.type)
        XCTAssertEqual(content.filename, expectedContent.filename)
        XCTAssertEqual(content.data, expectedContent.data)
    }

    func test_plistRepresentation_containsContentForImageContent() throws {
        let imageContent = ImagePageContent()
        imageContent.image = NSImage(named: "NSAddTemplate")
        imageContent.imageDescription = "Foo Bar Baz"
        let page = Page()
        page.content = imageContent

        let expectedContent = ModelFile(type: PageContentType.image.rawValue,
                                        filename: "\(page.id.uuid.uuidString).png",
                                        data: imageContent.image?.pngData(),
                                        metadata: ["description": "Foo Bar Baz"])

        let content = try XCTUnwrap(page.plistRepresentation["content"] as? ModelFile)
        XCTAssertEqual(content.type, expectedContent.type)
        XCTAssertEqual(content.filename, expectedContent.filename)
        XCTAssertEqual(content.data, expectedContent.data)
        XCTAssertEqual(content.metadata?["description"] as? String, "Foo Bar Baz")
    }


    //MARK: - update(fromPlistRepresentation:)
    func test_updateFromPlistRepresentation_doesntUpdateIfIDsDontMatch() {
        let page = Page()
        let plist: [String: Any] = [
            "id": "foobar",
            "title": "Lorem Ipsum",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 1234),
            "dateModified": Date(timeIntervalSinceReferenceDate: 9876),
            "content": ModelFile(type: "text", filename: nil, data: nil, metadata: nil)
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .idsDontMatch)
        }
    }

    func test_updateFromPlistRepresentation_updatesTitle() {
        let page = Page()
        let plist: [String: Any] = [
            "id": page.id.stringRepresentation,
            "title": "Lorem Ipsum",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 1235),
            "dateModified": Date(timeIntervalSinceReferenceDate: 9875),
            "content": ModelFile(type: "text", filename: nil, data: nil, metadata: nil)
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: plist))

        XCTAssertEqual(page.title, "Lorem Ipsum")
    }

    func test_updateFromPlistRepresentation_throwsIfTitleMissing() {
        let page = Page()
        let plist: [String: Any] = [
            "id": page.id.stringRepresentation,
            "dateCreated": Date(timeIntervalSinceReferenceDate: 1235),
            "dateModified": Date(timeIntervalSinceReferenceDate: 9875),
            "content": ModelFile(type: "text", filename: nil, data: nil, metadata: nil)
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("title"))
        }
    }

    func test_updateFromPlistRepresentation_updatesDateCreated() {
        let page = Page()
        let plist: [String: Any] = [
            "id": page.id.stringRepresentation,
            "title": "Lorem Ipsum",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 1236),
            "dateModified": Date(timeIntervalSinceReferenceDate: 9874),
            "content": ModelFile(type: "text", filename: nil, data: nil, metadata: nil)
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: plist))

        XCTAssertEqual(page.dateCreated, Date(timeIntervalSinceReferenceDate: 1236))
    }

    func test_updateFromPlistRepresentation_throwsIfDateCreatedMissing() {
        let page = Page()
        let plist: [String: Any] = [
            "id": page.id.stringRepresentation,
            "title": "Lorem Ipsum",
            "dateModified": Date(timeIntervalSinceReferenceDate: 9874),
            "content": ModelFile(type: "text", filename: nil, data: nil, metadata: nil)
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("dateCreated"))
        }
    }

    func test_updateFromPlistRepresentation_updatesDateModified() {
        let page = Page()
        let plist: [String: Any] = [
            "id": page.id.stringRepresentation,
            "title": "Lorem Ipsum",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 1237),
            "dateModified": Date(timeIntervalSinceReferenceDate: 9873),
            "content": ModelFile(type: "text", filename: nil, data: nil, metadata: nil)
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: plist))

        XCTAssertEqual(page.dateModified, Date(timeIntervalSinceReferenceDate: 9873))
    }

    func test_updateFromPlistRepresentation_throwsIfDateModifiedMissing() {
        let page = Page()
        let plist: [String: Any] = [
            "id": page.id.stringRepresentation,
            "title": "Lorem Ipsum",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 1237),
            "content": ModelFile(type: "empty", filename: nil, data: nil, metadata: nil)
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("dateModified"))
        }
    }

    func test_updateFromPlistRepresentation_updatesUserPreferredSizeIfInPlist() {
        let page = Page()
        let plist: [String: Any] = [
            "id": page.id.stringRepresentation,
            "title": "Lorem Ipsum",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 1238),
            "dateModified": Date(timeIntervalSinceReferenceDate: 9872),
            "userPreferredSize": NSStringFromSize(CGSize(width: 320, height: 480)),
            "content": ModelFile(type: "text", filename: nil, data: nil, metadata: nil)
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: plist))

        XCTAssertEqual(page.contentSize, CGSize(width: 320, height: 480))
    }

    func test_updateFromPlistRepresentation_setsUserPreferredSizeToNilIfNotInPlist() {
        let page = Page()
        page.contentSize = CGSize(width: 3, height: 4)
        let plist: [String: Any] = [
            "id": page.id.stringRepresentation,
            "title": "Lorem Ipsum",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 1238),
            "dateModified": Date(timeIntervalSinceReferenceDate: 9872),
            "content": ModelFile(type: "text", filename: nil, data: nil, metadata: nil)
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: plist))

        XCTAssertEqual(page.contentSize, Page.standardSize)
    }

    func test_updateFromPlistRepresentation_updatesContentToTextContentIfTextContentInPlist() throws {
        let page = Page()
        let data = try NSAttributedString(string: "Foobar Baz", attributes: [.font: NSFont.systemFont(ofSize: 5)]).data(from: NSRange(location: 0, length: 10),
                                                                     documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        let plist: [String: Any] = [
            "id": page.id.stringRepresentation,
            "title": "Lorem Ipsum",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 1238),
            "dateModified": Date(timeIntervalSinceReferenceDate: 9872),
            "content": ModelFile(type: "text", filename: "\(page.id.uuid.uuidString).rtf", data: data, metadata: nil)
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: plist))

        XCTAssertEqual(page.content.contentType, .text)
        let expectedString = try NSAttributedString(data: data, options: [:], documentAttributes: nil)
        XCTAssertEqual((page.content as? TextPageContent)?.text, expectedString)
    }

    func test_updateFromPlistRepresentation_updatesContentToImageContentIfImageContentInPlist() {
        let page = Page()
        guard let data = NSImage(named: "NSAddTemplate")?.pngData() else {
            XCTFail("Couldn't generate PDF data")
            return
        }
        let image = NSImage(data: data)
        let plist: [String: Any] = [
            "id": page.id.stringRepresentation,
            "title": "Lorem Ipsum",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 1238),
            "dateModified": Date(timeIntervalSinceReferenceDate: 9872),
            "content": ModelFile(type: "image", filename: "\(page.id.uuid.uuidString).png", data: data, metadata: ["description": "Hello World"])
        ]

        XCTAssertNoThrow(try page.update(fromPlistRepresentation: plist))

        XCTAssertEqual(page.content.contentType, .image)
        XCTAssertEqual((page.content as? ImagePageContent)?.image?.tiffRepresentation, image?.tiffRepresentation)
        XCTAssertEqual((page.content as? ImagePageContent)?.imageDescription, "Hello World")
    }

    func test_updateFromPlistRepresentation_throwsIfContentMissing() {
        let page = Page()
        let plist: [String: Any] = [
            "id": page.id.stringRepresentation,
            "title": "Lorem Ipsum",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 1239),
            "dateModified": Date(timeIntervalSinceReferenceDate: 9871),
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("content"))
        }
    }

    func test_updateFromPlistRepresentation_throwsIfContentTypeIsNotValid() {
        let page = Page()
        page.content = TextPageContent()
        let plist: [String: Any] = [
           "id": page.id.stringRepresentation,
           "title": "Lorem Ipsum",
           "dateCreated": Date(timeIntervalSinceReferenceDate: 1238),
           "dateModified": Date(timeIntervalSinceReferenceDate: 9872),
           "content": ModelFile(type: "foobar", filename: nil, data: nil, metadata: nil)
        ]

        XCTAssertThrowsError(try page.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("content"))
        }
    }


    //MARK: - updatePageSizes()
    func test_updatePagesSizes_doesntUpdateAnySizesIfUserPreferredSizeIsSet() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let page = modelController.collection(for: Page.self).newObject() {
            let content = ImagePageContent()
            content.image = NSImage(size: NSSize(width: 50, height: 30))
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

    func test_updatePageSizes_updatesFrameSizeOfPageOnAllCanvasesIfUserPreferredSizeIsNotSet() throws{
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let page = modelController.collection(for: Page.self).newObject() {
            let content = ImagePageContent()
            content.image = NSImage(size: NSSize(width: 50, height: 30))
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
        textPage.content = TextPageContent()

        let imagePage = Page()
        imagePage.content = ImagePageContent()

        XCTAssertTrue(textPage.sortType < imagePage.sortType)
    }


    //MARK: - ModelCollection<Page>

    //MARK: - setContentValue(_:for:ofPageWithID:)
    func test_setContentValueForKeyPathOfPageWithID_updatesTheContentIfPageExists() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let collection = modelController.collection(for: Page.self)
        let content = TextPageContent()
        content.text = NSAttributedString(string: "Foo Bar")
        let page = collection.newObject() {
            $0.content = content
        }

        let newValue = NSAttributedString(string: "Hello World")
        collection.setContentValue(newValue, for: \TextPageContent.text, ofPageWithID: page.id)
        XCTAssertEqual(content.text, newValue)
    }

    func test_setContentValueForKeyPathOfPageWithID_doesntUpdateTheContentIfPageCantBeFound() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let collection = modelController.collection(for: Page.self)
        let content = TextPageContent()
        content.text = NSAttributedString(string: "Foo Bar")
        _ = collection.newObject() {
            $0.content = content
        }

        let newValue = NSAttributedString(string: "Hello World")
        collection.setContentValue(newValue, for: \TextPageContent.text, ofPageWithID: Page.modelID(with: UUID()))
        XCTAssertEqual(content.text, NSAttributedString(string: "Foo Bar"))
    }
}
