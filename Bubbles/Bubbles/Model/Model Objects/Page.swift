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
    var tags: [Tag] = [] {
        didSet { self.didChange(\.tags, oldValue: oldValue) }
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
}
