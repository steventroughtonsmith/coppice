//
//  PageContentTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 09/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest
import UniformTypeIdentifiers

class PageContentTests: XCTestCase {
    func test_pageContentType_contentTypeForUTIReturnsTextForPlainTextUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: UTType.text.identifier), .text)
    }

    func test_pageContentType_contentTypeForUTIReturnsTextForRTFUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: UTType.rtf.identifier), .text)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForGIFUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: UTType.gif.identifier), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForPNGUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: UTType.png.identifier), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForJPEGUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: UTType.jpeg.identifier), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForTIFFUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: UTType.tiff.identifier), .image)
    }

    func test_pageContentType_contentTypeForUTIReturnsImageForBMPUTI() {
        XCTAssertEqual(Page.ContentType.contentType(forUTI: UTType.bmp.identifier), .image)
    }
}
