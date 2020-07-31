//
//  PageContent.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

public enum PageContentType: String, Equatable, CaseIterable {
    case text
    case image

    public func createContent(data: Data? = nil, metadata: [String: Any]? = nil) -> PageContent {
        switch self {
        case .text:
            return TextPageContent(data: data)
        case .image:
            return ImagePageContent(data: data, metadata: metadata)
        }
    }

    public static func contentType(forUTI uti: String) -> PageContentType? {
        if UTTypeConformsTo(uti as CFString, kUTTypeText) {
            return .text
        }
        if UTTypeConformsTo(uti as CFString, kUTTypeImage) {
            return .image
        }
        return nil
    }

    public var icon: NSImage {
        return icon(.small)
    }

    public func icon(_ size: Symbols.Page.Size) -> NSImage {
        switch self {
        case .text:
            return NSImage.symbol(withName: Symbols.Page.text(size))!
        case .image:
            return NSImage.symbol(withName: Symbols.Page.image(size))!
        }
    }

    public var addIcon: NSImage {
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 10 {
            return self.icon(.small)
        }
        return self.icon(.regular)
    }

    public var localizedName: String {
        switch self {
        case .text:
            return NSLocalizedString("Text Page", comment: "Text content name")
        case .image:
            return NSLocalizedString("Image Page", comment: "Image content name")
        }
    }

    public var keyEquivalent: String {
        switch self {
        case .text, .image:
            return "N"

        }
    }

    public var keyEquivalentModifierMask: NSEvent.ModifierFlags {
        switch self {
        case .text:
            return [.command, .shift]
        case .image:
            return [.option, .command]
        }
    }
}

public protocol PageContent: class {
    var contentType: PageContentType { get }
    var page: Page? { get set }
    var modelFile: ModelFile { get }
    var maintainAspectRatio: Bool { get }

    func firstRangeOf(_ searchTerm: String) -> NSRange

    var initialContentSize: CGSize? { get }

    func sizeToFitContent(currentSize: CGSize) -> CGSize

    var filePromiseProvider: ExtendableFilePromiseProvider { get }
}

public extension PageContent {
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
}

