//
//  PlistV2Tests.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 01/08/2022.
//

import XCTest

@testable import CoppiceCore
import M3Data

final class PlistV2Tests: XCTestCase {
    func test_init_loadsTestPlistWithNoError() throws {
        let plist = TestData.Plist.V2().plist
        XCTAssertNoThrow(try Plist.V2(plist: plist))
    }

    //MARK: - Errors (Missing Collection)
    func test_errors_throwsMissingCollectionErrorIfCanvasesMissing() {
        let plist: [String: Any] = ["version": 2, "pages": [[String: Any]](), "canvasPages": [[String: Any]](), "folders": [[String: Any]]()]
        do {
            _ = try Plist.V2(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingCollection("canvases") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingCollectionErrorIfPagesMissing() {
        let plist: [String: Any] = ["version": 2, "canvases": [[String: Any]](), "canvasPages": [[String: Any]](), "folders": [[String: Any]]()]
        do {
            _ = try Plist.V2(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingCollection("pages") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingCollectionErrorIfCanvasPagesMissing() {
        let plist: [String: Any] = ["version": 2, "pages": [[String: Any]](), "canvases": [[String: Any]](), "folders": [[String: Any]]()]
        do {
            _ = try Plist.V2(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingCollection("canvasPages") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingCollectionErrorIfFoldersMissing() {
        let plist: [String: Any] = ["version": 2, "pages": [[String: Any]](), "canvases": [[String: Any]](), "canvasPages": [[String: Any]]()]
        do {
            _ = try Plist.V2(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingCollection("folders") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    //MARK: - Errors (missingID)
    func test_errors_throwsMissingIDErrorIfACanvasIsMissingAnID() {
        let plist: [String: Any] = [
            "version": 2,
            "canvases": [["title": "Canvas Without ID"]],
            "pages": [],
            "canvasPages": [],
            "folders": [],
        ]

        do {
            _ = try Plist.V2(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingID(let object) {
            XCTAssertEqual(object as? [String: String], ["title": "Canvas Without ID"])
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingIDErrorIfAPageIsMissingAnID() {
        let plist: [String: Any] = [
            "version": 2,
            "canvases": [],
            "pages": [
                ["id": Page.modelID(with: UUID()).stringRepresentation, "title": "Page With ID"],
                ["title": "Page Without ID"],
            ],
            "canvasPages": [],
            "folders": [],
        ]

        do {
            _ = try Plist.V2(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingID(let object) {
            XCTAssertEqual(object as? [String: String], ["title": "Page Without ID"])
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingIDErrorIfACanvasPageIsMissingAnID() {
        let plist: [String: Any] = [
            "version": 2,
            "canvases": [],
            "pages": [],
            "canvasPages": [
                ["id": Page.modelID(with: UUID()).stringRepresentation, "frame": NSStringFromRect(CGRect(x: 0, y: 2, width: 8, height: 9))],
                ["frame": NSStringFromRect(CGRect(x: 0, y: 12, width: 5, height: 4))],
            ],
            "folders": [],
        ]

        do {
            _ = try Plist.V2(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingID(let object) {
            XCTAssertEqual(object as? [String: String], ["frame": NSStringFromRect(CGRect(x: 0, y: 12, width: 5, height: 4))])
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingIDErrorIfAFolderIsMissingAnID() {
        let plist: [String: Any] = [
            "version": 2,
            "canvases": [],
            "pages": [],
            "canvasPages": [],
            "folders": [
                ["id": Page.modelID(with: UUID()).stringRepresentation, "title": "My Folder", "contents": []],
                ["title": "Second Folder", "contents": []],
            ],
        ]

        do {
            _ = try Plist.V2(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingID(let object) {
            XCTAssertEqual(object["title"] as? String, "Second Folder")
            XCTAssertEqual(object["contents"] as? [String], [])
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    //MARK: - migrateToNextVersion
    func test_migrateToNextVersion_doesntChangePages() throws {
        let testPlist = TestData.Plist.V2()
        let migratedPlist = try Plist.V2(plist: testPlist.plist).migrateToNextVersion()

        let migratedPages = try XCTUnwrap(migratedPlist["pages"] as? [NSDictionary])

        XCTAssertEqual(migratedPages, testPlist.plistPages as [NSDictionary])
    }

    func test_migrateToNextVersion_doesntChangeFolders() throws {
        let testPlist = TestData.Plist.V2()
        let migratedPlist = try Plist.V2(plist: testPlist.plist).migrateToNextVersion()

        let migratedFolders = try XCTUnwrap(migratedPlist["folders"] as? [NSDictionary])

        XCTAssertEqual(migratedFolders, testPlist.plistFolders as [NSDictionary])
    }

    func test_migrateToNextVersion_doesntChangeCanvases() throws {
        let testPlist = TestData.Plist.V2()
        let migratedPlist = try Plist.V2(plist: testPlist.plist).migrateToNextVersion()

        let migratedCanvases = try XCTUnwrap(migratedPlist["canvases"] as? [NSDictionary])

        XCTAssertEqual(migratedCanvases, testPlist.plistCanvases as [NSDictionary])
    }

    func test_migrateToNextVersion_doesntChangeSettings() throws {
        let testPlist = TestData.Plist.V2()
        let migratedPlist = try Plist.V2(plist: testPlist.plist).migrateToNextVersion()

        let migratedSettings = try XCTUnwrap(migratedPlist["settings"] as? NSDictionary)

        XCTAssertEqual(migratedSettings, testPlist.plistSettings as NSDictionary)
    }

    func test_migrateToNextVersion_changesVersionTo3() throws {
        let testPlist = TestData.Plist.V2()
        let migratedPlist = try Plist.V2(plist: testPlist.plist).migrateToNextVersion()

        let version = try XCTUnwrap(migratedPlist["version"] as? Int)

        XCTAssertEqual(version, 3)
    }

    func test_migrateToNextVersion_addsCanvasLinksForEveryCanvasPageWithParent() throws {
        let testPlist = TestData.Plist.V2()
        let migratedPlist = try Plist.V2(plist: testPlist.plist).migrateToNextVersion()

        let newCanvasLinks = try XCTUnwrap(migratedPlist["canvasLinks"] as? [[String: Any]])
        XCTAssertEqual(newCanvasLinks.count, 2)

        let firstLinkSourceID = CanvasPage.modelID(with: testPlist.canvasPageIDs[0]).stringRepresentation
        let firstLink = try XCTUnwrap(newCanvasLinks.first(where: { ($0["sourcePage"] as? String) == firstLinkSourceID}))
        let firstLinkDestinationID = CanvasPage.modelID(with: testPlist.canvasPageIDs[1]).stringRepresentation
        XCTAssertEqual(firstLink["destinationPage"] as? String, firstLinkDestinationID)

        let secondLinkSourceID = CanvasPage.modelID(with: testPlist.canvasPageIDs[1]).stringRepresentation
        let secondLink = try XCTUnwrap(newCanvasLinks.first(where: { ($0["sourcePage"] as? String) == secondLinkSourceID}))
        let secondLinkDestinationID = CanvasPage.modelID(with: testPlist.canvasPageIDs[3]).stringRepresentation
        XCTAssertEqual(secondLink["destinationPage"] as? String, secondLinkDestinationID)
    }

    func test_migrateToNextVersion_createsCorrectPageLinkForEveryCanvasLink() throws {
        let testPlist = TestData.Plist.V2()
        let migratedPlist = try Plist.V2(plist: testPlist.plist).migrateToNextVersion()

        let newCanvasLinks = try XCTUnwrap(migratedPlist["canvasLinks"] as? [[String: Any]])
        XCTAssertEqual(newCanvasLinks.count, 2)

        let firstLinkSourceID = CanvasPage.modelID(with: testPlist.canvasPageIDs[0]).stringRepresentation
        let firstLink = try XCTUnwrap(newCanvasLinks.first(where: { ($0["sourcePage"] as? String) == firstLinkSourceID}))
        let expectedFirstPageLink = PageLink(destination: Page.modelID(with: testPlist.pageIDs[1]),
                                             source: Page.modelID(with: testPlist.pageIDs[0]))
        XCTAssertEqual(firstLink["link"] as? String, expectedFirstPageLink.url.absoluteString)

        let secondLinkSourceID = CanvasPage.modelID(with: testPlist.canvasPageIDs[1]).stringRepresentation
        let secondLink = try XCTUnwrap(newCanvasLinks.first(where: { ($0["sourcePage"] as? String) == secondLinkSourceID}))
        let expectedSecondPageLink = PageLink(destination: Page.modelID(with: testPlist.pageIDs[2]),
                                              source: Page.modelID(with: testPlist.pageIDs[1]))
        XCTAssertEqual(secondLink["link"] as? String, expectedSecondPageLink.url.absoluteString)
    }

    func test_migrateToNextVersion_removesParentFromCanvasPagesButChangesNothingElse() throws {
        let testPlist = TestData.Plist.V2()
        let migratedPlist = try Plist.V2(plist: testPlist.plist).migrateToNextVersion()
        let targetPlist = TestData.Plist.V3()

        let migratedCanvasPages = try XCTUnwrap(migratedPlist["canvasPages"] as? [NSDictionary])

        XCTAssertEqual(migratedCanvasPages, targetPlist.plistCanvasPages as [NSDictionary])
    }

}
