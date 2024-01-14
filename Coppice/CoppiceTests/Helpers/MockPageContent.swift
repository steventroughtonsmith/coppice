//
//  MockPageContent.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 20/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
@testable import Coppice
@testable import CoppiceCore
import M3Data
import UniformTypeIdentifiers

class MockPageContent: Page.Content, NSFilePromiseProviderDelegate {
    override var minimumContentSize: CGSize {
        return Page.defaultMinimumContentSize
    }

    override var filePromiseProvider: ExtendableFilePromiseProvider {
        return ExtendableFilePromiseProvider(fileType: UTType.text.identifier, delegate: self)
    }

    var maintainAspectRatioOverride: Bool = false
    override var maintainAspectRatio: Bool {
        return self.maintainAspectRatioOverride
    }

    override var contentType: Page.ContentType {
        return .text
    }

    var initialContentSizeOverride: CGSize?
    override var initialContentSize: CGSize? {
        return self.initialContentSizeOverride
    }

    override var modelFile: ModelFile {
        return ModelFile(type: self.contentType.rawValue, filename: nil, data: nil, metadata: nil)
    }

    override func sizeToFitContent(currentSize: CGSize) -> CGSize {
        return currentSize
    }


    var match: Match?
    override func firstMatch(forSearchString searchString: String) -> PageContentMatch? {
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
