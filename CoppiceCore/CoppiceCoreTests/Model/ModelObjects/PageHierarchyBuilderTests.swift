//
//  PageHierarchyBuilderTests.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 08/10/2022.
//

import XCTest

@testable import CoppiceCore

final class PageHierarchyBuilderTests: XCTestCase {
    var modelController: CoppiceModelController!

    var linkInPage1: CanvasPage!
    var linkInPage2: CanvasPage!
    var rootPage: CanvasPage!
    var childPage1: CanvasPage!
    var childPage2: CanvasPage!
    var grandChildPage: CanvasPage!

    var linkIn1: CanvasLink!
    var linkIn2: CanvasLink!
    var child1Link: CanvasLink!
    var child2Link: CanvasLink!
    var grandChildLink: CanvasLink!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let modelController = CoppiceModelController(undoManager: UndoManager())
        self.modelController = modelController
        let canvas = Canvas.create(in: modelController)

        self.linkInPage1 = CanvasPage.create(in: modelController) {
            $0.canvas = canvas
            $0.frame = CGRect(x: -20, y: 20, width: 10, height: 10)
        }

        self.linkInPage2 = CanvasPage.create(in: modelController) {
            $0.canvas = canvas
            $0.frame = CGRect(x: -30, y: -40, width: 10, height: 10)
        }

        let root = Page.create(in: modelController)
        let child1 = Page.create(in: modelController)
        let child2 = Page.create(in: modelController)
        let grandChild = Page.create(in: modelController)

        self.rootPage = CanvasPage.create(in: modelController) {
            $0.canvas = canvas
            $0.page = root
            $0.frame = CGRect(x: 10, y: 5, width: 10, height: 10)
        }

        self.childPage1 = CanvasPage.create(in: modelController) {
            $0.canvas = canvas
            $0.page = child1
            $0.frame = CGRect(x: 30, y: 40, width: 50, height: 60)
        }
        self.childPage2 = CanvasPage.create(in: modelController) {
            $0.canvas = canvas
            $0.page = child2
            $0.frame = CGRect(x: 20, y: -20, width: 10, height: 10)
        }
        self.grandChildPage = CanvasPage.create(in: modelController) {
            $0.canvas = canvas
            $0.page = grandChild
            $0.frame = CGRect(x: 100, y: 100, width: 42, height: 1337)
        }

        self.linkIn1 = CanvasLink.create(in: modelController) {
            $0.canvas = canvas
            $0.sourcePage = self.linkInPage1
            $0.destinationPage = self.rootPage
            $0.link = PageLink(destination: self.rootPage.id, source: self.linkInPage1.id)
        }

        self.linkIn2 = CanvasLink.create(in: modelController) {
            $0.canvas = canvas
            $0.sourcePage = self.linkInPage2
            $0.destinationPage = self.rootPage
            $0.link = PageLink(destination: self.rootPage.id, source: self.linkInPage2.id)
        }

        self.child1Link = CanvasLink.create(in: modelController) {
            $0.canvas = canvas
            $0.sourcePage = self.rootPage
            $0.destinationPage = self.childPage1
            $0.link = PageLink(destination: self.childPage1.id, source: self.rootPage.id)
        }

        self.child2Link = CanvasLink.create(in: modelController) {
            $0.canvas = canvas
            $0.sourcePage = self.rootPage
            $0.destinationPage = self.childPage2
            $0.link = PageLink(destination: self.childPage2.id, source: self.rootPage.id)
        }

        self.grandChildLink = CanvasLink.create(in: modelController) {
            $0.canvas = canvas
            $0.sourcePage = self.childPage1
            $0.destinationPage = self.grandChildPage
            $0.link = PageLink(destination: self.grandChildPage.id, source: self.childPage1.id)
        }
    }

    //MARK: - buildHierarchy(in:)
    func test_buildHierarchy_createsNewHierarchyObject() throws {
        let builder = PageHierarchyBuilder(rootPage: self.rootPage)
        let hierarchy = builder.buildHierarchy(in: self.modelController)

        XCTAssertTrue(self.modelController.pageHierarchyCollection.all.contains(hierarchy))
    }

    func test_buildHierarchy_addsIDOfRootPageSetInInit() throws {
        let builder = PageHierarchyBuilder(rootPage: self.rootPage)
        let hierarchy = builder.buildHierarchy(in: self.modelController)

        XCTAssertEqual(hierarchy.rootPageID, self.rootPage.id)
    }

    func test_buildHierarchy_addsEntryPointWithCorrectOffsets() throws {
        let builder = PageHierarchyBuilder(rootPage: self.rootPage)
        let hierarchy = builder.buildHierarchy(in: self.modelController)

        XCTAssertEqual(hierarchy.entryPoints.count, 2)
        let entryPoint1 = try XCTUnwrap(hierarchy.entryPoints.first(where: { $0.pageLink == self.linkIn1.link }))
        let entryPoint2 = try XCTUnwrap(hierarchy.entryPoints.first(where: { $0.pageLink == self.linkIn2.link }))

        XCTAssertEqual(entryPoint1.relativePosition, CGPoint(x: 30, y: -15))
        XCTAssertEqual(entryPoint2.relativePosition, CGPoint(x: 40, y: 45))
    }

    func test_buildHiearchy_addsPagesWithCorrectOffsets() throws {
        let builder = PageHierarchyBuilder(rootPage: self.rootPage)
        builder.add(self.rootPage)
        builder.add(self.childPage1)
        builder.add(self.childPage2)
        builder.add(self.grandChildPage)

        let hierarchy = builder.buildHierarchy(in: self.modelController)

        XCTAssertEqual(hierarchy.pages.count, 4)
        let rootPage = try XCTUnwrap(hierarchy.pages.first(where: { $0.canvasPageID == self.rootPage.id }))
        let child1 = try XCTUnwrap(hierarchy.pages.first(where: { $0.canvasPageID == self.childPage1.id }))
        let child2 = try XCTUnwrap(hierarchy.pages.first(where: { $0.canvasPageID == self.childPage2.id }))
        let grandChild = try XCTUnwrap(hierarchy.pages.first(where: { $0.canvasPageID == self.grandChildPage.id }))

        XCTAssertEqual(rootPage.pageID, self.rootPage.page!.id)
        XCTAssertEqual(child1.pageID, self.childPage1.page!.id)
        XCTAssertEqual(child2.pageID, self.childPage2.page!.id)
        XCTAssertEqual(grandChild.pageID, self.grandChildPage.page!.id)

        XCTAssertEqual(rootPage.relativeContentFrame, CGRect(x: 0, y: 0, width: 10, height: 10))
        XCTAssertEqual(child1.relativeContentFrame, CGRect(x: 20, y: 35, width: 50, height: 60))
        XCTAssertEqual(child2.relativeContentFrame, CGRect(x: 10, y: -25, width: 10, height: 10))
        XCTAssertEqual(grandChild.relativeContentFrame, CGRect(x: 90, y: 95, width: 42, height: 1337))
    }

    func test_buildHierarchy_addsLinksWithCorrectIDs() throws {
        let builder = PageHierarchyBuilder(rootPage: self.rootPage)
        builder.add(self.rootPage)
        builder.add(self.childPage1)
        builder.add(self.childPage2)
        builder.add(self.grandChildPage)

        let hierarchy = builder.buildHierarchy(in: self.modelController)

        let link1 = try XCTUnwrap(hierarchy.links.first(where: { $0.link == self.child1Link.link }))
        let link2 = try XCTUnwrap(hierarchy.links.first(where: { $0.link == self.child2Link.link }))
        let link3 = try XCTUnwrap(hierarchy.links.first(where: { $0.link == self.grandChildLink.link }))

        XCTAssertEqual(link1.sourceID, self.rootPage.id)
        XCTAssertEqual(link2.sourceID, self.rootPage.id)
        XCTAssertEqual(link3.sourceID, self.childPage1.id)

        XCTAssertEqual(link1.destinationID, self.childPage1.id)
        XCTAssertEqual(link2.destinationID, self.childPage2.id)
        XCTAssertEqual(link3.destinationID, self.grandChildPage.id)
    }
}
