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

    var id = UUID()
    weak var collection: ModelCollection<Page>?

    override required init() {
        super.init()
    }

    
    // MARK: - Attributes
    @objc dynamic var title: String = "Untitled Page" {
        didSet { self.didChange(\.title, oldValue: oldValue) }
    }
    var tags: [Tag] = [] {
        didSet { self.didChange(\.tags, oldValue: oldValue) }
    }
    var dateCreated = Date()
    var dateModified = Date()


    // MARK: - Relationships
    var content: PageContent?

    var canvases: Set<CanvasPage> {
        return self.relationship(for: \.page)
    }
}

protocol PageContent: class {

}
