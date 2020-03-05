//
//  ModelWriterTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class ModelWriterTests: XCTestCase {
    var testModel: ModelController!

    var pages: [Page]!
    var canvases: [Canvas]!
    var canvasPages: [CanvasPage]!

    override func setUp() {
        super.setUp()
        self.testModel = BubblesModelController(undoManager: UndoManager())

        let pageUUIDS = [UUID(), UUID(), UUID()].sorted { $0.uuidString < $1.uuidString }
        let pageCollection = self.testModel.collection(for: Page.self)
        self.pages = [
            pageCollection.newObject() {
                $0.id = Page.modelID(with: pageUUIDS[0])
                $0.title = "Page 1"
                let content = TextPageContent()
                content.text = NSAttributedString(string: "Hello World")
                $0.content = content
            },
            pageCollection.newObject() {
                $0.id = Page.modelID(with: pageUUIDS[1])
                $0.title = "Page 2"
            },
            pageCollection.newObject() {
                $0.id = Page.modelID(with: pageUUIDS[2])
                $0.title = "Page 3"
                let content = ImagePageContent()
                content.image = NSImage(named: "NSAddTemplate")
                $0.content = content
            },
        ]

        let canvasCollection = self.testModel.collection(for: Canvas.self)
        self.canvases = [
            canvasCollection.newObject { $0.title = "Canvas 1" },
            canvasCollection.newObject { $0.title = "Canvas 2" }
        ]

        let canvasPagesCollection = self.testModel.collection(for: CanvasPage.self)
        self.canvasPages = [
            canvasPagesCollection.newObject() {
                $0.page = self.pages[0]
                $0.canvas = self.canvases[0]
            },
            canvasPagesCollection.newObject() {
                $0.page = self.pages[1]
                $0.canvas = self.canvases[0]
            },
            canvasPagesCollection.newObject() {
                $0.page = self.pages[1]
                $0.canvas = self.canvases[1]
            }
        ]

        self.canvasPages[1].parent = self.canvasPages[0]
    }

    func test_plist_fileWrapperContainsDataPlistAtRoot() throws {
        let writer = ModelWriter(modelController: self.testModel)
        let fileWrapper = try writer.generateFileWrapper()
        XCTAssertNotNil(fileWrapper.fileWrappers?["data.plist"])
        XCTAssertTrue(fileWrapper.fileWrappers?["data.plist"]?.isRegularFile ?? false)
    }

    func test_plist_containsAllPages() throws {
        let writer = ModelWriter(modelController: self.testModel)
        let fileWrapper = try writer.generateFileWrapper()
        let data = try XCTUnwrap(fileWrapper.fileWrappers?["data.plist"]?.regularFileContents)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        let pages = try XCTUnwrap(plist["pages"] as? [[String: Any]])
        XCTAssertEqual(pages.count, 3)
    }

    func test_plist_pagesContainTypeAndFilenameOfContent() throws {
        let writer = ModelWriter(modelController: self.testModel)
        let fileWrapper = try writer.generateFileWrapper()
        let data = try XCTUnwrap(fileWrapper.fileWrappers?["data.plist"]?.regularFileContents)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        let pages = try XCTUnwrap(plist["pages"] as? [[String: Any]])

        let page1Content = pages[0]["content"] as? [String: String]
        XCTAssertEqual(page1Content, ["type": "text", "filename": "\(self.pages[0].id.uuid.uuidString).rtf"])
        let page2Content = pages[1]["content"] as? [String: String]
        XCTAssertEqual(page2Content, ["type": "text", "filename": "\(self.pages[1].id.uuid.uuidString).rtf"])
        let page3Content = pages[2]["content"] as? [String: String]
        XCTAssertEqual(page3Content, ["type": "image", "filename": "\(self.pages[2].id.uuid.uuidString).png"])
    }

    func test_plist_containsAllCanvasPages() throws {
        let writer = ModelWriter(modelController: self.testModel)
        let fileWrapper = try writer.generateFileWrapper()
        let data = try XCTUnwrap(fileWrapper.fileWrappers?["data.plist"]?.regularFileContents)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        let canvasPages = try XCTUnwrap(plist["canvasPages"] as? [[String: Any]])
        XCTAssertEqual(canvasPages.count, 3)
    }

    func test_plist_containsAllCanvases() throws {
        let writer = ModelWriter(modelController: self.testModel)
        let fileWrapper = try writer.generateFileWrapper()
        let data = try XCTUnwrap(fileWrapper.fileWrappers?["data.plist"]?.regularFileContents)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        let canvases = try XCTUnwrap(plist["canvases"] as? [[String: Any]])
        XCTAssertEqual(canvases.count, 2)
    }

    func test_content_fileWrapperContainsContentDirectoryAtRoot() throws {
        let writer = ModelWriter(modelController: self.testModel)
        let fileWrapper = try writer.generateFileWrapper()
        XCTAssertNotNil(fileWrapper.fileWrappers?["content"])
        XCTAssertTrue(fileWrapper.fileWrappers?["content"]?.isDirectory ?? false)
    }

    func test_content_containsDataFilesForEachContentType() throws {
        let writer = ModelWriter(modelController: self.testModel)
        let fileWrapper = try writer.generateFileWrapper()
        let contentDirectory = try XCTUnwrap(fileWrapper.fileWrappers?["content"])

        let page1Content = try XCTUnwrap(contentDirectory.fileWrappers?["\(self.pages[0].id.uuid.uuidString).rtf"])
        XCTAssertTrue(page1Content.isRegularFile)

        XCTAssertNil(contentDirectory.fileWrappers?["\(self.pages[2].id.uuid.uuidString)"])

        let page3Content = try XCTUnwrap(contentDirectory.fileWrappers?["\(self.pages[2].id.uuid.uuidString).png"])
        XCTAssertTrue(page3Content.isRegularFile)
    }
}
