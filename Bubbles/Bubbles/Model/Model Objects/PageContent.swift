//
//  PageContent.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

enum PageContentType: String, Equatable {
    case empty
    case text
    case image

    func createContent(data: Data? = nil, metadata: [String: Any]? = nil) -> PageContent {
        switch self {
        case .empty:
            return EmptyPageContent()
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

    var icon: NSImage? {
        switch self {
        case .text:
            return NSImage(named: "TextPageSmall")
        case .image:
			return NSImage(named: "ImagePageSmall")
        default:
            return nil
        }
    }
}

protocol PageContent: class {
    var contentType: PageContentType { get }
    var contentSize: CGSize? { get }
    var page: Page? { get set }
    var modelFile: ModelFile { get }

    func isMatchForSearch(_ searchTerm: String?) -> Bool
}

extension PageContent {
    func didChange<T>(_ keyPath: ReferenceWritableKeyPath<Self,T>, oldValue: T) {
        guard let page = self.page else {
            return
        }

        let pageID = page.id
        page.collection?.notifyOfChange(to: page)
        page.collection?.registerUndoAction { (collection) in
            collection.setContentValue(oldValue, for: keyPath, ofPageWithID: pageID)
        }
    }

    func isMatchForSearch(_ searchTerm: String?) -> Bool {
        return false
    }
}

