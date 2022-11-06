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
            "children": [],
        ]))
    }

    func test_initPlistRepresentation_returnsNilIfPageIDNotInPlist() {
        XCTAssertNil(LegacyPageHierarchy(plistRepresentation: [
            "id": CanvasPage.modelID(with: UUID()).stringRepresentation,
            "frame": NSStringFromRect(.zero),
            "children": [],
        ]))
    }

    func test_initPlistRepresentation_returnsNilIfFrameNotInPlist() {
        XCTAssertNil(LegacyPageHierarchy(plistRepresentation: [
            "id": CanvasPage.modelID(with: UUID()).stringRepresentation,
            "pageID": Page.modelID(with: UUID()).stringRepresentation,
            "children": [],
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
        let hierarchy = try XCTUnwrap(LegacyPageHierarchy(plistRepresentation: [
            "id": CanvasPage.modelID(with: UUID()).stringRepresentation,
            "pageID": Page.modelID(with: UUID()).stringRepresentation,
            "frame": NSStringFromRect(.zero),
            "children": [
                [
                    "id": expectedID.stringRepresentation,
                    "pageID": expectedPageID.stringRepresentation,
                    "frame": NSStringFromRect(expectedFrame),
                    "children": [],
                ],
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
        let plist = hierarchy.pageHierarchyPlistRepresentation(withSourceCanvasPageID: sourceID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        XCTAssertEqual(plist[.PageHierarchy.rootPageID] as? ModelID, hierarchy.id)
    }

    func test_pageHierarchyPlistRepresentation_hasSingleEntryPointFromSuppliedSourceToTopOfLegacyHierarchy() throws {
        let hierarchy = self.createLegacyHierarchy()

        let sourceID = ModelID(modelType: CanvasPage.modelType)
        let plist = hierarchy.pageHierarchyPlistRepresentation(withSourceCanvasPageID: sourceID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        let entryPoints = try XCTUnwrap(plist[.PageHierarchy.entryPoints] as? [[ModelPlistKey: Any]])
        XCTAssertEqual(entryPoints.count, 1)
        XCTAssertEqual(entryPoints.first?[.PageHierarchy.EntryPoint.pageLink] as? URL, PageLink(destination: hierarchy.pageID).url)
    }

    func test_pageHierarchyPlistRepresentation_entryPointHasRelativePositionBetweenLegacyRootFrameAndSourceFrame() throws {
        let hierarchy = self.createLegacyHierarchy()

        let sourceID = ModelID(modelType: CanvasPage.modelType)
        let plist = hierarchy.pageHierarchyPlistRepresentation(withSourceCanvasPageID: sourceID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        let entryPoints = try XCTUnwrap(plist[.PageHierarchy.entryPoints] as? [[ModelPlistKey: Any]])
        XCTAssertEqual(entryPoints.count, 1)
        XCTAssertEqual(entryPoints.first?[.PageHierarchy.EntryPoint.relativePosition] as? CGPoint, CGPoint(x: 0, y: 160))
    }

    func test_pageHierarchyPlistRepresentation_pageRefsContainsLegacyRootWithZeroFrame() throws {
        let hierarchy = self.createLegacyHierarchy()

        let sourceID = ModelID(modelType: CanvasPage.modelType)
        let plist = hierarchy.pageHierarchyPlistRepresentation(withSourceCanvasPageID: sourceID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        let pageRefs = try XCTUnwrap(plist[.PageHierarchy.pages] as? [[ModelPlistKey: Any]])
        let rootPage = try XCTUnwrap(pageRefs.first(where: { ($0[.PageHierarchy.PageRef.canvasPageID] as? ModelID) == hierarchy.id }))
        XCTAssertEqual(rootPage[.PageHierarchy.PageRef.pageID] as? ModelID, hierarchy.pageID)
        XCTAssertEqual(rootPage[.PageHierarchy.PageRef.relativeContentFrame] as? CGRect, CGRect(x: 0, y: 0, width: 40, height: 30))
    }

    func test_pageHierarchyPlistRepresentation_pageRefsContainsAllChildHierarchyPagesWithRelativeFrames() throws {
        let hierarchy = self.createLegacyHierarchy()

        let sourceID = ModelID(modelType: CanvasPage.modelType)
        let plist = hierarchy.pageHierarchyPlistRepresentation(withSourceCanvasPageID: sourceID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        let pageRefs = try XCTUnwrap(plist[.PageHierarchy.pages] as? [[ModelPlistKey: Any]])

        let child1 = try XCTUnwrap(pageRefs.first(where: { ($0[.PageHierarchy.PageRef.canvasPageID] as? ModelID) == hierarchy.children[0].id }))
        XCTAssertEqual(child1[.PageHierarchy.PageRef.pageID] as? ModelID, hierarchy.children[0].pageID)
        XCTAssertEqual(child1[.PageHierarchy.PageRef.relativeContentFrame] as? CGRect, CGRect(x: 70, y: 40, width: 100, height: 150))

        let child2 = try XCTUnwrap(pageRefs.first(where: { ($0[.PageHierarchy.PageRef.canvasPageID] as? ModelID) == hierarchy.children[1].id }))
        XCTAssertEqual(child2[.PageHierarchy.PageRef.pageID] as? ModelID, hierarchy.children[1].pageID)
        XCTAssertEqual(child2[.PageHierarchy.PageRef.relativeContentFrame] as? CGRect, CGRect(x: -110, y: -160, width: 82, height: 65))

        let grandchild1 = try XCTUnwrap(pageRefs.first(where: { ($0[.PageHierarchy.PageRef.canvasPageID] as? ModelID) == hierarchy.children[0].children[0].id }))
        XCTAssertEqual(grandchild1[.PageHierarchy.PageRef.pageID] as? ModelID, hierarchy.children[0].children[0].pageID)
        XCTAssertEqual(grandchild1[.PageHierarchy.PageRef.relativeContentFrame] as? CGRect, CGRect(x: 92, y: 240, width: 510, height: 210))

        let grandchild2 = try XCTUnwrap(pageRefs.first(where: { ($0[.PageHierarchy.PageRef.canvasPageID] as? ModelID) == hierarchy.children[0].children[1].id }))
        XCTAssertEqual(grandchild2[.PageHierarchy.PageRef.pageID] as? ModelID, hierarchy.children[0].children[1].pageID)
        XCTAssertEqual(grandchild2[.PageHierarchy.PageRef.relativeContentFrame] as? CGRect, CGRect(x: 50, y: -170, width: 100, height: 150))
    }

    func test_pageHierarchyPlistRepresentation_createLinksBetweenEachPageAndItsChildren() throws {
        let hierarchy = self.createLegacyHierarchy()

        let sourceID = ModelID(modelType: CanvasPage.modelType)
        let plist = hierarchy.pageHierarchyPlistRepresentation(withSourceCanvasPageID: sourceID, andFrame: CGRect(x: -30, y: -150, width: 60, height: 100))
        let linkRefs = try XCTUnwrap(plist[.PageHierarchy.links] as? [[ModelPlistKey: Any]])

        let rootID = hierarchy.id
        let child1ID = hierarchy.children[0].id
        let child2ID = hierarchy.children[1].id
        let grandchild1ID = hierarchy.children[0].children[0].id
        let grandchild2ID = hierarchy.children[0].children[1].id

        let link1 = try XCTUnwrap(linkRefs.first(where: { ($0[.PageHierarchy.LinkRef.sourceID] as? ModelID) == rootID && ($0[.PageHierarchy.LinkRef.destinationID] as? ModelID) == child1ID }))
        XCTAssertEqual(link1[.PageHierarchy.LinkRef.link] as? URL, PageLink(destination: hierarchy.children[0].pageID, source: hierarchy.pageID).url)
        let link2 = try XCTUnwrap(linkRefs.first(where: { ($0[.PageHierarchy.LinkRef.sourceID] as? ModelID) == rootID && ($0[.PageHierarchy.LinkRef.destinationID] as? ModelID) == child2ID }))
        XCTAssertEqual(link2[.PageHierarchy.LinkRef.link] as? URL, PageLink(destination: hierarchy.children[1].pageID, source: hierarchy.pageID).url)
        let link3 = try XCTUnwrap(linkRefs.first(where: { ($0[.PageHierarchy.LinkRef.sourceID] as? ModelID) == child1ID && ($0[.PageHierarchy.LinkRef.destinationID] as? ModelID) == grandchild1ID }))
        XCTAssertEqual(link3[.PageHierarchy.LinkRef.link] as? URL, PageLink(destination: hierarchy.children[0].children[0].pageID, source: hierarchy.children[0].pageID).url)
        let link4 = try XCTUnwrap(linkRefs.first(where: { ($0[.PageHierarchy.LinkRef.sourceID] as? ModelID) == child1ID && ($0[.PageHierarchy.LinkRef.destinationID] as? ModelID) == grandchild2ID }))
        XCTAssertEqual(link4[.PageHierarchy.LinkRef.link] as? URL, PageLink(destination: hierarchy.children[0].children[1].pageID, source: hierarchy.children[0].pageID).url)
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
