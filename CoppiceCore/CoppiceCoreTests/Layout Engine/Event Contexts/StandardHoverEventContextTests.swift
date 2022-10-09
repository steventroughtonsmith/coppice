//
//  StandardHoverEventContextTests.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 08/10/2022.
//

import XCTest

final class StandardHoverEventContextTests: XCTestCase {
    func test_cursorMoved_setsPageUnderMouseToNilIfNothingUnderMouse() throws {
        XCTFail()
    }

    func test_cursorMoved_setsPageUnderMouseToNilIfLinkUnderMouse() throws {
        XCTFail()
    }

    func test_cursorMoved_setsPageUnderMouseIfOverPage() throws {
        XCTFail()
    }

    func test_cursorMoved_doesntHighlightAnyPageLinksIfOverNothing() throws {
        XCTFail()
    }

    func test_cursorMoved_doesntHighlightAnyPageLinksIfOverPage() throws {
        XCTFail()
    }

    func test_cursorMoved_highlightsPageLinksIfOverLinkOnPage() throws {
        XCTFail()
    }

    func test_cursorMoved_tellsPageToHighlightLinksIfOverPageLink() throws {
        XCTFail()
    }

    func test_cursorMoved_tellsPreviouslyHighlightedPageToUnhighlightIfNoLongerOverLink() throws {
        XCTFail()
    }
}
