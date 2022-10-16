//
//  CreateLinkHoverEventContextTests.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 08/10/2022.
//

import XCTest

@testable import CoppiceCore

final class CreateLinkHoverEventContextTests: XCTestCase {
    var sourcePage: LayoutEnginePage!
    var layoutEngine: MockLayoutEngine!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.sourcePage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        self.layoutEngine = MockLayoutEngine()
    }


    //MARK: - cursorMoved(to:modifiers:in)
    func test_cursorMoved_createsAndUpdatesCursorPageLocation() throws {
        let context = CreateLinkHoverEventContext(page: self.sourcePage)

        XCTAssertNil(self.layoutEngine.cursorPage)
        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)

        let cursorPage = try XCTUnwrap(self.layoutEngine.cursorPage)
        XCTAssertEqual(cursorPage.contentFrame.origin, CGPoint(x: 15, y: 18))

        context.cursorMoved(to: CGPoint(x: 21, y: 42), modifiers: [], in: self.layoutEngine)
        XCTAssertEqual(cursorPage.contentFrame.origin, CGPoint(x: 21, y: 42))
    }

    func test_cursorMoved_addsLinkToCursorPageIfLinkDoesntExistAndPointNotOverPage() throws {
        let context = CreateLinkHoverEventContext(page: self.sourcePage)
        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)

        let cursorPage = try XCTUnwrap(self.layoutEngine.cursorPage)

        let addedLinks = try XCTUnwrap(self.layoutEngine.addLinksMock.arguments.first)
        XCTAssertEqual(addedLinks.count, 1)
        let cursorLink = try XCTUnwrap(addedLinks.first)
        XCTAssertEqual(cursorLink.sourcePageID, self.sourcePage.id)
        XCTAssertEqual(cursorLink.destinationPageID, cursorPage.id)
    }

    func test_cursorMoved_removesCursorLinkFromLayoutAndAddsLinkToPageIfPointOverPage() throws {
        let context = CreateLinkHoverEventContext(page: self.sourcePage)
        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)

        let destinationPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        self.layoutEngine.itemAtCanvasPointMock.returnValue = destinationPage

        context.cursorMoved(to: CGPoint(x: 16, y: 18), modifiers: [], in: self.layoutEngine)

        let cursorPage = try XCTUnwrap(self.layoutEngine.cursorPage)

        let removedLinks = try XCTUnwrap(self.layoutEngine.removeLinksMock.arguments.first)
        let cursorLink = try XCTUnwrap(removedLinks.first)
        XCTAssertEqual(cursorLink.sourcePageID, self.sourcePage.id)
        XCTAssertEqual(cursorLink.destinationPageID, cursorPage.id)

        XCTAssertEqual(self.layoutEngine.addLinksMock.arguments.count, 2)
        let addedLinks = try XCTUnwrap(self.layoutEngine.addLinksMock.arguments.last)
        XCTAssertEqual(addedLinks.count, 1)
        let pageLink = try XCTUnwrap(addedLinks.first)
        XCTAssertEqual(pageLink.sourcePageID, self.sourcePage.id)
        XCTAssertEqual(pageLink.destinationPageID, destinationPage.id)
    }

    func test_cursorMoved_showsMessageIfCursorOverPage() throws {
        let context = CreateLinkHoverEventContext(page: self.sourcePage)

        let destinationPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        self.layoutEngine.itemAtCanvasPointMock.returnValue = destinationPage

        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)

        XCTAssertEqual(destinationPage.message?.message, "Link to Page")
    }

    func test_cursorMoved_removesLinkToPageAndAddsCursorLinkIfPointNoLongerOverPage() throws {
        let context = CreateLinkHoverEventContext(page: self.sourcePage)
        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)

        let destinationPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        self.layoutEngine.itemAtCanvasPointMock.returnValue = destinationPage

        context.cursorMoved(to: CGPoint(x: 16, y: 18), modifiers: [], in: self.layoutEngine)

        self.layoutEngine.itemAtCanvasPointMock.returnValue = nil
        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)

        let cursorPage = try XCTUnwrap(self.layoutEngine.cursorPage)

        XCTAssertEqual(self.layoutEngine.removeLinksMock.arguments.count, 2)
        let removedLinks = try XCTUnwrap(self.layoutEngine.removeLinksMock.arguments.last)
        let pageLink = try XCTUnwrap(removedLinks.first)
        XCTAssertEqual(pageLink.sourcePageID, self.sourcePage.id)
        XCTAssertEqual(pageLink.destinationPageID, destinationPage.id)

        XCTAssertEqual(self.layoutEngine.addLinksMock.arguments.count, 3)
        let addedLinks = try XCTUnwrap(self.layoutEngine.addLinksMock.arguments.last)
        XCTAssertEqual(addedLinks.count, 1)
        let cursorLink = try XCTUnwrap(addedLinks.first)
        XCTAssertEqual(cursorLink.sourcePageID, self.sourcePage.id)
        XCTAssertEqual(cursorLink.destinationPageID, cursorPage.id)
    }

    func test_cursorMoved_tellsLayoutCursorAndTargetModifiedIfPointOverPage() throws {
        let context = CreateLinkHoverEventContext(page: self.sourcePage)
        let destinationPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        self.layoutEngine.itemAtCanvasPointMock.returnValue = destinationPage
        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)

        let cursorPage = try XCTUnwrap(self.layoutEngine.cursorPage)
        let modifiedPages = try XCTUnwrap(self.layoutEngine.modifiedItemsMock.arguments.first as? [LayoutEnginePage])
        XCTAssertEqual(modifiedPages.count, 2)
        XCTAssertTrue(modifiedPages.contains(cursorPage))
        XCTAssertTrue(modifiedPages.contains(destinationPage))
    }

    func test_cursorMoved_tellsLayoutOnlyCursorModifiedIfPointNotOverPage() throws {
        let context = CreateLinkHoverEventContext(page: self.sourcePage)
        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)

        let cursorPage = try XCTUnwrap(self.layoutEngine.cursorPage)
        let modifiedPages = try XCTUnwrap(self.layoutEngine.modifiedItemsMock.arguments.first as? [LayoutEnginePage])
        XCTAssertEqual(modifiedPages.count, 1)
        XCTAssertTrue(modifiedPages.contains(cursorPage))
    }

    //MARK: - cleanUp(in:)
    func test_cleanUp_removesPageLink() throws {
        let context = CreateLinkHoverEventContext(page: self.sourcePage)
        let destinationPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        self.layoutEngine.itemAtCanvasPointMock.returnValue = destinationPage
        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)

        let addedLink = try XCTUnwrap(self.layoutEngine.addLinksMock.arguments.first?.first)
        let engine = LinkLayoutEngine()
        addedLink.linkLayoutEngine = engine

        context.cleanUp(in: self.layoutEngine)

        let removedLinks = try XCTUnwrap(self.layoutEngine.removeLinksMock.arguments.last)
        let pageLink = try XCTUnwrap(removedLinks.first)
        XCTAssertEqual(pageLink.sourcePageID, self.sourcePage.id)
        XCTAssertEqual(pageLink.destinationPageID, destinationPage.id)
    }

    func test_cleanUp_removesCursorLink() throws {
        let context = CreateLinkHoverEventContext(page: self.sourcePage)
        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)

        let addedLink = try XCTUnwrap(self.layoutEngine.addLinksMock.arguments.first?.first)
        let engine = LinkLayoutEngine()
        addedLink.linkLayoutEngine = engine

        let cursorPage = try XCTUnwrap(self.layoutEngine.cursorPage)
        context.cleanUp(in: self.layoutEngine)

        let removedLinks = try XCTUnwrap(self.layoutEngine.removeLinksMock.arguments.first)
        let cursorLink = try XCTUnwrap(removedLinks.first)
        XCTAssertEqual(cursorLink.sourcePageID, self.sourcePage.id)
        XCTAssertEqual(cursorLink.destinationPageID, cursorPage.id)
    }

    func test_cleanUp_clearsMessage() throws {
        let context = CreateLinkHoverEventContext(page: self.sourcePage)
        let destinationPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        self.layoutEngine.itemAtCanvasPointMock.returnValue = destinationPage
        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)
        destinationPage.message = .init(message: "Hello World", color: .blue)

        context.cleanUp(in: self.layoutEngine)
        XCTAssertNil(destinationPage.message)
    }

    func test_cleanUp_clearsCursorPage() throws {
        let context = CreateLinkHoverEventContext(page: self.sourcePage)
        let destinationPage = LayoutEnginePage(id: UUID(), contentFrame: .zero)
        self.layoutEngine.itemAtCanvasPointMock.returnValue = destinationPage
        context.cursorMoved(to: CGPoint(x: 15, y: 18), modifiers: [], in: self.layoutEngine)

        XCTAssertNotNil(self.layoutEngine.cursorPage)

        context.cleanUp(in: self.layoutEngine)

        XCTAssertNil(self.layoutEngine.cursorPage)
    }
}
