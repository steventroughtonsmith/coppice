//
//  ModelObjects+PasteboardTests.swift
//  coppicesTests
//
//  Created by Martin Pilkington on 14/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

class ModelObjects_PasteboardTests: XCTestCase {
    //MARK: - .pasteboardWriter
    func test_pasteboardWriter_canvasWriterContainsModelID() {
        let canvas = Canvas()
        let pasteboardWriter = canvas.pasteboardWriter
        XCTAssertTrue(pasteboardWriter.writableTypes(for: NSPasteboard.general).contains(ModelID.PasteboardType))
    }

    func test_pasteboardWriter_folderWriterContainsModelID() {
        let folder = Folder()
        let pasteboardWriter = folder.pasteboardWriter
        XCTAssertTrue(pasteboardWriter.writableTypes(for: NSPasteboard.general).contains(ModelID.PasteboardType))
    }

    func test_pasteboardWriter_pageWriterContainsModelID() {
        let page = Page()
        page.content = TextPageContent()
        let pasteboardWriter = page.pasteboardWriter
        XCTAssertTrue(pasteboardWriter.writableTypes(for: NSPasteboard.general).contains(ModelID.PasteboardType))
    }


    //MARK: - .filePromiseProvider
    func test_filePromiseProvider_textContentReturnsFilePromiseProviderWithRTFFileType() {
        let content = TextPageContent()
        let fileProvider = content.filePromiseProvider
        XCTAssertEqual(fileProvider.fileType, kUTTypeRTF as String)
    }

    func test_filePromiseProvider_imageContentReturnsFilePromiseProviderWithPNGFileType() {
        let content = ImagePageContent()
        let fileProvider = content.filePromiseProvider
        XCTAssertEqual(fileProvider.fileType, kUTTypePNG as String)
    }


    //MARK: - filePromiseProvider(_: fileNameForType:)
    func test_filePromiseProviderFileNameForType_textContentReturnsEmptyStringIfTypeIsNotRTF() {
        let page = Page()
        page.title = "Hello World"
        let content = TextPageContent()
        page.content = content

        let provider = content.filePromiseProvider
        XCTAssertEqual(content.filePromiseProvider(provider, fileNameForType: (kUTTypeText as String)), "")
    }

    func test_filePromiseProviderFileNameForType_textContentReturnsFileNameUsingPageTitle() {
        let page = Page()
        page.title = "Hello World"
        let content = TextPageContent()
        page.content = content

        let provider = content.filePromiseProvider
        let filename = (content.filePromiseProvider(provider, fileNameForType: (kUTTypeRTF as String)) as NSString)
        XCTAssertEqual(filename.deletingPathExtension, "Hello World")
    }

    func test_filePromiseProviderFileNameForType_textContentReturnsFileNameWithRTFExtension() {
        let page = Page()
        page.title = "Hello World"
        let content = TextPageContent()
        page.content = content

        let provider = content.filePromiseProvider
        let filename = (content.filePromiseProvider(provider, fileNameForType: (kUTTypeRTF as String)) as NSString)
        XCTAssertEqual(filename.pathExtension, "rtf")
    }

    func test_filePromiseProviderFileNameForType_imageContentReturnsEmptyStringIfTypeIsNotPNG() {
        let page = Page()
        page.title = "Hello World"
        let content = ImagePageContent()
        page.content = content

        let provider = content.filePromiseProvider
        XCTAssertEqual(content.filePromiseProvider(provider, fileNameForType: (kUTTypeText as String)), "")
    }

    func test_filePromiseProviderFileNameForType_imageContentReturnsFileNameUsingPageTitle() {
        let page = Page()
        page.title = "Hello World"
        let content = ImagePageContent()
        page.content = content

        let provider = content.filePromiseProvider
        let filename = (content.filePromiseProvider(provider, fileNameForType: (kUTTypePNG as String)) as NSString)
        XCTAssertEqual(filename.deletingPathExtension, "Hello World")
    }

    func test_filePromiseProviderFileNameForType_imageContentReturnsFileNameWithPNGExtension() {
        let page = Page()
        page.title = "Hello World"
        let content = ImagePageContent()
        page.content = content

        let provider = content.filePromiseProvider
        let filename = (content.filePromiseProvider(provider, fileNameForType: (kUTTypePNG as String)) as NSString)
        XCTAssertEqual(filename.pathExtension, "png")
    }


    //MARK: - filePromiseProvider(_:writePromiseTo:completionHandler:)
    func test_filePromiseProviderWritePromise_textContentWritesDataToSuppliedURL() {
        let page = Page()
        page.title = "Hello World"
        let content = TextPageContent()
        page.content = content
        content.text = NSAttributedString(string: "Foo Bar")

        let provider = content.filePromiseProvider
        let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())/coppicestexttest.rtf")
        try? FileManager.default.removeItem(at: url)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        self.performAndWaitFor("Write data") { (expectation) in
            content.filePromiseProvider(provider, writePromiseTo: url) { _ in
                expectation.fulfill()
            }
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let string = try? NSAttributedString(url: url, options: [:], documentAttributes: nil)
        XCTAssertEqual(string?.string, content.text.string)
    }

    func test_filePromiseProviderWritePromise_textContentCallsCallbackWithNilIfWriteSucceeds() {
        let page = Page()
        page.title = "Hello World"
        let content = TextPageContent()
        page.content = content
        content.text = NSAttributedString(string: "Foo Bar")

        let provider = content.filePromiseProvider
        let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())/coppicestexttest.rtf")
        try? FileManager.default.removeItem(at: url)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        self.performAndWaitFor("Write data") { (expectation) in
            content.filePromiseProvider(provider, writePromiseTo: url) { error in
                expectation.fulfill()
                XCTAssertNil(error)
            }
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func test_filePromiseProviderWritePromise_textContentCallsCallbackWithErrorIfWriteFails() {
        let page = Page()
        page.title = "Hello World"
        let content = TextPageContent()
        page.content = content
        content.text = NSAttributedString(string: "Foo Bar")

        let provider = content.filePromiseProvider
        let url = URL(fileURLWithPath: "/System/coppicestexttest.rtf")
        try? FileManager.default.removeItem(at: url)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        self.performAndWaitFor("Write data") { (expectation) in
            content.filePromiseProvider(provider, writePromiseTo: url) { error in
                expectation.fulfill()
                XCTAssertNotNil(error)
            }
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func test_filePromiseProviderWritePromise_imageContentWritesDataToSuppliedURL() throws {
        let page = Page()
        page.title = "Hello World"
        let content = ImagePageContent()
        page.content = content
        content.image = NSImage(named: "NSAddTemplate")!

        let provider = content.filePromiseProvider
        let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())/coppicesimagetest.png")
        try? FileManager.default.removeItem(at: url)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        self.performAndWaitFor("Write data") { (expectation) in
            content.filePromiseProvider(provider, writePromiseTo: url) { _ in
                expectation.fulfill()
            }
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let image = try XCTUnwrap(NSImage(contentsOf: url))
        XCTAssertEqual(image.pngData(), NSImage(named: "NSAddTemplate")!.pngData())
    }

    func test_filePromiseProviderWritePromise_imageContentCallsCallbackWithNilIfWriteSucceeds() {
        let page = Page()
        page.title = "Hello World"
        let content = ImagePageContent()
        page.content = content
        content.image = NSImage(named: "NSAddTemplate")!

        let provider = content.filePromiseProvider
        let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())/coppicesimagetest.png")
        try? FileManager.default.removeItem(at: url)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        self.performAndWaitFor("Write data") { (expectation) in
            content.filePromiseProvider(provider, writePromiseTo: url) { error in
                expectation.fulfill()
                XCTAssertNil(error)
            }
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func test_filePromiseProviderWritePromise_imageContentCallsCallbackWithErrorIfWriteFails() {
        let page = Page()
        page.title = "Hello World"
        let content = ImagePageContent()
        page.content = content
        content.image = NSImage(named: "NSAddTemplate")!

        let provider = content.filePromiseProvider
        let url = URL(fileURLWithPath: "/System/coppicesimagetest.png")
        try? FileManager.default.removeItem(at: url)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        self.performAndWaitFor("Write data") { (expectation) in
            content.filePromiseProvider(provider, writePromiseTo: url) { error in
                expectation.fulfill()
                XCTAssertNotNil(error)
            }
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }


    //MARK: - ExtendableFilePromiseProvider
    func test_writableTypesForPasteboard_addsAdditionalItemTypesToArray() {
        let content = TextPageContent()
        let provider = content.filePromiseProvider

        provider.additionalItems[ModelID.PasteboardType] = CanvasPage.modelID(with: UUID())
        provider.additionalItems[.color] = NSColor.blue

        let types = provider.writableTypes(for: NSPasteboard.general)
        XCTAssertTrue(types.contains(.color))
        XCTAssertTrue(types.contains(ModelID.PasteboardType))
    }

    func test_pasteboardPropertyListForType_returnsAdditionalItemIfTypeMatches() {
        let content = TextPageContent()
        let provider = content.filePromiseProvider

        let modelID = CanvasPage.modelID(with: UUID())
        provider.additionalItems[ModelID.PasteboardType] = modelID
        provider.additionalItems[.color] = NSColor.blue

        XCTAssertEqual(provider.pasteboardPropertyList(forType: ModelID.PasteboardType) as? ModelID, modelID)
        XCTAssertEqual(provider.pasteboardPropertyList(forType: .color) as? NSColor, NSColor.blue)
    }

    func test_pasteboardPropertyListForType_doesntReturnAnythingForTypeNotInAdditionalItems() {
        let content = TextPageContent()
        let provider = content.filePromiseProvider

        let modelID = CanvasPage.modelID(with: UUID())
        provider.additionalItems[ModelID.PasteboardType] = modelID
        provider.additionalItems[.color] = NSColor.blue

        XCTAssertNil(provider.pasteboardPropertyList(forType: .pdf))
    }
}
