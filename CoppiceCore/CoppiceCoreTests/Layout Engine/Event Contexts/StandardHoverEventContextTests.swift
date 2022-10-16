//
//  StandardHoverEventContextTests.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 08/10/2022.
//

import XCTest

@testable import CoppiceCore

final class StandardHoverEventContextTests: XCTestCase {
    func test_cursorMoved_setsPageUnderMouseToNilIfNothingUnderMouse() throws {
        let layoutEngine = MockLayoutEngine()
        let context = StandardHoverEventContext()

        layoutEngine.itemAtCanvasPointMock.returnValue = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        context.cursorMoved(to: CGPoint(x: 20, y: 40), modifiers: [], in: layoutEngine)
        XCTAssertNotNil(layoutEngine.pageUnderMouse)

        layoutEngine.itemAtCanvasPointMock.returnValue = nil
        context.cursorMoved(to: CGPoint(x: 21, y: 41), modifiers: [], in: layoutEngine)
        XCTAssertNil(layoutEngine.pageUnderMouse)
    }

    func test_cursorMoved_setsPageUnderMouseToNilIfLinkUnderMouse() throws {
        let layoutEngine = MockLayoutEngine()
        let context = StandardHoverEventContext()

        layoutEngine.itemAtCanvasPointMock.returnValue = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        context.cursorMoved(to: CGPoint(x: 20, y: 40), modifiers: [], in: layoutEngine)
        XCTAssertNotNil(layoutEngine.pageUnderMouse)

        layoutEngine.itemAtCanvasPointMock.returnValue = LayoutEngineLink(id: UUID(), pageLink: nil, sourcePageID: UUID(), destinationPageID: UUID())
        context.cursorMoved(to: CGPoint(x: 21, y: 41), modifiers: [], in: layoutEngine)
        XCTAssertNil(layoutEngine.pageUnderMouse)
    }

    func test_cursorMoved_setsPageUnderMouseIfOverPage() throws {
        let layoutEngine = MockLayoutEngine()
        let context = StandardHoverEventContext()

        let expectedPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        layoutEngine.itemAtCanvasPointMock.returnValue = expectedPage
        context.cursorMoved(to: CGPoint(x: 20, y: 40), modifiers: [], in: layoutEngine)
        XCTAssertEqual(layoutEngine.pageUnderMouse, expectedPage)
    }

    func test_cursorMoved_doesntHighlightAnyPageLinksIfOverNothing() throws {
        let (layoutEngine, views) = self.createHighlightingMock()
        layoutEngine.itemAtCanvasPointMock.returnValue = nil

        let context = StandardHoverEventContext()
        context.cursorMoved(to: CGPoint(x: 20, y: 40), modifiers: [], in: layoutEngine)

        XCTAssertFalse(views[0].highlightLinksMock.wasCalled)
        XCTAssertFalse(views[1].highlightLinksMock.wasCalled)
        XCTAssertFalse(views[2].highlightLinksMock.wasCalled)

        for link in layoutEngine.links {
            XCTAssertFalse(link.highlighted)
        }
    }

    func test_cursorMoved_doesntHighlightAnyPageLinksIfOverPage() throws {
        let (layoutEngine, views) = self.createHighlightingMock()

        layoutEngine.itemAtCanvasPointMock.returnValue = layoutEngine.pages[0]
        views[0].linkAtContentPointMock.returnValue = nil


        let context = StandardHoverEventContext()
        context.cursorMoved(to: CGPoint(x: 20, y: 40), modifiers: [], in: layoutEngine)
        XCTAssertEqual(layoutEngine.pageUnderMouse, layoutEngine.pages[0])

        XCTAssertFalse(views[0].highlightLinksMock.wasCalled)
        XCTAssertFalse(views[1].highlightLinksMock.wasCalled)
        XCTAssertFalse(views[2].highlightLinksMock.wasCalled)

        for link in layoutEngine.links {
            XCTAssertFalse(link.highlighted)
        }
    }

    func test_cursorMoved_highlightsPageLinksIfOverLinkOnPage() throws {
        let (layoutEngine, views) = self.createHighlightingMock()

        layoutEngine.itemAtCanvasPointMock.returnValue = layoutEngine.pages[0]
        views[0].linkAtContentPointMock.returnValue = PageLink(destination: Page.modelID(with: layoutEngine.pages[2].id),
                                                               source: Page.modelID(with: layoutEngine.pages[0].id)).url

        let context = StandardHoverEventContext()
        context.cursorMoved(to: CGPoint(x: 20, y: 40), modifiers: [], in: layoutEngine)
        XCTAssertEqual(layoutEngine.pageUnderMouse, layoutEngine.pages[0])

        XCTAssertFalse(views[0].highlightLinksMock.wasCalled)
        XCTAssertFalse(views[1].highlightLinksMock.wasCalled)
        XCTAssertFalse(views[2].highlightLinksMock.wasCalled)

        XCTAssertFalse(layoutEngine.links[0].highlighted)
        XCTAssertTrue(layoutEngine.links[1].highlighted)
    }

    func test_cursorMoved_tellsPageToHighlightLinksIfOverPageLink() throws {
        let (layoutEngine, views) = self.createHighlightingMock()

        layoutEngine.itemAtCanvasPointMock.returnValue = layoutEngine.links[1]
        layoutEngine.pageWithIDMock.returnValue = layoutEngine.pages[0]

        let context = StandardHoverEventContext()
        context.cursorMoved(to: CGPoint(x: 20, y: 40), modifiers: [], in: layoutEngine)

        XCTAssertTrue(views[0].highlightLinksMock.wasCalled)
        XCTAssertFalse(views[1].highlightLinksMock.wasCalled)
        XCTAssertFalse(views[2].highlightLinksMock.wasCalled)
        let pageLink = try XCTUnwrap(views[0].highlightLinksMock.arguments.first)
        XCTAssertEqual(pageLink, PageLink(destination: Page.modelID(with: layoutEngine.pages[2].id), source: Page.modelID(with: layoutEngine.pages[0].id)))

        XCTAssertFalse(layoutEngine.links[0].highlighted)
        XCTAssertTrue(layoutEngine.links[1].highlighted)
    }

    func test_cursorMoved_tellsPreviouslyHighlightedPageToUnhighlightIfNoLongerOverLink() throws {
        let (layoutEngine, views) = self.createHighlightingMock()

        layoutEngine.itemAtCanvasPointMock.returnValue = layoutEngine.links[1]
        layoutEngine.pageWithIDMock.returnValue = layoutEngine.pages[0]

        let context = StandardHoverEventContext()
        context.cursorMoved(to: CGPoint(x: 20, y: 40), modifiers: [], in: layoutEngine)

        layoutEngine.itemAtCanvasPointMock.returnValue = nil
        context.cursorMoved(to: CGPoint(x: 21, y: 41), modifiers: [], in: layoutEngine)

        XCTAssertTrue(views[0].highlightLinksMock.wasCalled)
        XCTAssertFalse(views[1].highlightLinksMock.wasCalled)
        XCTAssertFalse(views[2].highlightLinksMock.wasCalled)

        XCTAssertTrue(views[0].unhighlightLinksMock.wasCalled)

        XCTAssertFalse(layoutEngine.links[0].highlighted)
        XCTAssertFalse(layoutEngine.links[1].highlighted)
    }


    private func createHighlightingMock() -> (MockLayoutEngine, [MockLayoutEnginePageView]) {
        let layoutEngine = MockLayoutEngine()

        let parentPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let parentView = MockLayoutEnginePageView()
        parentPage.view = parentView

        let childPage1 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let child1View = MockLayoutEnginePageView()
        childPage1.view = child1View

        let childPage2 = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        let child2View = MockLayoutEnginePageView()
        childPage2.view = child2View

        layoutEngine.pages = [parentPage, childPage1, childPage2]

        let child1Link = LayoutEngineLink(id: UUID(),
                                          pageLink: PageLink(destination: Page.modelID(with: childPage1.id), source: Page.modelID(with: parentPage.id)),
                                          sourcePageID: parentPage.id,
                                          destinationPageID: childPage1.id)
        let child2Link = LayoutEngineLink(id: UUID(),
                                          pageLink: PageLink(destination: Page.modelID(with: childPage2.id), source: Page.modelID(with: parentPage.id)),
                                          sourcePageID: parentPage.id,
                                          destinationPageID: childPage2.id)
        layoutEngine.links = [child1Link, child2Link]

        return (layoutEngine, [parentView, child1View, child2View])
    }
}
