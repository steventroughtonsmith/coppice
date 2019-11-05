//
//  Page.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

struct Tag {
    let name: String
}

final class Page: NSObject, CollectableModelObject {
    static let modelType: ModelType = ModelType(rawValue: "Page")!
    static let standardSize = CGSize(width: 300, height: 400)
    static let contentChangedNotification = Notification.Name("PageContentChangedNotification")

    var id = ModelID(modelType: Page.modelType)
    weak var collection: ModelCollection<Page>?

    func linkToPage(from sourcePage: Page? = nil) -> PageLink {
        return PageLink(destination: self.id, source: sourcePage?.id)
    }

    override init() {
        self.title = "Untitled Page"
        self.content = EmptyPageContent()
        super.init()
        self.content.page = self
    }

    // MARK: - Attributes
    @objc dynamic var title: String {
        didSet { self.didChange(\.title, oldValue: oldValue) }
    }
    var dateCreated = Date()
    var dateModified = Date()
    private var userPreferredSize: CGSize?
    var contentSize: CGSize {
        get {
            return self.userPreferredSize ?? self.content.contentSize ?? Page.standardSize
        }
        set {
            self.userPreferredSize = newValue
        }
    }


    // MARK: - Relationships
    var content: PageContent {
        didSet {
            self.content.page = self
            NotificationCenter.default.post(name: Page.contentChangedNotification, object: self)
        }
    }

    var canvases: Set<CanvasPage> {
        return self.relationship(for: \.page)
    }


    //MARK: - Helpers
    func updatePageSizes() {
        guard self.userPreferredSize == nil else {
            return
        }
        self.canvases.forEach { canvasPage in
            var frame = canvasPage.frame
            frame.size = self.contentSize
            canvasPage.frame = frame
        }
    }


    //MARK: - Plists
    static var modelFileProperties: [String] {
        return ["content"]
    }
    
    var plistRepresentation: [String : Any] {
        var plist: [String: Any] = [
            "id": self.id.stringRepresentation,
            "title": self.title,
            "dateCreated": self.dateCreated,
            "dateModified": self.dateModified,
            "content": self.content.modelFile
        ]
        if let preferredSize = self.userPreferredSize {
            plist["userPreferredSize"] = NSStringFromSize(preferredSize)
        }

        return plist
    }

    func update(fromPlistRepresentation plist: [String : Any]) throws {
        guard self.id.stringRepresentation == (plist["id"] as? String) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        self.title = try self.attribute(withKey: "title", from: plist)
        self.dateCreated = try self.attribute(withKey: "dateCreated", from: plist)
        self.dateModified = try self.attribute(withKey: "dateModified", from: plist)

        if let userPreferredSizeString = plist["userPreferredSize"] as? String {
            self.userPreferredSize = NSSizeFromString(userPreferredSizeString)
        } else {
            self.userPreferredSize = nil
        }

        let content: ModelFile = try self.attribute(withKey: "content", from: plist)
        guard let contentType = PageContentType(rawValue: content.type) else {
            throw ModelObjectUpdateErrors.attributeNotFound("content")
        }
        self.content = contentType.createContent(data: content.data)
    }

    private func attribute<T>(withKey key: String, from plist: [String: Any]) throws -> T {
        guard let value = plist[key] as? T else {
            throw ModelObjectUpdateErrors.attributeNotFound(key)
        }
        return value
    }
}
