//
//  CanvasTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import CoppiceCore

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
        let id = try XCTUnwrap(plist["id"] as? String)
        XCTAssertEqual(id, canvas.id.stringRepresentation)
    }

    func test_plistRepresentation_containsTitle() throws {
        let canvas = Canvas()
        canvas.title = "Hello World"
        let plist = canvas.plistRepresentation
        let title = try XCTUnwrap(plist["title"] as? String)
        XCTAssertEqual(title, "Hello World")
    }

    func test_plistRepresentation_containsDateCreated() throws {
        let canvas = Canvas()
        canvas.dateCreated = Date(timeIntervalSinceReferenceDate: 1000)
        let plist = canvas.plistRepresentation
        let date = try XCTUnwrap(plist["dateCreated"] as? Date)
        XCTAssertEqual(date, Date(timeIntervalSinceReferenceDate: 1000))
    }

    func test_plistRepresentation_containsDateModified() throws {
        let canvas = Canvas()
        canvas.dateModified = Date(timeIntervalSinceReferenceDate: 42)
        let plist = canvas.plistRepresentation
        let date = try XCTUnwrap(plist["dateModified"] as? Date)
        XCTAssertEqual(date, Date(timeIntervalSinceReferenceDate: 42))
    }

    func test_plistRepresentation_containsSortIndex() throws {
        let canvas = Canvas()
        canvas.sortIndex = 4
        let plist = canvas.plistRepresentation
        let sortIndex = try XCTUnwrap(plist["sortIndex"] as? Int)
        XCTAssertEqual(sortIndex, 4)
    }

    func test_plistRepresentation_containsTheme() throws {
        let canvas = Canvas()
        canvas.theme = .dark
        let plist = canvas.plistRepresentation
        let theme = try XCTUnwrap(plist["theme"] as? String)
        XCTAssertEqual(theme, Canvas.Theme.dark.rawValue)
    }

    func test_plistRepresentation_containsViewPortIfSet() throws {
        let canvas = Canvas()
        canvas.viewPort = CGRect(x: 1, y: 2, width: 30, height: 40)
        let plist = canvas.plistRepresentation
        let viewPort = try XCTUnwrap(plist["viewPort"] as? String)
        XCTAssertEqual(viewPort, NSStringFromRect(CGRect(x: 1, y: 2, width: 30, height: 40)))
    }

    func test_plistRepresentation_doesntContainViewPortIfNotSet() {
        let canvas = Canvas()
        canvas.viewPort = nil
        let plist = canvas.plistRepresentation
        XCTAssertNil(plist["viewPort"])
    }

    func test_plistRepresentation_containsThumbnailIfSet() throws {
        let canvas = Canvas()
        canvas.thumbnail = NSImage(named: "NSAddTemplate")!
        let plist = canvas.plistRepresentation
        let thumbnail = try XCTUnwrap(plist["thumbnail"] as? ModelFile)
        XCTAssertEqual(thumbnail.type, "thumbnail")
        XCTAssertEqual(thumbnail.filename, "\(canvas.id.uuid.uuidString)-thumbnail.png")
        XCTAssertNotNil(thumbnail.data)
    }

    func test_plistRepresentation_doesntContainThumbnailifNotSet() {
        let canvas = Canvas()
        canvas.thumbnail = nil
        let plist = canvas.plistRepresentation
        XCTAssertNil(plist["thumbnail"])
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
        var pageHierarchies = [ModelID: [ModelID: PageHierarchy]]()
        let canvasPageID1 = CanvasPage.modelID(with: UUID())
        let canvasPageID2 = CanvasPage.modelID(with: UUID())
        let pageID1 = Page.modelID(with: UUID())
        let pageID2 = Page.modelID(with: UUID())
        let pageID3 = Page.modelID(with: UUID())
        pageHierarchies[canvasPageID1] = [pageID1: PageHierarchy(canvasPage: canvasPage1)!]
        pageHierarchies[canvasPageID2] = [pageID2: PageHierarchy(canvasPage: canvasPage2)!,
                                      pageID3: PageHierarchy(canvasPage: canvasPage3)!]

        canvas.closedPageHierarchies = pageHierarchies

        let plist = canvas.plistRepresentation
        let hierarchies = try XCTUnwrap(plist["closedPageHierarchies"] as? [String : [String : Any ]])
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
        let sortIndex = try XCTUnwrap(plist["zoomFactor"] as? CGFloat)
        XCTAssertEqual(sortIndex, 0.25)
    }

    func test_plistRepresentation_includesAnyOtherProperties() throws {
        let canvas = Canvas()

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "foo": "bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
            "thumbnail": ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
            "testingAttribute": 12345
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        let plistRepresentation = canvas.plistRepresentation
        XCTAssertEqual(plistRepresentation["foo"] as? String, "bar")
        XCTAssertEqual(plistRepresentation["testingAttribute"] as? Int, 12345)
        XCTAssertEqual(plistRepresentation["id"] as? String, canvas.id.stringRepresentation)
    }


    //MARK: - update(fromPlistRepresentation:)
    func test_updateFromPlistRepresentation_doesntUpdateIfIDsDontMatch() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": "baz",
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 30),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1453),
            "sortIndex": 5
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .idsDontMatch)
        }
    }

    func test_updateFromPlistRepresentation_updatesTitle() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 31),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1454),
            "sortIndex": 4,
            "theme": "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.title, "Hello Bar")
    }

    func test_updateFromPlistRepresentation_throwsIfTitleMissing() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "dateCreated": Date(timeIntervalSinceReferenceDate: 30),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1453),
            "sortIndex": 5,
            "theme": "auto",
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("title"))
        }
    }

    func test_updateFromPlistRepresentation_updatesDateCreated() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 3,
            "theme": "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.dateCreated, Date(timeIntervalSinceReferenceDate: 32))
    }

    func test_updateFromPlistRepresentation_throwsIfDateCreatedMissing() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateModified": Date(timeIntervalSinceReferenceDate: 1453),
            "sortIndex": 5,
            "theme": "auto",
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("dateCreated"))
        }
    }

    func test_updateFromPlistRepresentation_updatesDateModified() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 33),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1456),
            "sortIndex": 2,
            "theme": "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.dateModified, Date(timeIntervalSinceReferenceDate: 1456))
    }

    func test_updateFromPlistRepresentation_throwsIfDateModifiedMissing() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 30),
            "sortIndex": 5,
            "theme": "auto",
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("dateModified"))
        }
    }

    func test_updateFromPlistRepresentation_updatesSortIndex() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.sortIndex, 1)
    }

    func test_updateFromPlistRepresentation_throwsIfSortIndexMissing() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 30),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1453),
            "theme": "auto",
        ]

        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("sortIndex"))
        }
    }

    func test_updateFromPlistRepresentation_updatesTheme() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 29),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1452),
            "sortIndex": 1,
            "theme": "dark",
        ]
        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))
        XCTAssertEqual(canvas.theme, .dark)
    }

    func test_updateFromPlistRepresentation_throwsIfThemeMissing() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 29),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1452),
            "sortIndex": 1,
        ]
        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("theme"))
        }
    }

    func test_updateFromPlistRepresentation_throwsIfThemeDoesntMatch() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 29),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1452),
            "sortIndex": 1,
            "theme": "possum",
        ]
        XCTAssertThrowsError(try canvas.update(fromPlistRepresentation: plist), "") {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("theme"))
        }
    }

    func test_updateFromPlistRepresentation_updatesViewPortIfInPlist() {
        let canvas = Canvas()
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
            "viewPort": NSStringFromRect(CGRect(x: 9, y: 8, width: 7, height: 6)),
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.viewPort, CGRect(x: 9, y: 8, width: 7, height: 6))
    }

    func test_updateFromPlistRepresentation_setsViewPortToNilIfNotInPlist() {
        let canvas = Canvas()
        canvas.viewPort = CGRect(x: 99, y: 88, width: 77, height: 66)
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertNil(canvas.viewPort)
    }

    func test_updateFromPlistRepresentation_updatesThumbnailIfInPlist() {
        let canvas = Canvas()
        canvas.thumbnail = NSImage(named: "NSRemoveTemplate")!

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
            "thumbnail": ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:])
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.thumbnail?.pngData(), expectedImageData)
    }

    func test_updateFromPlistRepresentation_setsThumbnailToNilIfNotInPlist() {
        let canvas = Canvas()
        canvas.thumbnail = NSImage(named: "NSRemoveTemplate")!
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
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
        let hierarchyPlist = PageHierarchy(canvasPage: canvasPage)!.plistRepresentation
        let hierarchyDict = [canvasPageID.stringRepresentation: [pageID.stringRepresentation: hierarchyPlist]]

        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
            "closedPageHierarchies": hierarchyDict
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
        let pageHierarchy = PageHierarchy(canvasPage: canvasPage)!

        canvas.closedPageHierarchies = [canvasPageID: [pageID: pageHierarchy]]

        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))
        XCTAssertEqual(canvas.closedPageHierarchies.count, 0)
    }

    func test_updateFromPlistRepresentation_updatesZoomFactor() throws {
        let canvas = Canvas()
        canvas.thumbnail = NSImage(named: "NSRemoveTemplate")!

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
            "thumbnail": ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
            "zoomFactor": CGFloat(0.75)
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.zoomFactor, 0.75)
    }

    func test_updateFromPlistRepresentation_setsZoomFactorTo1IfNoneExistsInPlist() throws {
        let canvas = Canvas()

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
            "thumbnail": ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.zoomFactor, 1)
    }

    func test_updateFromPlistRepresentation_addsAnythingElseInPlistToOtherProperties() throws {
        let canvas = Canvas()

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "foo": "bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
            "thumbnail": ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
            "testingAttribute": 12345
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))
        XCTAssertEqual(canvas.otherProperties["foo"] as? String, "bar")
        XCTAssertEqual(canvas.otherProperties["testingAttribute"] as? Int, 12345)
    }

    func test_updateFromPlistRepresentation_doesntIncludeAnySupportPlistKeysInOtherProperties() throws {
        let canvas = Canvas()

        let expectedImageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let plist: [String: Any] = [
            "id": canvas.id.stringRepresentation,
            "title": "Hello Bar",
            "foo": "bar",
            "dateCreated": Date(timeIntervalSinceReferenceDate: 32),
            "dateModified": Date(timeIntervalSinceReferenceDate: 1455),
            "sortIndex": 1,
            "theme": "auto",
            "thumbnail": ModelFile(type: "thumbnail", filename: nil, data: expectedImageData, metadata: [:]),
            "testingAttribute": 12345
        ]

        XCTAssertNoThrow(try canvas.update(fromPlistRepresentation: plist))

        XCTAssertEqual(canvas.otherProperties.count, 2)
        for key in Canvas.PlistKeys.allCases {
            XCTAssertNil(canvas.otherProperties[key.rawValue])
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
    func test_openPageLinkedFrom_createsNewCanvasPageWithSuppliedPageAndSetsParentAsSource() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let canvasPage = CanvasPage.create(in: modelController)

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: canvasPage).first)
        XCTAssertEqual(newCanvasPage.page, page)
        XCTAssertEqual(newCanvasPage.parent, canvasPage)
        XCTAssertTrue(modelController.collection(for: CanvasPage.self).all.contains(newCanvasPage))
    }

    func test_openPageLinkedFrom_addsNewPageToRightIfNoOtherPageThere() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas = Canvas.create(in: modelController)
        let page = Page.create(in: modelController) { $0.contentSize = CGSize(width: 20, height: 20) }
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10, y: 50 + GlobalConstants.linkedPageOffset, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnRightAddsAbove() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 90, y: 30 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnTopRightAddsToBottomRight() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 90, y: 50 + GlobalConstants.linkedPageOffset, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnBottomRightAddsToTopRight() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 90, y: 20 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnLeftAddsAbove() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: -110, y: 30 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnTopLeftAddsToBottomLeft() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: -110, y: 50 + GlobalConstants.linkedPageOffset, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnBottomLeftAddsToTopLeft() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: -110, y: 20 - GlobalConstants.linkedPageOffset - 20, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnTopAddsToRight() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: -90, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnTopLeftAddsToTopRight() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: -90, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnTopRightAddsToTopLeft() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 20 - GlobalConstants.linkedPageOffset - 20, y: -90, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnBottomAddsToRight() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: 110, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnBottomLeftAddsToBottomRight() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 10 + GlobalConstants.linkedPageOffset + 20, y: 110, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_ifChildAlreadyExistsOnBottomRightAddsToBottomLeft() throws {
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

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 20 - GlobalConstants.linkedPageOffset - 20, y: 110, width: 20, height: 20))
    }

    func test_openPageLinkedFrom_openingClosedHierarchyCreatesCanvasPageUsingIDPageAndFrameFromHierarchy() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvas = Canvas.create(in: modelController)
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }
        let page = Page.create(in: modelController)

        let canvasPageID = CanvasPage.modelID(with: UUID())
        let hierarchy = PageHierarchy(id: canvasPageID, pageID: page.id, frame: CGRect(x: 100, y: 20, width: 35, height: 42), children: [])

        canvas.closedPageHierarchies = [parentPage.id: [page.id: hierarchy]]

        let newCanvasPage = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage).first)
        XCTAssertEqual(newCanvasPage.id, canvasPageID)
        XCTAssertEqual(newCanvasPage.page, page)
        XCTAssertEqual(newCanvasPage.frame, CGRect(x: 100, y: 20, width: 35, height: 42))
    }

    func test_openPageLinkedFrom_openingClosedHierarchyOpensAllChildHierarchiesToo() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvas = Canvas.create(in: modelController)
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }
        let page = Page.create(in: modelController)
        let page2 = Page.create(in: modelController)
        let page3 = Page.create(in: modelController)

        let childCanvasPage1ID = CanvasPage.modelID(with: UUID())
        let childHierarchy1 = PageHierarchy(id: childCanvasPage1ID, pageID: page2.id, frame: CGRect(x: 200, y: 30, width: 42, height: 55), children: [])
        let childCanvasPage2ID = CanvasPage.modelID(with: UUID())
        let childHierarchy2 = PageHierarchy(id: childCanvasPage2ID, pageID: page3.id, frame: CGRect(x: 300, y: 40, width: 55, height: 62), children: [])
        let rootCanvasPageID = CanvasPage.modelID(with: UUID())
        let rootHierarchy = PageHierarchy(id: rootCanvasPageID, pageID: page.id, frame: CGRect(x: 100, y: 20, width: 35, height: 42), children: [childHierarchy1, childHierarchy2])

        canvas.closedPageHierarchies = [parentPage.id: [page.id: rootHierarchy]]

        let canvasPages = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage))
        XCTAssertEqual(canvasPages.count, 3)
        XCTAssertTrue(canvasPages.contains(where: {
            ($0.id == childCanvasPage1ID) && ($0.page == page2) && ($0.frame == CGRect(x: 200, y: 30, width: 42, height: 55))
        }))
        XCTAssertTrue(canvasPages.contains(where: {
            ($0.id == childCanvasPage2ID) && ($0.page == page3) && ($0.frame == CGRect(x: 300, y: 40, width: 55, height: 62))
        }))
    }

    func test_openPageLinkedFrom_openinglosedHierarchySetsCorrectSourcePageOnAllHierarchies() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvas = Canvas.create(in: modelController)
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }
        let page = Page.create(in: modelController)
        let page2 = Page.create(in: modelController)
        let page3 = Page.create(in: modelController)

        let childCanvasPage1ID = CanvasPage.modelID(with: UUID())
        let childHierarchy1 = PageHierarchy(id: childCanvasPage1ID, pageID: page2.id, frame: CGRect(x: 200, y: 30, width: 42, height: 55), children: [])
        let childCanvasPage2ID = CanvasPage.modelID(with: UUID())
        let childHierarchy2 = PageHierarchy(id: childCanvasPage2ID, pageID: page3.id, frame: CGRect(x: 300, y: 40, width: 55, height: 62), children: [])
        let rootCanvasPageID = CanvasPage.modelID(with: UUID())
        let rootHierarchy = PageHierarchy(id: rootCanvasPageID, pageID: page.id, frame: CGRect(x: 100, y: 20, width: 35, height: 42), children: [childHierarchy1, childHierarchy2])

        canvas.closedPageHierarchies = [parentPage.id: [page.id: rootHierarchy]]

        let canvasPages = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage))
        XCTAssertEqual(canvasPages.filter({ $0.parent?.id == parentPage.id}).count, 1)
        XCTAssertEqual(canvasPages.filter({ $0.parent?.id == rootCanvasPageID}).count, 2)
    }

    func test_openPageLinkedFrom_openingClosedHierarchySetsCanvasToReceiverOnAllPages() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvas = Canvas.create(in: modelController)
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }
        let page = Page.create(in: modelController)
        let page2 = Page.create(in: modelController)
        let page3 = Page.create(in: modelController)

        let childCanvasPage1ID = CanvasPage.modelID(with: UUID())
        let childHierarchy1 = PageHierarchy(id: childCanvasPage1ID, pageID: page2.id, frame: CGRect(x: 200, y: 30, width: 42, height: 55), children: [])
        let childCanvasPage2ID = CanvasPage.modelID(with: UUID())
        let childHierarchy2 = PageHierarchy(id: childCanvasPage2ID, pageID: page3.id, frame: CGRect(x: 300, y: 40, width: 55, height: 62), children: [])
        let rootCanvasPageID = CanvasPage.modelID(with: UUID())
        let rootHierarchy = PageHierarchy(id: rootCanvasPageID, pageID: page.id, frame: CGRect(x: 100, y: 20, width: 35, height: 42), children: [childHierarchy1, childHierarchy2])

        canvas.closedPageHierarchies = [parentPage.id: [page.id: rootHierarchy]]

        let canvasPages = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage))
        XCTAssertEqual(canvasPages[safe: 0]?.canvas, canvas)
        XCTAssertEqual(canvasPages[safe: 1]?.canvas, canvas)
        XCTAssertEqual(canvasPages[safe: 2]?.canvas, canvas)
    }

    func test_openPageLinkedFrom_hierarchyIsRemovedFromClosedHierarchiesWhenOpening() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvas = Canvas.create(in: modelController)
        let parentPage = CanvasPage.create(in: modelController) {
            $0.frame = CGRect(x: 10, y: 30, width: 20, height: 20)
            $0.canvas = canvas
        }
        let page = Page.create(in: modelController)
        let page2 = Page.create(in: modelController)
        let page3 = Page.create(in: modelController)

        let childCanvasPage1ID = CanvasPage.modelID(with: UUID())
        let childHierarchy1 = PageHierarchy(id: childCanvasPage1ID, pageID: page2.id, frame: CGRect(x: 200, y: 30, width: 42, height: 55), children: [])
        let childCanvasPage2ID = CanvasPage.modelID(with: UUID())
        let childHierarchy2 = PageHierarchy(id: childCanvasPage2ID, pageID: page3.id, frame: CGRect(x: 300, y: 40, width: 55, height: 62), children: [])
        let rootCanvasPageID = CanvasPage.modelID(with: UUID())
        let rootHierarchy = PageHierarchy(id: rootCanvasPageID, pageID: page.id, frame: CGRect(x: 100, y: 20, width: 35, height: 42), children: [childHierarchy1, childHierarchy2])

        canvas.closedPageHierarchies = [parentPage.id: [page.id: rootHierarchy]]

        _ = try XCTUnwrap(canvas.open(page, linkedFrom: parentPage))

        XCTAssertEqual(canvas.closedPageHierarchies[parentPage.id]?.count, 0)
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

    func test_closeCanvasPage_removesCanvasPageAndAllChildrenFromCanvas() {
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
        }

        let page2 = Page.create(in: modelController)
        CanvasPage.create(in: modelController) {
            $0.page = page2
            $0.canvas = canvas
            $0.parent = canvasPage
        }

        let page3 = Page.create(in: modelController)
        CanvasPage.create(in: modelController) {
            $0.page = page3
            $0.canvas = canvas
            $0.parent = canvasPage
        }

        XCTAssertEqual(canvas.pages.count, 4)

        canvas.close(canvasPage)

        XCTAssertEqual(canvas.pages.count, 1)
    }

    func test_closeCanvasPage_deletesCanvasPageAndAllChildrenFromCanvasPageCollection() {
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
        }

        let page2 = Page.create(in: modelController)
        let childPage1 = CanvasPage.create(in: modelController) {
            $0.page = page2
            $0.canvas = canvas
            $0.parent = canvasPage
        }

        let page3 = Page.create(in: modelController)
        let childPage2 = CanvasPage.create(in: modelController) {
            $0.page = page3
            $0.canvas = canvas
            $0.parent = canvasPage
        }

        XCTAssertNotNil(modelController.collection(for: CanvasPage.self).objectWithID(canvasPage.id))
        XCTAssertNotNil(modelController.collection(for: CanvasPage.self).objectWithID(childPage1.id))
        XCTAssertNotNil(modelController.collection(for: CanvasPage.self).objectWithID(childPage2.id))

        canvas.close(canvasPage)

        XCTAssertNil(modelController.collection(for: CanvasPage.self).objectWithID(canvasPage.id))
        XCTAssertNil(modelController.collection(for: CanvasPage.self).objectWithID(childPage1.id))
        XCTAssertNil(modelController.collection(for: CanvasPage.self).objectWithID(childPage2.id))
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
}
