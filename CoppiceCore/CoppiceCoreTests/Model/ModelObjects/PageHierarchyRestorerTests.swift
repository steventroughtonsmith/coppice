//
//  PageHierarchyRestorerTests.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 08/10/2022.
//

import XCTest
@testable import CoppiceCore
import M3Data

final class PageHierarchyRestorerTests: XCTestCase {

    var modelController: CoppiceModelController!
    var canvas: Canvas!

    var linkInPage1: CanvasPage!
    var linkInPage2: CanvasPage!

    var page1: Page!
    var page2: Page!
    var page3: Page!
    var page4: Page!

    var canvasPage1ID: ModelID!
    var canvasPage2ID: ModelID!
    var canvasPage3ID: ModelID!
    var canvasPage4ID: ModelID!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let modelController = CoppiceModelController(undoManager: UndoManager())
        self.modelController = modelController
        self.canvas = Canvas.create(in: modelController)

        self.linkInPage1 = CanvasPage.create(in: modelController) {
            $0.canvas = self.canvas
            $0.frame = CGRect(x: -20, y: 20, width: 10, height: 10)
        }

        self.linkInPage2 = CanvasPage.create(in: modelController) {
            $0.canvas = self.canvas
            $0.frame = CGRect(x: -30, y: -40, width: 10, height: 10)
        }

        self.page1 = Page.create(in: modelController)
        self.page2 = Page.create(in: modelController)
        self.page3 = Page.create(in: modelController)
        self.page4 = Page.create(in: modelController)

        self.canvasPage1ID = ModelID(modelType: CanvasPage.modelType)
        self.canvasPage2ID = ModelID(modelType: CanvasPage.modelType)
        self.canvasPage3ID = ModelID(modelType: CanvasPage.modelType)
        self.canvasPage4ID = ModelID(modelType: CanvasPage.modelType)
    }

    //MARK: - restore(_:from:for:)
    func test_restorePageHierarchy_returnsEmptyArrayIfHierarchyDoesntContainEntryPointForLink() throws {
        let hierarchy = self.createHierarchy()

        let restorer = PageHierarchyRestorer(canvas: self.canvas)
        let restoredPages = restorer.restore(hierarchy, from: self.linkInPage1, for: PageLink(destination: ModelID(modelType: CanvasPage.modelType), source: ModelID(modelType: CanvasPage.modelType)))

        XCTAssertEqual(restoredPages.count, 0)
        XCTAssertEqual(self.modelController.canvasPageCollection.all.count, 2)
    }

    func test_restorePageHierarchy_createsCanvasPagesForEachPageInHierarchyWithCorrectIDs() throws {
        let hierarchy = self.createHierarchy()

        let restorer = PageHierarchyRestorer(canvas: self.canvas)
        let restoredPages = restorer.restore(hierarchy, from: self.linkInPage1, for: PageLink(destination: self.canvasPage1ID, source: self.linkInPage1.id))

        XCTAssertEqual(restoredPages.count, 4)
        XCTAssertEqual(self.modelController.canvasPageCollection.all.count, 6)

        let canvasPage1 = try XCTUnwrap(restoredPages.first(where: { $0.id == self.canvasPage1ID }))
        XCTAssertEqual(canvasPage1.page, self.page1)
        let canvasPage2 = try XCTUnwrap(restoredPages.first(where: { $0.id == self.canvasPage2ID }))
        XCTAssertEqual(canvasPage2.page, self.page2)
        let canvasPage3 = try XCTUnwrap(restoredPages.first(where: { $0.id == self.canvasPage3ID }))
        XCTAssertEqual(canvasPage3.page, self.page3)
        let canvasPage4 = try XCTUnwrap(restoredPages.first(where: { $0.id == self.canvasPage4ID }))
        XCTAssertEqual(canvasPage4.page, self.page4)
    }

    func test_restorePageHierarchy_setsCorrectFrameForEachPageInHierarchy() throws {
        let hierarchy = self.createHierarchy()

        let restorer = PageHierarchyRestorer(canvas: self.canvas)
        let restoredPages = restorer.restore(hierarchy, from: self.linkInPage1, for: PageLink(destination: self.canvasPage1ID, source: self.linkInPage1.id))

        XCTAssertEqual(restoredPages.count, 4)
        XCTAssertEqual(self.modelController.canvasPageCollection.all.count, 6)

        let canvasPage1 = try XCTUnwrap(restoredPages.first(where: { $0.id == self.canvasPage1ID }))
        XCTAssertEqual(canvasPage1.frame, CGRect(x: 10, y: 5, width: 10, height: 10))
        let canvasPage2 = try XCTUnwrap(restoredPages.first(where: { $0.id == self.canvasPage2ID }))
        XCTAssertEqual(canvasPage2.frame, CGRect(x: 30, y: 40, width: 50, height: 60))
        let canvasPage3 = try XCTUnwrap(restoredPages.first(where: { $0.id == self.canvasPage3ID }))
        XCTAssertEqual(canvasPage3.frame, CGRect(x: 20, y: -20, width: 10, height: 10))
        let canvasPage4 = try XCTUnwrap(restoredPages.first(where: { $0.id == self.canvasPage4ID }))
        XCTAssertEqual(canvasPage4.frame, CGRect(x: 100, y: 100, width: 42, height: 1337))
    }

    func test_restorePageHierarchy_createsLinkFromSourceToRootOfHierarchy() throws {
        let hierarchy = self.createHierarchy()

        let restorer = PageHierarchyRestorer(canvas: self.canvas)
        _ = restorer.restore(hierarchy, from: self.linkInPage1, for: PageLink(destination: self.canvasPage1ID, source: self.linkInPage1.id))

        let link = try XCTUnwrap(self.modelController.canvasLinkCollection.all.first(where: { $0.link == PageLink(destination: self.canvasPage1ID, source: self.linkInPage1.id) }))

        XCTAssertEqual(link.sourcePage, self.linkInPage1)
        XCTAssertEqual(link.destinationPage?.id, self.canvasPage1ID)
    }

    func test_restorePageHierarchy_createsCanvasLinkForEachLinkInHierarchy() throws {
        let hierarchy = self.createHierarchy()

        let restorer = PageHierarchyRestorer(canvas: self.canvas)
        _ = restorer.restore(hierarchy, from: self.linkInPage1, for: PageLink(destination: self.canvasPage1ID, source: self.linkInPage1.id))

        let link1 = try XCTUnwrap(self.modelController.canvasLinkCollection.all.first(where: { $0.link == PageLink(destination: self.canvasPage2ID, source: self.canvasPage1ID) }))
        let link2 = try XCTUnwrap(self.modelController.canvasLinkCollection.all.first(where: { $0.link == PageLink(destination: self.canvasPage3ID, source: self.canvasPage1ID) }))
        let link3 = try XCTUnwrap(self.modelController.canvasLinkCollection.all.first(where: { $0.link == PageLink(destination: self.canvasPage4ID, source: self.canvasPage2ID) }))

        XCTAssertEqual(link1.sourcePage?.id, self.canvasPage1ID)
        XCTAssertEqual(link1.destinationPage?.id, self.canvasPage2ID)

        XCTAssertEqual(link2.sourcePage?.id, self.canvasPage1ID)
        XCTAssertEqual(link2.destinationPage?.id, self.canvasPage3ID)

        XCTAssertEqual(link3.sourcePage?.id, self.canvasPage2ID)
        XCTAssertEqual(link3.destinationPage?.id, self.canvasPage4ID)
    }

    func test_restorePageHierarchy_doesntCreateCanvasLinkIfOneOfLinkedPagesDoesNotExist() throws {
        let hierarchy = self.createHierarchy()
        let modelID = ModelID(modelType: CanvasPage.modelType)
        hierarchy.links.append(.init(sourceID: self.canvasPage3ID, destinationID: modelID, link: PageLink(destination: modelID, source: self.canvasPage3ID)))

        let restorer = PageHierarchyRestorer(canvas: self.canvas)
        _ = restorer.restore(hierarchy, from: self.linkInPage1, for: PageLink(destination: self.canvasPage1ID, source: self.linkInPage1.id))

        XCTAssertNil(self.modelController.canvasLinkCollection.all.first(where: { $0.link == PageLink(destination: modelID, source: self.canvasPage3ID) }))
    }

    private func createHierarchy() -> PageHierarchy {
        let hierarchy = PageHierarchy.create(in: self.modelController)
        hierarchy.entryPoints = [
            .init(pageLink: PageLink(destination: self.canvasPage1ID, source: self.linkInPage1.id), relativePosition: CGPoint(x: 30, y: -15)),
            .init(pageLink: PageLink(destination: self.canvasPage1ID, source: self.linkInPage1.id), relativePosition: CGPoint(x: 40, y: 45))
        ]

        hierarchy.pages = [
            .init(canvasPageID: self.canvasPage1ID, pageID: self.page1.id, relativeContentFrame: CGRect(x: 0, y: 0, width: 10, height: 10)),
            .init(canvasPageID: self.canvasPage2ID, pageID: self.page2.id, relativeContentFrame: CGRect(x: 20, y: 35, width: 50, height: 60)),
            .init(canvasPageID: self.canvasPage3ID, pageID: self.page3.id, relativeContentFrame: CGRect(x: 10, y: -25, width: 10, height: 10)),
            .init(canvasPageID: self.canvasPage4ID, pageID: self.page4.id, relativeContentFrame: CGRect(x: 90, y: 95, width: 42, height: 1337))
        ]

        hierarchy.links = [
            .init(sourceID: self.canvasPage1ID, destinationID: self.canvasPage2ID, link: PageLink(destination: self.canvasPage2ID, source: self.canvasPage1ID)),
            .init(sourceID: self.canvasPage1ID, destinationID: self.canvasPage3ID, link: PageLink(destination: self.canvasPage3ID, source: self.canvasPage1ID)),
            .init(sourceID: self.canvasPage2ID, destinationID: self.canvasPage4ID, link: PageLink(destination: self.canvasPage4ID, source: self.canvasPage2ID)),
        ]

        hierarchy.rootPageID = self.canvasPage1ID

        return hierarchy
    }
}
