//
//  PlistV3Tests.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 01/08/2022.
//

import XCTest

@testable import CoppiceCore
import M3Data

final class PlistV3Tests: XCTestCase {
    func test_init_loadsTestPlistWithNoError() throws {
        let plist = TestData.Plist.V3().plist
        XCTAssertNoThrow(try Plist.V3(plist: plist))
    }

    //MARK: - Errors (Missing Collection)
    func test_errors_throwsMissingCollectionErrorIfCanvasesMissing() {
        let emptyArray = [[String: Any]]() as PlistValue
        let plist: [String: PlistValue] = ["version": 3, "pages": emptyArray, "canvasPages": emptyArray, "folders": emptyArray, "canvasLinks": emptyArray]
        do {
            _ = try Plist.V3(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingCollection("canvases") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingCollectionErrorIfPagesMissing() {
        let emptyArray = [[String: Any]]() as PlistValue
        let plist: [String: PlistValue] = ["version": 3, "canvases": emptyArray, "canvasPages": emptyArray, "folders": emptyArray, "canvasLinks": emptyArray]
        do {
            _ = try Plist.V3(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingCollection("pages") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingCollectionErrorIfCanvasPagesMissing() {
        let emptyArray = [[String: Any]]() as PlistValue
        let plist: [String: PlistValue] = ["version": 3, "pages": emptyArray, "canvases": emptyArray, "folders": emptyArray, "canvasLinks": emptyArray]
        do {
            _ = try Plist.V3(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingCollection("canvasPages") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingCollectionErrorIfFoldersMissing() {
        let emptyArray = [[String: Any]]() as PlistValue
        let plist: [String: PlistValue] = ["version": 3, "pages": emptyArray, "canvases": emptyArray, "canvasPages": emptyArray, "canvasLinks": emptyArray]
        do {
            _ = try Plist.V3(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingCollection("folders") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingCollectionErrorIfCanvasLinksMissing() {
        let emptyArray = [[String: Any]]() as PlistValue
        let plist: [String: PlistValue] = ["version": 3, "pages": emptyArray, "canvases": emptyArray, "canvasPages": emptyArray, "folders": emptyArray]
        do {
            _ = try Plist.V3(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingCollection("canvasLinks") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    //MARK: - Errors (missingID)
    func test_errors_throwsMissingIDErrorIfACanvasIsMissingAnID() {
        let emptyArray = [[String: Any]]() as PlistValue
        let plist: [String: PlistValue] = [
            "version": 3,
            "canvases": [["title": "Canvas Without ID"]],
            "pages": emptyArray,
            "canvasPages": emptyArray,
            "folders": emptyArray,
            "canvasLinks": emptyArray,
        ]

        do {
            _ = try Plist.V3(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingID(let object) {
            XCTAssertEqual(object as? [String: String], ["title": "Canvas Without ID"])
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingIDErrorIfAPageIsMissingAnID() {
        let emptyArray = [[String: Any]]() as PlistValue
        let plist: [String: PlistValue] = [
            "version": 3,
            "canvases": emptyArray,
            "pages": [
                ["id": Page.modelID(with: UUID()).stringRepresentation, "title": "Page With ID"],
                ["title": "Page Without ID"],
            ] as PlistValue,
            "canvasPages": emptyArray,
            "folders": emptyArray,
            "canvasLinks": emptyArray,
        ]

        do {
            _ = try Plist.V3(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingID(let object) {
            XCTAssertEqual(object as? [String: String], ["title": "Page Without ID"])
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingIDErrorIfACanvasPageIsMissingAnID() {
        let emptyArray = [[String: Any]]() as PlistValue
        let plist: [String: PlistValue] = [
            "version": 3,
            "canvases": emptyArray,
            "pages": emptyArray,
            "canvasPages": [
                ["id": Page.modelID(with: UUID()).stringRepresentation, "frame": NSStringFromRect(CGRect(x: 0, y: 2, width: 8, height: 9))],
                ["frame": NSStringFromRect(CGRect(x: 0, y: 12, width: 5, height: 4))],
            ] as PlistValue,
            "folders": emptyArray,
            "canvasLinks": emptyArray,
        ]

        do {
            _ = try Plist.V3(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingID(let object) {
            XCTAssertEqual(object as? [String: String], ["frame": NSStringFromRect(CGRect(x: 0, y: 12, width: 5, height: 4))])
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingIDErrorIfAFolderIsMissingAnID() {
        let emptyArray = [[String: Any]]() as PlistValue
        let plist: [String: PlistValue] = [
            "version": 3,
            "canvases": emptyArray,
            "pages": emptyArray,
            "canvasPages": emptyArray,
            "folders": [
                ["id": Page.modelID(with: UUID()).stringRepresentation, "title": "My Folder", "contents": [String]()] as [String: Any],
                ["title": "Second Folder", "contents": [String]()],
            ] as PlistValue,
            "canvasLinks": emptyArray,
        ]

        do {
            _ = try Plist.V3(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingID(let object) {
            XCTAssertEqual(object["title"] as? String, "Second Folder")
            XCTAssertEqual(object["contents"] as? [String], [])
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingIDErrorIfACanvasLinkIsMissingAnID() {
        let emptyArray = [[String: Any]]() as PlistValue
        let plist: [String: PlistValue] = [
            "version": 3,
            "canvases": emptyArray,
            "pages": emptyArray,
            "canvasPages": emptyArray,
            "folders": [
                ["id": CanvasLink.modelID(with: UUID()).stringRepresentation, "link": "coppice://12345"],
                ["link": "coppice://67890"],
            ] as PlistValue,
            "canvasLinks": emptyArray,
        ]

        do {
            _ = try Plist.V3(plist: plist)
            XCTFail("Error not thrown")
        } catch ModelPlist.Errors.missingID(let object) {
            XCTAssertEqual(object["link"] as? String, "coppice://67890")
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }
}
