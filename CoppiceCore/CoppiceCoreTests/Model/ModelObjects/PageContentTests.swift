//
//  PageContentTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 09/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

class PageContentTests: XCTestCase {
    func test_pageContentType_contentTypeForUTIReturnsTextForPlainTextUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: kUTTypePlainText as String), .text)
    }

    func test_pageContentType_contentTypeForUTIReturnsTextForRTFUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: kUTTypeRTF as String), .text)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForGIFUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: kUTTypeGIF as String), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForPNGUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: kUTTypePNG as String), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForJPEGUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: kUTTypeJPEG as String), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForTIFFUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: kUTTypeTIFF as String), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForBMPUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: kUTTypeBMP as String), .image)
    }
}
