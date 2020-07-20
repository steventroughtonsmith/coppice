//
//  PageHierarchyTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 14/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import CoppiceCore

class PageHierarchyTests: XCTestCase {

    var modelController: CoppiceModelController!
    var parentPage: CanvasPage!
    var childPage1: CanvasPage!
    var childPage2: CanvasPage!

    override func setUp() {
        super.setUp()
        self.modelController = CoppiceModelController(undoManager: UndoManager())
        let pageCollection = self.modelController.collection(for: Page.self)
        let page1 = pageCollection.newObject()
        let page2 = pageCollection.newObject()
        let page3 = pageCollection.newObject()
        let canvasPageCollection = self.modelController.collection(for: CanvasPage.self)
        self.parentPage = canvasPageCollection.newObject() {
            $0.page = page1
            $0.frame = CGRect(x: 10, y: 20, width: 30, height: 40)
        }
        self.childPage1 = canvasPageCollection.newObject() {
            $0.page = page2
            $0.frame = CGRect(x: -20, y: -10, width: 30, height: 40)
            $0.parent = self.parentPage
        }
        self.childPage2 = canvasPageCollection.newObject() {
            $0.page = page3
            $0.frame = CGRect(x: 90, y: 80, width: 70, height: 60)
            $0.parent = self.parentPage
        }
    }


    //MARK: - init(canvasPage:)
    func test_initCanvasPage_returnsNilIfPageIsNotSet() {
        self.parentPage.page = nil
        XCTAssertNil(PageHierarchy(canvasPage: self.parentPage))
    }

    func test_initCanvasPage_convertsChildrenToPageHierarchies() throws {
        let hierarchy = try XCTUnwrap(PageHierarchy(canvasPage: self.parentPage))
        XCTAssertEqual(hierarchy.children.count, 2)

        XCTAssertTrue(hierarchy.children.contains(where: {
            ($0.id == self.childPage1.id) && ($0.pageID == self.childPage1.page!.id) && ($0.frame == self.childPage1.frame)
        }))
        XCTAssertTrue(hierarchy.children.contains(where: {
            ($0.id == self.childPage2.id) && ($0.pageID == self.childPage2.page!.id) && ($0.frame == self.childPage2.frame)
        }))
    }

    func test_initCanvasPage_setsID_PageIDAndFrame() throws {
        let hierarchy = try XCTUnwrap(PageHierarchy(canvasPage: self.parentPage))
        XCTAssertEqual(hierarchy.id, self.parentPage.id)
        XCTAssertEqual(hierarchy.pageID, self.parentPage.page!.id)
        XCTAssertEqual(hierarchy.frame, self.parentPage.frame)
    }


    //MARK: - init(plistRepresentation:)
    func test_initPlistRepresentation_returnsNilIfIDNotInPlist() {
        XCTAssertNil(PageHierarchy(plistRepresentation: [
            "pageID": Page.modelID(with: UUID()).stringRepresentation,
            "frame": NSStringFromRect(.zero),
            "children": []
        ]))
    }

    func test_initPlistRepresentation_returnsNilIfPageIDNotInPlist() {
        XCTAssertNil(PageHierarchy(plistRepresentation: [
            "id": CanvasPage.modelID(with: UUID()).stringRepresentation,
            "frame": NSStringFromRect(.zero),
            "children": []
        ]))
    }

    func test_initPlistRepresentation_returnsNilIfFrameNotInPlist() {
        XCTAssertNil(PageHierarchy(plistRepresentation: [
            "id": CanvasPage.modelID(with: UUID()).stringRepresentation,
            "pageID": Page.modelID(with: UUID()).stringRepresentation,
            "children": []
        ]))
    }

    func test_initPlistRepresentation_returnsNilIfChildrenNotInPlist() {
        XCTAssertNil(PageHierarchy(plistRepresentation: [
            "id": CanvasPage.modelID(with: UUID()).stringRepresentation,
            "pageID": Page.modelID(with: UUID()).stringRepresentation,
            "frame": NSStringFromRect(.zero)
        ]))
    }

    func test_initPlistRepresentation_setsID_PageIDAndFrame() throws {
        let expectedID = CanvasPage.modelID(with: UUID())
        let expectedPageID = Page.modelID(with: UUID())
        let expectedFrame = CGRect(x: 10, y: 15, width: 20, height: 25)
        let hierarchy = try XCTUnwrap(PageHierarchy(plistRepresentation: [
            "id": expectedID.stringRepresentation,
            "pageID": expectedPageID.stringRepresentation,
            "frame": NSStringFromRect(expectedFrame),
            "children": [],
        ]))

        XCTAssertEqual(hierarchy.id, expectedID)
        XCTAssertEqual(hierarchy.pageID, expectedPageID)
        XCTAssertEqual(hierarchy.frame, expectedFrame)
    }

    func test_initPlistRepresentation_convertsChildrenToPageHierarchies() throws {
        let expectedID = CanvasPage.modelID(with: UUID())
        let expectedPageID = Page.modelID(with: UUID())
        let expectedFrame = CGRect(x: 10, y: 15, width: 20, height: 25)
        let hierarchy = try XCTUnwrap(PageHierarchy(plistRepresentation: [
            "id": CanvasPage.modelID(with: UUID()).stringRepresentation,
            "pageID": Page.modelID(with: UUID()).stringRepresentation,
            "frame": NSStringFromRect(.zero),
            "children": [
                [
                    "id": expectedID.stringRepresentation,
                    "pageID": expectedPageID.stringRepresentation,
                    "frame": NSStringFromRect(expectedFrame),
                    "children": []
                ]
            ],
        ]))

        let child = try XCTUnwrap(hierarchy.children[safe: 0])
        XCTAssertEqual(child.id, expectedID)
        XCTAssertEqual(child.pageID, expectedPageID)
        XCTAssertEqual(child.frame, expectedFrame)
    }


    //MARK: - .plistRepresentation
    func test_plistRepresentation_addsIDStringRepresentation() throws {
        let hierarchy = try XCTUnwrap(PageHierarchy(canvasPage: self.parentPage))
        XCTAssertEqual(hierarchy.plistRepresentation["id"] as? String, self.parentPage.id.stringRepresentation)
    }

    func test_plistRepresentation_addsPageIDStringRepresentation() throws {
        let hierarchy = try XCTUnwrap(PageHierarchy(canvasPage: self.parentPage))
        XCTAssertEqual(hierarchy.plistRepresentation["pageID"] as? String, self.parentPage.page!.id.stringRepresentation)
    }

    func test_plistRepresentation_addsFrameStringRepresentation() throws {
        let hierarchy = try XCTUnwrap(PageHierarchy(canvasPage: self.parentPage))
        XCTAssertEqual(hierarchy.plistRepresentation["frame"] as? String, NSStringFromRect(self.parentPage.frame))
    }

    func test_plistRepresentation_convertsChildrenToPlistAndAddsThem() throws {
        let hierarchy = try XCTUnwrap(PageHierarchy(canvasPage: self.parentPage))
        let children = try XCTUnwrap(hierarchy.plistRepresentation["children"] as? [[String: Any]])
        XCTAssertEqual(children.count, 2)

        XCTAssertTrue(children.contains(where: {
            (($0["id"] as? String) == self.childPage1.id.stringRepresentation) &&
                (($0["pageID"] as? String) == self.childPage1.page!.id.stringRepresentation) &&
                (($0["frame"] as? String) == NSStringFromRect(self.childPage1.frame))
        }))
        XCTAssertTrue(children.contains(where: {
            (($0["id"] as? String) == self.childPage2.id.stringRepresentation) &&
                (($0["pageID"] as? String) == self.childPage2.page!.id.stringRepresentation) &&
                (($0["frame"] as? String) == NSStringFromRect(self.childPage2.frame))
        }))
    }

}
