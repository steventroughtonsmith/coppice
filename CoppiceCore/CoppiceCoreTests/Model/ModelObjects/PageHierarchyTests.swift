//
//  PageHierarchyTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 14/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import M3Data
import XCTest

class PageHierarchyTests: XCTestCase {
    //MARK: - init(plistRepresentation:)
    func test_initPlistRepresentation_returnsNilIfIDNotInPlist() {
        XCTAssertNil(LegacyPageHierarchy(plistRepresentation: [
            "pageID": Page.modelID(with: UUID()).stringRepresentation,
            "frame": NSStringFromRect(.zero),
            "children": [[String: Any]](),
        ]))
    }

    func test_initPlistRepresentation_returnsNilIfPageIDNotInPlist() {
        XCTAssertNil(LegacyPageHierarchy(plistRepresentation: [
            "id": CanvasPage.modelID(with: UUID()).stringRepresentation,
            "frame": NSStringFromRect(.zero),
            "children": [[String: Any]](),
        ]))
    }

    func test_initPlistRepresentation_returnsNilIfFrameNotInPlist() {
        XCTAssertNil(LegacyPageHierarchy(plistRepresentation: [
            "id": CanvasPage.modelID(with: UUID()).stringRepresentation,
            "pageID": Page.modelID(with: UUID()).stringRepresentation,
            "children": [[String: Any]](),
        ]))
    }

    func test_initPlistRepresentation_returnsNilIfChildrenNotInPlist() {
        XCTAssertNil(LegacyPageHierarchy(plistRepresentation: [
            "id": CanvasPage.modelID(with: UUID()).stringRepresentation,
            "pageID": Page.modelID(with: UUID()).stringRepresentation,
            "frame": NSStringFromRect(.zero),
        ]))
    }

    func test_initPlistRepresentation_setsID_PageIDAndFrame() throws {
        let expectedID = CanvasPage.modelID(with: UUID())
        let expectedPageID = Page.modelID(with: UUID())
        let expectedFrame = CGRect(x: 10, y: 15, width: 20, height: 25)
        let hierarchy = try XCTUnwrap(LegacyPageHierarchy(plistRepresentation: [
            "id": expectedID.stringRepresentation,
            "pageID": expectedPageID.stringRepresentation,
            "frame": NSStringFromRect(expectedFrame),
            "children": [[String: Any]](),
        ]))

        XCTAssertEqual(hierarchy.id, expectedID)
        XCTAssertEqual(hierarchy.pageID, expectedPageID)
        XCTAssertEqual(hierarchy.frame, expectedFrame)
    }

    func test_initPlistRepresentation_convertsChildrenToPageHierarchies() throws {
        let expectedID = CanvasPage.modelID(with: UUID())
        let expectedPageID = Page.modelID(with: UUID())
        let expectedFrame = CGRect(x: 10, y: 15, width: 20, height: 25)
        let hierarchy = try XCTUnwrap(LegacyPageHierarchy(plistRepresentation: [
            "id": CanvasPage.modelID(with: UUID()).stringRepresentation,
            "pageID": Page.modelID(with: UUID()).stringRepresentation,
            "frame": NSStringFromRect(.zero),
            "children": [
                [
                    "id": expectedID.stringRepresentation,
                    "pageID": expectedPageID.stringRepresentation,
                    "frame": NSStringFromRect(expectedFrame),
                    "children": [[String: Any]](),
                ] as [String: Any],
            ],
        ]))

        let child = try XCTUnwrap(hierarchy.children[safe: 0])
        XCTAssertEqual(child.id, expectedID)
        XCTAssertEqual(child.pageID, expectedPageID)
        XCTAssertEqual(child.frame, expectedFrame)
    }

    //MARK: - pageHierarchyPlistRepresentation(withSourceCanvasPageID:andFrame:)
    func test_pageHierarchyPlistRepresentation_rootPageIDIsIDOfTopOfLegacyHierarchy() throws {
        let hierarchy = self.createLegacyHierarchy()

        let sourceID = ModelID(modelType: CanvasPage.modelType)
        let sourcePageID = ModelID(modelType: Page.modelType)
        let plist = hierarchy.pageHierarchyPersistenceRepresentation(withSourceCanvasPageID: sourceID, sourcePageID: sourcePageID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        XCTAssertEqual(plist[PageHierarchy.PlistKeys.rootPageID] as? String, hierarchy.id.stringRepresentation)
    }

    func test_pageHierarchyPlistRepresentation_hasSingleEntryPointFromSuppliedSourceToTopOfLegacyHierarchy() throws {
        let hierarchy = self.createLegacyHierarchy()

        let sourceID = ModelID(modelType: CanvasPage.modelType)
        let sourcePageID = ModelID(modelType: Page.modelType)
        let plist = hierarchy.pageHierarchyPersistenceRepresentation(withSourceCanvasPageID: sourceID, sourcePageID: sourcePageID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        let entryPoints = try XCTUnwrap(plist[PageHierarchy.PlistKeys.entryPoints] as? [[String: Any]])
        XCTAssertEqual(entryPoints.count, 1)
        XCTAssertEqual(entryPoints.first?["pageLink"] as? String, PageLink(destination: hierarchy.pageID, source: sourceID).url.absoluteString)
    }

    func test_pageHierarchyPlistRepresentation_entryPointHasRelativePositionBetweenLegacyRootFrameAndSourceFrame() throws {
        let hierarchy = self.createLegacyHierarchy()

        let sourceID = ModelID(modelType: CanvasPage.modelType)
        let sourcePageID = ModelID(modelType: Page.modelType)
        let plist = hierarchy.pageHierarchyPersistenceRepresentation(withSourceCanvasPageID: sourceID, sourcePageID: sourcePageID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        let entryPoints = try XCTUnwrap(plist[PageHierarchy.PlistKeys.entryPoints] as? [[String: Any]])
        XCTAssertEqual(entryPoints.count, 1)
        XCTAssertEqual(entryPoints.first?["relativePosition"] as? String, NSStringFromPoint(CGPoint(x: 0, y: 160)))
    }

    func test_pageHierarchyPlistRepresentation_pageRefsContainsLegacyRootWithZeroFrame() throws {
        let hierarchy = self.createLegacyHierarchy()

        let sourceID = ModelID(modelType: CanvasPage.modelType)
        let sourcePageID = ModelID(modelType: Page.modelType)
        let plist = hierarchy.pageHierarchyPersistenceRepresentation(withSourceCanvasPageID: sourceID, sourcePageID: sourcePageID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        let pageRefs = try XCTUnwrap(plist[PageHierarchy.PlistKeys.pages] as? [[String: Any]])
        let rootPage = try XCTUnwrap(pageRefs.first(where: { ($0["canvasPageID"] as? String) == hierarchy.id.stringRepresentation }))
        XCTAssertEqual(rootPage["pageID"] as? String, hierarchy.pageID.stringRepresentation)
        XCTAssertEqual(rootPage["relativeContentFrame"] as? String, NSStringFromRect(CGRect(x: 0, y: 0, width: 40, height: 30)))
    }

    func test_pageHierarchyPlistRepresentation_pageRefsContainsAllChildHierarchyPagesWithRelativeFrames() throws {
        let hierarchy = self.createLegacyHierarchy()

        let sourceID = ModelID(modelType: CanvasPage.modelType)
        let sourcePageID = ModelID(modelType: Page.modelType)
        let plist = hierarchy.pageHierarchyPersistenceRepresentation(withSourceCanvasPageID: sourceID, sourcePageID: sourcePageID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        let pageRefs = try XCTUnwrap(plist[PageHierarchy.PlistKeys.pages] as? [[String: Any]])

        let child1 = try XCTUnwrap(pageRefs.first(where: { ($0["canvasPageID"] as? String) == hierarchy.children[0].id.stringRepresentation }))
        XCTAssertEqual(child1["pageID"] as? String, hierarchy.children[0].pageID.stringRepresentation)
        XCTAssertEqual(child1["relativeContentFrame"] as? String, NSStringFromRect(CGRect(x: 70, y: 40, width: 100, height: 150)))

        let child2 = try XCTUnwrap(pageRefs.first(where: { ($0["canvasPageID"] as? String) == hierarchy.children[1].id.stringRepresentation }))
        XCTAssertEqual(child2["pageID"] as? String, hierarchy.children[1].pageID.stringRepresentation)
        XCTAssertEqual(child2["relativeContentFrame"] as? String, NSStringFromRect(CGRect(x: -110, y: -160, width: 82, height: 65)))

        let grandchild1 = try XCTUnwrap(pageRefs.first(where: { ($0["canvasPageID"] as? String) == hierarchy.children[0].children[0].id.stringRepresentation }))
        XCTAssertEqual(grandchild1["pageID"] as? String, hierarchy.children[0].children[0].pageID.stringRepresentation)
        XCTAssertEqual(grandchild1["relativeContentFrame"] as? String, NSStringFromRect(CGRect(x: 92, y: 240, width: 510, height: 210)))

        let grandchild2 = try XCTUnwrap(pageRefs.first(where: { ($0["canvasPageID"] as? String) == hierarchy.children[0].children[1].id.stringRepresentation }))
        XCTAssertEqual(grandchild2["pageID"] as? String, hierarchy.children[0].children[1].pageID.stringRepresentation)
        XCTAssertEqual(grandchild2["relativeContentFrame"] as? String, NSStringFromRect(CGRect(x: 50, y: -170, width: 100, height: 150)))
    }

    func test_pageHierarchyPlistRepresentation_createLinksBetweenEachPageAndItsChildren() throws {
        let hierarchy = self.createLegacyHierarchy()

        let sourceID = ModelID(modelType: CanvasPage.modelType)
        let sourcePageID = ModelID(modelType: Page.modelType)
        let plist = hierarchy.pageHierarchyPersistenceRepresentation(withSourceCanvasPageID: sourceID, sourcePageID: sourcePageID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        let linkRefs = try XCTUnwrap(plist[PageHierarchy.PlistKeys.links] as? [[String: Any]])

        let rootID = hierarchy.id
        let child1ID = hierarchy.children[0].id
        let child2ID = hierarchy.children[1].id
        let grandchild1ID = hierarchy.children[0].children[0].id
        let grandchild2ID = hierarchy.children[0].children[1].id

        let link1 = try XCTUnwrap(linkRefs.first(where: { ($0["sourceID"] as? String) == rootID.stringRepresentation && ($0["destinationID"] as? String) == child1ID.stringRepresentation }))
        XCTAssertEqual(link1["link"] as? String, PageLink(destination: hierarchy.children[0].pageID, source: hierarchy.id).url.absoluteString)
        let link2 = try XCTUnwrap(linkRefs.first(where: { ($0["sourceID"] as? String) == rootID.stringRepresentation && ($0["destinationID"] as? String) == child2ID.stringRepresentation }))
        XCTAssertEqual(link2["link"] as? String, PageLink(destination: hierarchy.children[1].pageID, source: hierarchy.id).url.absoluteString)
        let link3 = try XCTUnwrap(linkRefs.first(where: { ($0["sourceID"] as? String) == child1ID.stringRepresentation && ($0["destinationID"] as? String) == grandchild1ID.stringRepresentation }))
        XCTAssertEqual(link3["link"] as? String, PageLink(destination: hierarchy.children[0].children[0].pageID, source: hierarchy.children[0].id).url.absoluteString)
        let link4 = try XCTUnwrap(linkRefs.first(where: { ($0["sourceID"] as? String) == child1ID.stringRepresentation && ($0["destinationID"] as? String) == grandchild2ID.stringRepresentation }))
        XCTAssertEqual(link4["link"] as? String, PageLink(destination: hierarchy.children[0].children[1].pageID, source: hierarchy.children[0].id).url.absoluteString)
    }

    //MARK: - Helpers
    func createLegacyHierarchy() -> LegacyPageHierarchy {
        let grandchild1 = LegacyPageHierarchy(id: ModelID(modelType: CanvasPage.modelType),
                                              pageID: ModelID(modelType: Page.modelType),
                                              frame: CGRect(x: 62, y: 250, width: 510, height: 210),
                                              children: [])

        let grandchild2 = LegacyPageHierarchy(id: ModelID(modelType: CanvasPage.modelType),
                                              pageID: ModelID(modelType: Page.modelType),
                                              frame: CGRect(x: 20, y: -160, width: 100, height: 150),
                                              children: [])

        let child1 = LegacyPageHierarchy(id: ModelID(modelType: CanvasPage.modelType),
                                         pageID: ModelID(modelType: Page.modelType),
                                         frame: CGRect(x: 40, y: 50, width: 100, height: 150),
                                         children: [grandchild1, grandchild2])

        let child2 = LegacyPageHierarchy(id: ModelID(modelType: CanvasPage.modelType),
                                         pageID: ModelID(modelType: Page.modelType),
                                         frame: CGRect(x: -140, y: -150, width: 82, height: 65),
                                         children: [])

        return LegacyPageHierarchy(id: ModelID(modelType: CanvasPage.modelType),
                                   pageID: ModelID(modelType: Page.modelType),
                                   frame: CGRect(x: -30, y: 10, width: 40, height: 30),
                                   children: [child1, child2])
    }

    /*
     Canvas
     .closePageHierarchies
     [CanvasPageID(1):
     [PageID(2):[
     id - CanvasPageID (3)
     pageID - PageID (4)
     frame - absolute rect (5)
     children - [Hierarchies] (6)


     PageHierarchy
     rootPageID (3)
     EntryPoints [PageLink (1, 3), RelativePosition (5 & pulled from code)]
     PageRefs    [CanvasPageID(3), PageID(4), relative frame(5 - (root page's 5))]
     LinkRefs    [SourceID (3), DestinationID (6.3), PageLink (6.3, 3)]
     */
}
