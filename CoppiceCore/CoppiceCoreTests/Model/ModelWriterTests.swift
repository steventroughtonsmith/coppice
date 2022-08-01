//
//  ModelWriterTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import M3Data
import XCTest

class ModelWriterTests: XCTestCase {
    var testModel: TestData.Model!

    override func setUp() {
        super.setUp()

        self.testModel = TestData.Model()
    }

    func test_plist_containsAllPages() throws {
        let writer = ModelWriter(modelController: self.testModel.modelController, plist: Plist.allPlists.last!)
        let fileWrappers = try writer.generateFileWrappers()
        let data = try XCTUnwrap(fileWrappers.data.regularFileContents)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        let pages = try XCTUnwrap(plist["pages"] as? [[String: Any]])
        XCTAssertEqual(pages.count, 3)

        XCTAssertEqual(pages as [NSDictionary], TestData.Plist.V3().plistPages as [NSDictionary])
    }

    func test_plist_pagesContainTypeAndFilenameOfContent() throws {
        let writer = ModelWriter(modelController: self.testModel.modelController, plist: Plist.allPlists.last!)
        let fileWrappers = try writer.generateFileWrappers()
        let data = try XCTUnwrap(fileWrappers.data.regularFileContents)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        let pages = try XCTUnwrap(plist["pages"] as? [[String: Any]])

        let page1Content = try XCTUnwrap(pages[0]["content"] as? [String: Any])
        XCTAssertEqual(page1Content["type"] as? String, "text")
        XCTAssertEqual(page1Content["filename"] as? String, "\(self.testModel.pageIDs[0].uuidString).rtf")
        let page2Content = try XCTUnwrap(pages[1]["content"] as? [String: Any])
        XCTAssertEqual(page2Content["type"] as? String, "text")
        XCTAssertEqual(page2Content["filename"] as? String, "\(self.testModel.pageIDs[1].uuidString).rtf")
        let page3Content = try XCTUnwrap(pages[2]["content"] as? [String: Any])
        XCTAssertEqual(page3Content["type"] as? String, "image")
        XCTAssertEqual(page3Content["filename"] as? String, "\(self.testModel.pageIDs[2].uuidString).png")
    }

    func test_plist_containsAllCanvasPages() throws {
        let writer = ModelWriter(modelController: self.testModel.modelController, plist: Plist.allPlists.last!)
        let fileWrappers = try writer.generateFileWrappers()
        let data = try XCTUnwrap(fileWrappers.data.regularFileContents)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        let canvasPages = try XCTUnwrap(plist["canvasPages"] as? [[String: Any]])
        XCTAssertEqual(canvasPages.count, 4)

        XCTAssertEqual(canvasPages as [NSDictionary], TestData.Plist.V3().plistCanvasPages as [NSDictionary])
    }

    func test_plist_containsAllCanvases() throws {
        let writer = ModelWriter(modelController: self.testModel.modelController, plist: Plist.allPlists.last!)
        let fileWrappers = try writer.generateFileWrappers()
        let data = try XCTUnwrap(fileWrappers.data.regularFileContents)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        let canvases = try XCTUnwrap(plist["canvases"] as? [[String: Any]])
        XCTAssertEqual(canvases.count, 2)
        XCTAssertEqual(canvases as [NSDictionary], TestData.Plist.V3().plistCanvases as [NSDictionary])
    }

    func test_plist_containsAllFolders() throws {
        let writer = ModelWriter(modelController: self.testModel.modelController, plist: Plist.allPlists.last!)
        let fileWrappers = try writer.generateFileWrappers()
        let data = try XCTUnwrap(fileWrappers.data.regularFileContents)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        let folders = try XCTUnwrap(plist["folders"] as? [[String: Any]])
        XCTAssertEqual(folders.count, 2)

        XCTAssertEqual(folders as [NSDictionary], TestData.Plist.V3().plistFolders as [NSDictionary])
    }

    func test_plist_containsAllCanvasLinks() throws {
        let writer = ModelWriter(modelController: self.testModel.modelController, plist: Plist.allPlists.last!)
        let fileWrappers = try writer.generateFileWrappers()
        let data = try XCTUnwrap(fileWrappers.data.regularFileContents)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        let canvasLinks = try XCTUnwrap(plist["canvasLinks"] as? [[String: Any]])
        XCTAssertEqual(canvasLinks.count, 2)

        XCTAssertEqual(canvasLinks as [NSDictionary], TestData.Plist.V3().plistCanvasLinks as [NSDictionary])
    }

    func test_plist_containsSuppliedDocumentVersion() throws {
        let writer = ModelWriter(modelController: self.testModel.modelController, plist: Plist.allPlists.last!)
        let fileWrappers = try writer.generateFileWrappers()
        let data = try XCTUnwrap(fileWrappers.data.regularFileContents)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        let version = try XCTUnwrap(plist["version"] as? Int)
        XCTAssertEqual(version, 3)
    }

    func test_content_containsDataFilesForEachContentType() throws {
        let writer = ModelWriter(modelController: self.testModel.modelController, plist: Plist.allPlists.last!)
        let fileWrappers = try writer.generateFileWrappers()
        let contentDirectory = try XCTUnwrap(fileWrappers.content)

        let page1Content = try XCTUnwrap(contentDirectory.fileWrappers?["\(self.testModel.pageIDs[0].uuidString).rtf"])
        XCTAssertTrue(page1Content.isRegularFile)

        XCTAssertNil(contentDirectory.fileWrappers?["\(self.testModel.pageIDs[2].uuidString)"])

        let page3Content = try XCTUnwrap(contentDirectory.fileWrappers?["\(self.testModel.pageIDs[2].uuidString).png"])
        XCTAssertTrue(page3Content.isRegularFile)
    }
}
