//
//  CanvasTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import M3Data
import XCTest
class CanvasTests: XCTestCase {
    //MARK: .zoomFactor
    func test_zoomFactor_capsMaximumValueTo1() throws {
        let canvas = Canvas()
        canvas.zoomFactor = 2
        XCTAssertEqual(canvas.zoomFactor, 1)
    }

    func test_zoomFactor_capsMinimumValueTo0Point25() throws {
        let canvas = Canvas()
        canvas.zoomFactor = 0.2
        XCTAssertEqual(canvas.zoomFactor, 0.25)
    }


    //MARK: - .plistRepresentation
    func test_plistRepresentation_containsID() throws {
        let canvas = Canvas()
        let plist = canvas.plistRepresentation
        let id = try XCTUnwrap(plist[.id] as? ModelID)
        XCTAssertEqual(id, canvas.id)
    }

    func test_plistRepresentation_containsTitle() throws {
        let canvas = Canvas()
        canvas.title = "Hello World"
        let plist = canvas.plistRepresentation
        let title = try XCTUnwrap(plist[.Canvas.title] as? String)
        XCTAssertEqual(title, "Hello World")
    }

    func test_plistRepresentation_containsDateCreated() throws {
        let canvas = Canvas()
        canvas.dateCreated = Date(timeIntervalSinceReferenceDate: 1000)
        let plist = canvas.plistRepresentation
        let date = try XCTUnwrap(plist[.Canvas.dateCreated] as? Date)
        XCTAssertEqual(date, Date(timeIntervalSinceReferenceDate: 1000))
    }

    func test_plistRepresentation_containsDateModified() throws {
        let canvas = Canvas()
        canvas.dateModified = Date(timeIntervalSinceReferenceDate: 42)
        let plist = canvas.plistRepresentation
        let date = try XCTUnwrap(plist[.Canvas.dateModified] as? Date)
        XCTAssertEqual(date, Date(timeIntervalSinceReferenceDate: 42))
    }

    func test_plistRepresentation_containsSortIndex() throws {
        let canvas = Canvas()
        canvas.sortIndex = 4
        let plist = canvas.plistRepresentation
        let sortIndex = try XCTUnwrap(plist[.Canvas.sortIndex] as? Int)
        XCTAssertEqual(sortIndex, 4)
    }

    func test_plistRepresentation_containsTheme() throws {
        let canvas = Canvas()
        canvas.theme = .dark
        let plist = canvas.plistRepresentation
        let theme = try XCTUnwrap(plist[.Canvas.theme] as? String)
        XCTAssertEqual(theme, Canvas.Theme.dark.rawValue)
    }

    func test_plistRepresentation_containsViewPortIfSet() throws {
        let canvas = Canvas()
        canvas.viewPort = CGRect(x: 1, y: 2, width: 30, height: 40)
        let plist = canvas.plistRepresentation
        let viewPort = try XCTUnwrap(plist[.Canvas.viewPort] as? String)
        XCTAssertEqual(viewPort, NSStringFromRect(CGRect(x: 1, y: 2, width: 30, height: 40)))
    }

    func test_plistRepresentation_doesntContainViewPortIfNotSet() {
        let canvas = Canvas()
        canvas.viewPort = nil
        let plist = canvas.plistRepresentation
        XCTAssertNil(plist[.Canvas.viewPort])
    }

    func test_plistRepresentation_containsThumbnailIfSet() throws {
        let canvas = Canvas()
        canvas.thumbnail = NSImage(named: "NSAddTemplate")!
        let plist = canvas.plistRepresentation
        let thumbnail = try XCTUnwrap(plist[.Canvas.thumbnail] as? ModelFile)
        XCTAssertEqual(thumbnail.type, "thumbnail")
        XCTAssertEqual(thumbnail.filename, "\(canvas.id.uuid.uuidString)-thumbnail.png")
        XCTAssertNotNil(thumbnail.data)
    }

    func test_plistRepresentation_doesntContainThumbnailifNotSet() {
        let canvas = Canvas()
        canvas.thumbnail = nil
        let plist = canvas.plistRepresentation
        XCTAssertNil(plist[.Canvas.thumbnail])
    }

    func test_plistRepresentation_containsClosedPageHierarchies() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvas = modelController.collection(for: Canvas.self).newObject()
        let page = modelController.collection(for: Page.self).newObject()
        let canvasPage1 = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = page
        }
        let canvasPage2 = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = page
        }
        let canvasPage3 = modelController.collection(for: CanvasPage.self).newObject() {
            $0.page = page
        }
        var pageHierarchies = [ModelID: [ModelID: LegacyPageHierarchy]]()
        let canvasPageID1 = CanvasPage.modelID(with: UUID())
        let canvasPageID2 = CanvasPage.modelID(with: UUID())
        let pageID1 = Page.modelID(with: UUID())
        let pageID2 = Page.modelID(with: UUID())
        let pageID3 = Page.modelID(with: UUID())
        pageHierarchies[canvasPageID1] = [pageID1: LegacyPageHierarchy(canvasPage: canvasPage1)!]
        pageHierarchies[canvasPageID2] = [pageID2: LegacyPageHierarchy(canvasPage: canvasPage2)!,
                                          pageID3: LegacyPageHierarchy(canvasPage: canvasPage3)!]

        canvas.closedPageHierarchies = pageHierarchies

        let plist = canvas.plistRepresentation
        let hierarchies = try XCTUnwrap(plist[.Canvas.closedPageHierarchies] as? [String: [String: Any]])
        let firstHierarchy = try XCTUnwrap(hierarchies[canvasPageID1.stringRepresentation])
        let secondHierarchy = try XCTUnwrap(hierarchies[canvasPageID2.stringRepresentation])

        XCTAssertNotNil(firstHierarchy[pageID1.stringRepresentation])
        XCTAssertNotNil(secondHierarchy[pageID2.stringRepresentation])
        XCTAssertNotNil(secondHierarchy[pageID3.stringRepresentation])
    }

    func test_plistRepresentation_containsZoomFactor() throws {
        let canvas = Canvas()
        canvas.zoomFactor = 0.25
        let plist = canvas.plistRepresentation
        let sortIndex = try XCTUnwrap(plist[.Canvas.zoomFactor] as? CGFloat)
        XCTAssertEqual(sortIndex, 0.25)
    }

    func test_plistRepresentation_containsAlwaysShowPageTitles() throws {
        let canvas = Canvas()
        canvas.alwaysShowPageTitles = true
        let plist = canvas.plistRepresentation
        let alwaysShowPageTitles = try XCTUnwrap(plist[.Canvas.alwaysShowPageTitles] as? Bool)
        XCTAssertTrue(alwaysShowPageTitles)
    }

    func test_plistRepresentation_includesAnyOtherProperties() throws {
        let canvas = Canvas()

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            ModelPlistKey(rawValue: "foo"): "bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
            .Canvas.thumbnail: ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
            ModelPlistKey(rawValue: "testingAttribute"): 12345,
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        let plistRepresentation = canvas.plistRepresentation
        XCTAssertEqual(plistRepresentation[ModelPlistKey(rawValue: "foo")] as? String, "bar")
        XCTAssertEqual(plistRepresentation[ModelPlistKey(rawValue: "testingAttribute")] as? Int, 12345)
        XCTAssertEqual(plistRepresentation[.id] as? ModelID, canvas.id)
    }


    //MARK: - update(fromPlistRepresentation:)
    func test_updateFromPlistRepresentation_doesntUpdateIfIDsDontMatch() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: "baz",
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 30),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1453),
            .Canvas.sortIndex: 5,
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .idsDontMatch)
        }
    }

    func test_updateFromPlistRepresentation_updatesTitle() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 31),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1454),
            .Canvas.sortIndex: 4,
            .Canvas.theme: "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.title, "Hello Bar")
    }

    func test_updateFromPlistRepresentation_throwsIfTitleMissing() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 30),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1453),
            .Canvas.sortIndex: 5,
            .Canvas.theme: "auto",
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("title"))
        }
    }

    func test_updateFromPlistRepresentation_updatesDateCreated() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 3,
            .Canvas.theme: "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.dateCreated, Date(timeIntervalSinceReferenceDate: 32))
    }

    func test_updateFromPlistRepresentation_throwsIfDateCreatedMissing() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1453),
            .Canvas.sortIndex: 5,
            .Canvas.theme: "auto",
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("dateCreated"))
        }
    }

    func test_updateFromPlistRepresentation_updatesDateModified() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 33),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1456),
            .Canvas.sortIndex: 2,
            .Canvas.theme: "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.dateModified, Date(timeIntervalSinceReferenceDate: 1456))
    }

    func test_updateFromPlistRepresentation_throwsIfDateModifiedMissing() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 30),
            .Canvas.sortIndex: 5,
            .Canvas.theme: "auto",
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("dateModified"))
        }
    }

    func test_updateFromPlistRepresentation_updatesSortIndex() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.sortIndex, 1)
    }

    func test_updateFromPlistRepresentation_throwsIfSortIndexMissing() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 30),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1453),
            .Canvas.theme: "auto",
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("sortIndex"))
        }
    }

    func test_updateFromPlistRepresentation_updatesTheme() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 29),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1452),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "dark",
        ]
        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))
        XCTAssertEqual(canvas.theme, .dark)
    }

    func test_updateFromPlistRepresentation_throwsIfThemeMissing() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 29),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1452),
            .Canvas.sortIndex: 1,
        ]
        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("theme"))
        }
    }

    func test_updateFromPlistRepresentation_throwsIfThemeDoesntMatch() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 29),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1452),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "possum",
        ]
        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("theme"))
        }
    }

    func test_updateFromPlistRepresentation_updatesViewPortIfInPlist() {
        let canvas = Canvas()
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
            .Canvas.viewPort: NSStringFromRect(CGRect(x: 9, y: 8, width: 7, height: 6)),
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.viewPort, CGRect(x: 9, y: 8, width: 7, height: 6))
    }

    func test_updateFromPlistRepresentation_setsViewPortToNilIfNotInPlist() {
        let canvas = Canvas()
        canvas.viewPort = CGRect(x: 99, y: 88, width: 77, height: 66)
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertNil(canvas.viewPort)
    }

    func test_updateFromPlistRepresentation_updatesThumbnailIfInPlist() {
        let canvas = Canvas()
        canvas.thumbnail = NSImage(named: "NSRemoveTemplate")!

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
            .Canvas.thumbnail: ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.thumbnail?.pngData(), expectedImageData)
    }

    func test_updateFromPlistRepresentation_setsThumbnailToNilIfNotInPlist() {
        let canvas = Canvas()
        canvas.thumbnail = NSImage(named: "NSRemoveTemplate")!
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertNil(canvas.thumbnail)
    }

    func test_updateFromPlistRepresentation_updatesClosedPageHierarchies() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvas = modelController.collection(for: Canvas.self).newObject()
        let page = modelController.collection(for: Page.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject() { $0.page = page }

        let canvasPageID = CanvasPage.modelID(with: UUID())
        let pageID = Page.modelID(with: UUID())
        let hierarchyPlist = LegacyPageHierarchy(canvasPage: canvasPage)!.plistRepresentation
        let hierarchyDict = [canvasPageID.stringRepresentation: [pageID.stringRepresentation: hierarchyPlist]]

        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
            .Canvas.closedPageHierarchies: hierarchyDict,
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        let hierarchies = try XCTUnwrap(canvas.closedPageHierarchies[canvasPageID])
        XCTAssertNotNil(hierarchies[pageID])
    }

    func test_updateFromPlistRepresentation_setsClosedPageHierarchiesToEmptySetIfNotInPlist() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvas = modelController.collection(for: Canvas.self).newObject()
        let page = modelController.collection(for: Page.self).newObject()
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject() { $0.page = page }

        let canvasPageID = CanvasPage.modelID(with: UUID())
        let pageID = Page.modelID(with: UUID())
        let pageHierarchy = LegacyPageHierarchy(canvasPage: canvasPage)!

        canvas.closedPageHierarchies = [canvasPageID: [pageID: pageHierarchy]]

        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))
        XCTAssertEqual(canvas.closedPageHierarchies.count, 0)
    }

    func test_updateFromPlistRepresentation_updatesZoomFactor() throws {
        let canvas = Canvas()
        canvas.thumbnail = NSImage(named: "NSRemoveTemplate")!

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
            .Canvas.thumbnail: ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
            .Canvas.zoomFactor: CGFloat(0.75),
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.zoomFactor, 0.75)
    }

    func test_updateFromPlistRepresentation_setsZoomFactorTo1IfNoneExistsInPlist() throws {
        let canvas = Canvas()

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
            .Canvas.thumbnail: ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.zoomFactor, 1)
    }

    func test_updateFromPlistRepresentation_setsAlwaysShowPageTitlesIfSet() throws {
        let canvas = Canvas()

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
            .Canvas.thumbnail: ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
            .Canvas.alwaysShowPageTitles: true,
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertTrue(canvas.alwaysShowPageTitles)
    }

    func test_updateFromPlistRepresentation_addsAnythingElseInPlistToOtherProperties() throws {
        let canvas = Canvas()

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            ModelPlistKey(rawValue: "foo"): "bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
            .Canvas.thumbnail: ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
            ModelPlistKey(rawValue: "testingAttribute"): 12345,
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))
        XCTAssertEqual(canvas.otherProperties[ModelPlistKey(rawValue: "foo")] as? String, "bar")
        XCTAssertEqual(canvas.otherProperties[ModelPlistKey(rawValue: "testingAttribute")] as? Int, 12345)
    }

    func test_updateFromPlistRepresentation_doesntIncludeAnySupportPlistKeysInOtherProperties() throws {
        let canvas = Canvas()

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [ModelPlistKey: Any] = [
            .id: canvas.id,
            .Canvas.title: "Hello Bar",
            ModelPlistKey(rawValue: "foo"): "bar",
            .Canvas.dateCreated: Date(timeIntervalSinceReferenceDate: 32),
            .Canvas.dateModified: Date(timeIntervalSinceReferenceDate: 1455),
            .Canvas.sortIndex: 1,
            .Canvas.theme: "auto",
            .Canvas.thumbnail: ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
            ModelPlistKey(rawValue: "testingAttribute"): 12345,
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.otherProperties.count, 2)
        for key in ModelPlistKey.Canvas.all {
            XCTAssertNil(canvas.otherProperties[key])
        }
    }


    //MARK: - objectWasInserted()
    func test_objectWasInserted_updatesSortIndexAfterInsertingInCollection() {
        let canvasCollection = ModelCollection<Canvas>()
        XCTAssertEqual(canvasCollection.newObject().sortIndex, 1)
        XCTAssertEqual(canvasCollection.newObject().sortIndex, 2)
        XCTAssertEqual(canvasCollection.newObject().sortIndex, 3)
        XCTAssertEqual(canvasCollection.newObject().sortIndex, 4)
    }

    //MARK: - open(_:linkedFrom:)
    func test_openPageLinkedFrom_createsNewCanvasPageWithSuppliedPageAndCreatesLinkFromSourceIfNewSupplied() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let canvasPage = CanvasPage.create(in: modelController)

        XCTAssertEqual(modelController.canvasLinkCollection.all.count, 0)
        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: canvasPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.page, page)
        XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(newCanvasPage))

        XCTAssertEqual(modelController.canvasLinkCollection.all.count, 1)
        let link = try XCTUnwrap(modelController.canvasLinkCollection.all.first)
        XCTAssertEqual(link.destinationPage, newCanvasPage)
        XCTAssertEqual(link.sourcePage, canvasPage)
        XCTAssertEqual(link.link, PageLink(destination: page.id))
    }

    func test_openPageLinkedFrom_createsNewCanvasPageWithSuppliedPageAndCreatesLinkFromSourceIfNewSuppliedEvenIfCanvasPageWithSuppliedPageAlreadyExists() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let canvasPage = CanvasPage.create(in: modelController) {
            $0.canvas = canvas
        }
        CanvasPage.create(in: modelController) {
            $0.page = page
            $0.canvas = canvas
        }

        XCTAssertEqual(modelController.canvasLinkCollection.all.count, 0)
        XCTAssertEqual(modelController.canvasPageCollection.all.count, 2)
        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: canvasPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.page, page)
        XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(newCanvasPage))
        XCTAssertEqual(modelController.canvasPageCollection.all.count, 3)

        XCTAssertEqual(modelController.canvasLinkCollection.all.count, 1)
        let link = try XCTUnwrap(modelController.canvasLinkCollection.all.first)
        XCTAssertEqual(link.destinationPage, newCanvasPage)
        XCTAssertEqual(link.sourcePage, canvasPage)
        XCTAssertEqual(link.link, PageLink(destination: page.id))
    }

    func test_openPageLinkedFrom_createsLinkBetweenSuppliedPageAndSourceIfAlreadyOnCanvasAndExistingModeSupplied() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let canvasPage = CanvasPage.create(in: modelController) {
            $0.canvas = canvas
        }
        let destinationCanvasPage = CanvasPage.create(in: modelController) {
            $0.page = page
            $0.canvas = canvas
        }

        XCTAssertEqual(modelController.canvasLinkCollection.all.count, 0)
        XCTAssertEqual(modelController.canvasPageCollection.all.count, 2)
        let openedCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: canvasPage, with: PageLink(destination: page.id), mode: .existing).first)
        XCTAssertEqual(openedCanvasPage, destinationCanvasPage)
        XCTAssertEqual(modelController.canvasPageCollection.all.count, 2)

        XCTAssertEqual(modelController.canvasLinkCollection.all.count, 1)
        let link = try XCTUnwrap(modelController.canvasLinkCollection.all.first)
        XCTAssertEqual(link.destinationPage, openedCanvasPage)
        XCTAssertEqual(link.sourcePage, canvasPage)
        XCTAssertEqual(link.link, PageLink(destination: page.id))
    }

    func test_openPageLinkedFrom_createsNewCanvasPageWithSuppliedPageAndCreatesLinkFromSourceIfExistingModeSuppliedButPageDoesntExist() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let canvasPage = CanvasPage.create(in: modelController)

        XCTAssertEqual(modelController.canvasLinkCollection.all.count, 0)
        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: canvasPage, with: PageLink(destination: page.id), mode: .existing).first)
        XCTAssertEqual(newCanvasPage.page, page)
        XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(newCanvasPage))

        XCTAssertEqual(modelController.canvasLinkCollection.all.count, 1)
        let link = try XCTUnwrap(modelController.canvasLinkCollection.all.first)
        XCTAssertEqual(link.destinationPage, newCanvasPage)
        XCTAssertEqual(link.sourcePage, canvasPage)
        XCTAssertEqual(link.link, PageLink(destination: page.id))
    }

    func test_openPageLinkedFrom_addsNewPageToRightIfNoOtherPageThere() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 30 + GlobalConstants.linkedPageOffset, y: 30, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_addsNewPageToLeftIfPageOnRightAndNoOtherPageThere() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) { $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20) }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 40, y: 20, width: 100, height: 100)
            $0.canvas = canvas
        } //Left

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 - GlobalConstants.linkedPageOffset - 20, y: 30, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_addsNewPageToBottomIfPagesOnLeftAndRightAndNoOtherPageThere() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 40, y: 20, width: 100, height: 100)
            $0.canvas = canvas
        } //Left
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -50, y: 20, width: 50, height: 20)
            $0.canvas = canvas
        } // Right

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10, y: 50 + GlobalConstants.linkedPageOffset, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_addsNewPageToTopIfPagesOnLeftRightAndBottomAndNoOtherPageThere() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 40, y: 20, width: 100, height: 100)
            $0.canvas = canvas
        } //Left
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -50, y: 20, width: 50, height: 20)
            $0.canvas = canvas
        } // Right
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 0, y: 60, width: 50, height: 50)
            $0.canvas = canvas
        } // Bottom

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10, y: 30 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_addsNewPageToRightIfPagesOnAllSides() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 40, y: 20, width: 100, height: 100)
            $0.canvas = canvas
        } //Left
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -50, y: 20, width: 50, height: 20)
            $0.canvas = canvas
        } // Right
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 0, y: 60, width: 50, height: 50)
            $0.canvas = canvas
        } // Bottom
        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 0, y: -30, width: 50, height: 40)
            $0.canvas = canvas
        } // Top

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 30 + GlobalConstants.linkedPageOffset, y: 30, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_addsNewPageToLeftIfParentOfSourceSetAndOnRightAndNoOtherPageExistsThere() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let rootPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 40, y: 40, width: 20, height: 20)
            $0.canvas = canvas
        }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
            $0.parent = rootPage
        }

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: 30, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_addsNewPageToTopIfParentOfSourceSetAndOnBottomAndNoOtherPageExistsThere() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let rootPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 90, width: 20, height: 20)
            $0.canvas = canvas
        }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
            $0.parent = rootPage
        }

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10, y: 30 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_addsNewPageToBottomIfParentOfSourceSetAndOnTopAndNoOtherPageExistsThere() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let rootPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: -90, width: 20, height: 20)
            $0.canvas = canvas
        }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
            $0.parent = rootPage
        }

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10, y: 50 + GlobalConstants.linkedPageOffset, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnRightAddsAbove() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 90, y: 30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 90, y: 30 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnTopRightAddsToBottomRight() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 90, y: 30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing right child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 90, y: -30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top right child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 90, y: 50 + GlobalConstants.linkedPageOffset, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnBottomRightAddsToTopRight() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 90, y: 20, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing right child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 90, y: 80, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom right child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 90, y: 20 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnLeftAddsAbove() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -110, y: 30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: -110, y: 30 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnTopLeftAddsToBottomLeft() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -110, y: 30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing right child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -110, y: -30, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top left child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: -110, y: 50 + GlobalConstants.linkedPageOffset, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnBottomLeftAddsToTopLeft() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -110, y: 20, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing right child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -110, y: 80, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom left child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: -110, y: 20 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnTopAddsToRight() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: -90, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: -90, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnTopLeftAddsToTopRight() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: -90, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -20, y: -90, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top left child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: -90, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnTopRightAddsToTopLeft() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 20, y: -90, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 60, y: -90, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing top right child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 20 - GlobalConstants.linkedPageOffset - 20, y: -90, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnBottomAddsToRight() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 110, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: 110, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnBottomLeftAddsToBottomRight() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 110, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: -20, y: 110, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom left child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: 110, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifLinkedPageAlreadyExistsOnBottomRightAddsToBottomLeft() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 20, y: 110, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom child

        CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 60, y: 110, width: 20, height: 20)
            $0.parent = parentPage
            $0.canvas = canvas
        } //existing bottom right child

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 20 - GlobalConstants.linkedPageOffset - 20, y: 110, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_tellsHierarchyRestorerToRestoreFirstMatchingHierarchy() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let mockPageHierarchyRestorer = MockPageHierarchyRestorer(canvas: canvas)
        canvas.hierarchyRestorer = mockPageHierarchyRestorer

        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }
        PageHierarchy.create(in: modelController) { // non-matching hierarchy
            $0.canvas = canvas
            $0.entryPoints = []
        }
        let matchingHierarchy = PageHierarchy.create(in: modelController) {
            $0.canvas = canvas
            $0.entryPoints = [PageHierarchy.EntryPoint(pageLink: PageLink(destination: page.id), relativePosition: .zero)]
        }

        canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new)

        XCTAssertTrue(mockPageHierarchyRestorer.mockRestoreHierarchy.wasCalled)
        let (hierarchy, canvasPage, pageLink) = try XCTUnwrap(mockPageHierarchyRestorer.mockRestoreHierarchy.arguments.first)
        XCTAssertEqual(hierarchy, matchingHierarchy)
        XCTAssertEqual(canvasPage, parentPage)
        XCTAssertEqual(pageLink, PageLink(destination: page.id))
    }

    func test_openPageLinkedFrom_doesntTellHieararchyRestorerToRestoreHierarchyIfNoneExists() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let secondCanvas = Canvas.create(in: modelController)
        let mockPageHierarchyRestorer = MockPageHierarchyRestorer(canvas: canvas)
        canvas.hierarchyRestorer = mockPageHierarchyRestorer

        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }
        PageHierarchy.create(in: modelController) { // non-matching hierarchy
            $0.canvas = secondCanvas
            $0.entryPoints = []
        }

        canvas.open(page, linkedFrom: parentPage, with: PageLink(destination: page.id), mode: .new)

        XCTAssertFalse(mockPageHierarchyRestorer.mockRestoreHierarchy.wasCalled)
    }


    //MARK: - close(_:)
    func test_closeCanvasPage_createsHierarchyForClosedPage() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvas = Canvas.create(in: modelController)
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }
        let page = Page.create(in: modelController)
        let canvasPage = CanvasPage.create(in: modelController) {
            $0.page = page
            $0.canvas = canvas
            $0.parent = parentPage
            $0.frame = CGRect(x: 40, y: 50, width: 60, height: 70)
        }

        canvas.close(canvasPage)

        let hierarchiesForParent = try XCTUnwrap(canvas.closedPageHierarchies[parentPage.id])
        let hierarchy = try XCTUnwrap(hierarchiesForParent[page.id])

        XCTAssertEqual(hierarchy.id, canvasPage.id)
        XCTAssertEqual(hierarchy.pageID, page.id)
        XCTAssertEqual(hierarchy.frame, canvasPage.frame)
        XCTAssertEqual(hierarchy.children.count, 0)
    }

    func test_closeCanvasPage_includesAllChildPagesInCreatedHierarchy() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvas = Canvas.create(in: modelController)
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }
        let page = Page.create(in: modelController)
        let canvasPage = CanvasPage.create(in: modelController) {
            $0.page = page
            $0.canvas = canvas
            $0.parent = parentPage
            $0.frame = CGRect(x: 40, y: 50, width: 60, height: 70)
        }

        let page2 = Page.create(in: modelController)
        let childPage1 = CanvasPage.create(in: modelController) {
            $0.page = page2
            $0.canvas = canvas
            $0.parent = canvasPage
            $0.frame = CGRect(x: 80, y: 90, width: 100, height: 110)
        }

        let page3 = Page.create(in: modelController)
        let childPage2 = CanvasPage.create(in: modelController) {
            $0.page = page3
            $0.canvas = canvas
            $0.parent = canvasPage
            $0.frame = CGRect(x: 120, y: 130, width: 140, height: 150)
        }

        canvas.close(canvasPage)

        let hierarchiesForParent = try XCTUnwrap(canvas.closedPageHierarchies[parentPage.id])
        let hierarchy = try XCTUnwrap(hierarchiesForParent[page.id])
        XCTAssertEqual(hierarchy.children.count, 2)
        XCTAssertTrue(hierarchy.children.contains(where: { $0.id == childPage1.id }))
        XCTAssertTrue(hierarchy.children.contains(where: { $0.id == childPage2.id }))
    }


    //MARK: - addPages(_:centredOn:)
    func test_addPagesCentredOn_createsNewCanvasPageForEachSuppliedPage() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page1 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let page2 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 30, height: 40) }
        let page3 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 50, height: 30) }

        let newCanvasPages = canvas.addPages([page1, page2, page3])
        XCTAssertEqual(newCanvasPages.count, 3)
        if let canvasPage = newCanvasPages[safe: 0] {
            XCTAssertEqual(canvasPage.page, page1)
            XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(canvasPage))
        } else {
            XCTFail()
        }

        if let canvasPage = newCanvasPages[safe: 1] {
            XCTAssertEqual(canvasPage.page, page2)
            XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(canvasPage))
        } else {
            XCTFail()
        }

        if let canvasPage = newCanvasPages[safe: 2] {
            XCTAssertEqual(canvasPage.page, page3)
            XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(canvasPage))
        } else {
            XCTFail()
        }
    }

    func test_addPagesCentredOn_centresFirstPageOnSuppliedPoint() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController) {
            $0.viewPort = CGRect(x: 40, y: 40, width: 100, height: 100)
        }
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 80, height: 90) }
        let page2 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 100, height: 50) }
        let page3 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 50, height: 120) }

        let canvasPages = canvas.addPages([page, page2, page3], centredOn: CGPoint(x: 60, y: 30))
        XCTAssertEqual(canvasPages.first?.frame, CGRect(x: 20, y: -15, width: 80, height: 90))
    }

    func test_addPagesCentredOn_centresFirstPageInViewPortIfNoPointSupplied() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController) {
            $0.viewPort = CGRect(x: 40, y: 40, width: 100, height: 100)
        }
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 80, height: 90) }
        let page2 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 100, height: 50) }
        let page3 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 50, height: 120) }

        let canvasPages = canvas.addPages([page, page2, page3])
        XCTAssertEqual(canvasPages.first?.frame, CGRect(x: 50, y: 45, width: 80, height: 90))
    }

    func test_addPagesCentredOn_stacksSubsequentPagesDownFromFirstIfGivenPoint() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController) {
            $0.viewPort = CGRect(x: 40, y: 40, width: 100, height: 100)
        }
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 80, height: 90) }
        let page2 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 100, height: 50) }
        let page3 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 50, height: 120) }

        let canvasPages = canvas.addPages([page, page2, page3], centredOn: CGPoint(x: 60, y: 30))
        XCTAssertEqual(canvasPages[safe: 1]?.frame, CGRect(x: 40, y: 5, width: 100, height: 50))
        XCTAssertEqual(canvasPages[safe: 2]?.frame, CGRect(x: 60, y: 25, width: 50, height: 120))
    }

    func test_addPagesCentredOn_stacksSubsequentPagesDownFromFirstIfNoPointSupplieds() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController) {
            $0.viewPort = CGRect(x: 40, y: 40, width: 100, height: 100)
        }
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 80, height: 90) }
        let page2 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 100, height: 50) }
        let page3 = Page.create(in: modelController) { $0.contentSize = CGSize(width: 50, height: 120) }

        let canvasPages = canvas.addPages([page, page2, page3])
        XCTAssertEqual(canvasPages[safe: 1]?.frame, CGRect(x: 70, y: 65, width: 100, height: 50))
        XCTAssertEqual(canvasPages[safe: 2]?.frame, CGRect(x: 90, y: 85, width: 50, height: 120))
    }

    //MARK: - .sortedPages
    func test_sortedPages_returnsPagesSortedByZIndexAscending() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)

        let page = Page.create(in: modelController)
        let page2 = Page.create(in: modelController)
        let page3 = Page.create(in: modelController)

        let canvasPages = canvas.addPages([page, page2, page3])

        let canvasPage = try XCTUnwrap(canvasPages[safe: 0])
        let canvasPage2 = try XCTUnwrap(canvasPages[safe: 1])
        let canvasPage3 = try XCTUnwrap(canvasPages[safe: 2])

        canvasPage2.zIndex = 2
        canvasPage.zIndex = 1
        canvasPage3.zIndex = 0

        XCTAssertEqual(canvas.sortedPages, [canvasPage3, canvasPage, canvasPage2])
    }
}
