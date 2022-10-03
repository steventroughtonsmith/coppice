//
//  MockPageContent.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 20/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
@testable import CoppiceCore
import M3Data

class MockPageContent: NSObject, PageContent, NSFilePromiseProviderDelegate {
    var pageLinks: Set<CoppiceCore.PageLink> = []

    var minimumContentSize: CGSize {
        return Page.defaultMinimumContentSize
    }

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


    var match: Match?
    func firstMatch(forSearchString searchString: String) -> PageContentMatch? {
        return self.match
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        return ""
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }
}

extension MockPageContent {
    struct Match: PageContentMatch {
        var range: NSRange
        var string: String
    }
}
