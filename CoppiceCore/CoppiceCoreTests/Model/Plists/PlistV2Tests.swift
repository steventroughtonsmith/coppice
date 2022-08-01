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
        let plist = TestPlists.V2().plist
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
}
