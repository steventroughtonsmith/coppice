//
//  PageContentTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 09/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class PageContentTests: XCTestCase {

    func test_pageContentType_contentTypeForUTIReturnsTextForPlainTextUTI() {
        XCTAssertEqual(PageContentType.contentType(forUTI: kUTTypePlainText as String), .text)
    }

    func test_pageContentType_contentTypeForUTIReturnsTextForRTFUTI() {
        XCTAssertEqual(PageContentType.contentType(forUTI: kUTTypeRTF as String), .text)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForGIFUTI() {
        XCTAssertEqual(PageContentType.contentType(forUTI: kUTTypeGIF as String), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForPNGUTI() {
        XCTAssertEqual(PageContentType.contentType(forUTI: kUTTypePNG as String), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForJPEGUTI() {
        XCTAssertEqual(PageContentType.contentType(forUTI: kUTTypeJPEG as String), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForTIFFUTI() {
        XCTAssertEqual(PageContentType.contentType(forUTI: kUTTypeTIFF as String), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForBMPUTI() {
        XCTAssertEqual(PageContentType.contentType(forUTI: kUTTypeBMP as String), .image)
    }
}
