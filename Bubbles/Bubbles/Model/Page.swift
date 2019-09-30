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

    var id = ModelID(modelType: Page.modelType)
    weak var collection: ModelCollection<Page>?

    init(title: String? = nil) {
        self.title = title ?? "Untitled Page"
    }

    var linkingURL: URL {
        return URL(string: "bubblespage://\(self.id.uuid.uuidString)")!
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
    var content: PageContent = EmptyPageContent()

    var canvases: Set<CanvasPage> {
        return self.relationship(for: \.page)
    }
}


extension ModelCollection where ModelType == Page {
    @discardableResult func newPage(title: String = "Untitled Page") -> Page {
        return self.newObject(context: ["title": title])
    }
}
