//
//  PageContent.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import M3Data

extension Page {
    public class Content: NSObject {
        public var contentType: Page.ContentType {
            preconditionFailure("Must override in subclass")
        }

        public weak var page: Page?
        public var undoManager: UndoManager? {
            self.page?.undoManager
        }

        public var modelFile: ModelFile {
            preconditionFailure("Must override in subclass")
        }

        public var maintainAspectRatio: Bool {
            return false
        }

        public internal(set) var otherMetadata: [String: Any]? = nil
        public internal(set) var pageLinks: Set<PageLink> = []

        public var initialContentSize: CGSize? {
            return nil
        }

        public var minimumContentSize: CGSize {
            return .zero
        }

        func sizeToFitContent(currentSize: CGSize) -> CGSize {
            return currentSize
        }

        @objc dynamic var filePromiseProvider: ExtendableFilePromiseProvider {
            preconditionFailure("Must override in subclass")
        }


        public func didChange<Content: Page.Content, T>(_ keyPath: ReferenceWritableKeyPath<Content, T>, oldValue: T) {
            guard let page = self.page else {
                return
            }

            let pageID = page.id
            page.collection?.notifyOfChange(to: page, keyPath: \Page.content)
            page.collection?.registerUndoAction { (collection) in
                collection.setContentValue(oldValue, for: keyPath, ofPageWithID: pageID)
            }
        }

        public func firstMatch(forSearchString searchString: String) -> PageContentMatch? {
            return nil
        }
    }
}

extension Page.Content: PlistConvertable {
    public func toPlistValue() throws -> PlistValue {
        return self.modelFile
    }

    public static func fromPlistValue(_ plistValue: PlistValue) throws -> Self {
        guard let modelFile = plistValue as? ModelFile else {
            throw PlistConvertableError.invalidConversionFromPlistValue
        }

        guard let contentType = Page.ContentType(rawValue: modelFile.type) else {
            throw ModelObjectUpdateErrors.attributeNotFound("content")
        }

        return try contentType.createContent(modelFile: modelFile) as! Self
    }
}

extension Notification.Name {
    public static let pageContentLinkDidChange = Notification.Name("M3PageContentLinkDidChangeNotification")
}

