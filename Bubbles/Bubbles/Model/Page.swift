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

    var id = ModelID(modelType: Page.modelType)
    weak var collection: ModelCollection<Page>?

    init(content: PageContent, title: String? = nil) {
        self.content = content
        self.title = title ?? "Untitled Page"
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


    // MARK: - Relationships
    var content: PageContent!

    var canvases: Set<CanvasPage> {
        return self.relationship(for: \.page)
    }
}


extension ModelCollection where ModelType == Page {
    @discardableResult func newPage(ofType type: PageContentType = .text, title: String = "Untitled Page") -> Page {
        return self.newObject(context: ["type": type, "title": title])
    }
}
