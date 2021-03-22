//
//  MockPageContent.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 20/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
@testable import CoppiceCore

class MockPageContent: NSObject, PageContent, NSFilePromiseProviderDelegate {
    var otherMetadata: [String: Any]?


    var filePromiseProvider: ExtendableFilePromiseProvider {
        return ExtendableFilePromiseProvider(fileType: (kUTTypeText as String), delegate: self)
    }

    var maintainAspectRatio: Bool = false

    var contentType: PageContentType {
        return .text
    }

    var initialContentSize: CGSize?

    var page: Page?

    var modelFile: ModelFile {
        return ModelFile(type: self.contentType.rawValue, filename: nil, data: nil, metadata: nil)
    }

    func sizeToFitContent(currentSize: CGSize) -> CGSize {
        return currentSize
    }


    var searchRange = NSRange(location: NSNotFound, length: 0)
    func firstRangeOf(_ searchTerm: String) -> NSRange {
        self.searchRange
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        return ""
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }
}
