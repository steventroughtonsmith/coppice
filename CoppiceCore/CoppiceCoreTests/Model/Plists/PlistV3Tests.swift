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
        let plist = TestPlists.V3().plist
        XCTAssertNoThrow(try Plist.V3(plist: plist))
    }

    //MARK: - Errors (Missing Collection)
    func test_errors_throwsMissingCollectionErrorIfCanvasesMissing() {
        let plist: [String: Any] = ["version": 3, "pages": [[String: Any]](), "canvasPages": [[String: Any]](), "folders": [[String: Any]](), "canvasLinks": [[String: Any]]()]
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
        let plist: [String: Any] = ["version": 3, "canvases": [[String: Any]](), "canvasPages": [[String: Any]](), "folders": [[String: Any]](), "canvasLinks": [[String: Any]]()]
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
        let plist: [String: Any] = ["version": 3, "pages": [[String: Any]](), "canvases": [[String: Any]](), "folders": [[String: Any]](), "canvasLinks": [[String: Any]]()]
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
        let plist: [String: Any] = ["version": 3, "pages": [[String: Any]](), "canvases": [[String: Any]](), "canvasPages": [[String: Any]](), "canvasLinks": [[String: Any]]()]
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
        let plist: [String: Any] = ["version": 3, "pages": [[String: Any]](), "canvases": [[String: Any]](), "canvasPages": [[String: Any]](), "folders": [[String: Any]]()]
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
        let plist: [String: Any] = [
            "version": 3,
            "canvases": [["title": "Canvas Without ID"]],
            "pages": [],
            "canvasPages": [],
            "folders": [],
            "canvasLinks": [],
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
        let plist: [String: Any] = [
            "version": 3,
            "canvases": [],
            "pages": [
                ["id": Page.modelID(with: UUID()).stringRepresentation, "title": "Page With ID"],
                ["title": "Page Without ID"],
            ],
            "canvasPages": [],
            "folders": [],
            "canvasLinks": [],
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
        let plist: [String: Any] = [
            "version": 3,
            "canvases": [],
            "pages": [],
            "canvasPages": [
                ["id": Page.modelID(with: UUID()).stringRepresentation, "frame": NSStringFromRect(CGRect(x: 0, y: 2, width: 8, height: 9))],
                ["frame": NSStringFromRect(CGRect(x: 0, y: 12, width: 5, height: 4))],
            ],
            "folders": [],
            "canvasLinks": [],
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
        let plist: [String: Any] = [
            "version": 3,
            "canvases": [],
            "pages": [],
            "canvasPages": [],
            "folders": [
                ["id": Page.modelID(with: UUID()).stringRepresentation, "title": "My Folder", "contents": []],
                ["title": "Second Folder", "contents": []],
            ],
            "canvasLinks": [],
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
        let plist: [String: Any] = [
            "version": 3,
            "canvases": [],
            "pages": [],
            "canvasPages": [],
            "folders": [
                ["id": CanvasLink.modelID(with: UUID()).stringRepresentation, "link": "coppice://12345"],
                ["link": "coppice://67890"],
            ],
            "canvasLinks": [],
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
