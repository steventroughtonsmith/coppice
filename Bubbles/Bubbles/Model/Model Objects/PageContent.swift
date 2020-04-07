//
//  PageContent.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

enum PageContentType: String, Equatable, CaseIterable {
    case text
    case image

    func createContent(data: Data? = nil, metadata: [String: Any]? = nil) -> PageContent {
        switch self {
        case .text:
            return TextPageContent(data: data)
        case .image:
            return ImagePageContent(data: data, metadata: metadata)
        }
    }

    static func contentType(forUTI uti: String) -> PageContentType? {
        if UTTypeConformsTo(uti as CFString, kUTTypeText) {
            return .text
        }
        if UTTypeConformsTo(uti as CFString, kUTTypeImage) {
            return .image
        }
        return nil
    }

    var icon: NSImage {
        switch self {
        case .text:
            return NSImage(named: .textPage)!
        case .image:
            return NSImage(named: .imagePage)!
        }
    }

    var localizedName: String {
        switch self {
        case .text:
            return NSLocalizedString("Text Page", comment: "Text content name")
        case .image:
            return NSLocalizedString("Image page", comment: "Image content name")
        }
    }

    var keyEquivalent: String {
        switch self {
        case .text, .image:
            return "N"

        }
    }

    var keyEquivalentModifierMask: NSEvent.ModifierFlags {
        switch self {
        case .text:
            return [.command, .shift]
        case .image:
            return [.option, .command]
        }
    }
}

protocol PageContent: class {
    var contentType: PageContentType { get }
    var contentSize: CGSize? { get }
    var page: Page? { get set }
    var modelFile: ModelFile { get }

    func firstRangeOf(_ searchTerm: String) -> NSRange

    var filePromiseProvider: ExtendableFilePromiseProvider? { get }
}

extension PageContent {
    func didChange<T>(_ keyPath: ReferenceWritableKeyPath<Self,T>, oldValue: T) {
        guard let page = self.page else {
            return
        }

        let pageID = page.id
        page.collection?.notifyOfChange(to: page, keyPath: \Page.content)
        page.collection?.registerUndoAction { (collection) in
            collection.setContentValue(oldValue, for: keyPath, ofPageWithID: pageID)
        }
    }

    func firstRangeOf(_ searchTerm: String) -> NSRange {
        return NSRange(location: NSNotFound, length: 0)
    }

    var filePromiseProvider: ExtendableFilePromiseProvider? {
        return nil
    }
}

