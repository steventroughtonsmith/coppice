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

    func linkToPage(from sourcePage: Page? = nil) -> PageLink {
        return PageLink(destination: self.id, source: sourcePage?.id)
    }

    init(title: String? = nil) {
        self.title = title ?? "Untitled Page"
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

struct PageLink {
    static let host = "page"
    static let querySourceName = "source"
    let destination: ModelID
    let source: ModelID?

    init(destination: ModelID, source: ModelID? = nil) {
        self.destination = destination
        self.source = source
    }

    init?(url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            urlComponents.scheme == GlobalConstants.urlScheme,
            urlComponents.host == PageLink.host else {
            return nil
        }

        let path = urlComponents.path
        let destinationUUIDString = String(path[(path.index(after: path.startIndex))...])
        guard let destinationID = Page.modelID(withUUIDString: destinationUUIDString) else {
            return nil
        }

        var sourceID: ModelID? = nil
        if let queryItem = urlComponents.queryItems?.first,
            queryItem.name == PageLink.querySourceName,
            let value = queryItem.value {

            sourceID = Page.modelID(withUUIDString: value)
        }

        self.init(destination: destinationID, source: sourceID)
    }

    var url: URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = GlobalConstants.urlScheme
        urlComponents.host = PageLink.host
        urlComponents.path = "/\(self.destination.uuid.uuidString)"
        if let source = self.source {
            urlComponents.queryItems = [URLQueryItem(name: PageLink.querySourceName, value: source.uuid.uuidString)]
        }
        guard let url = urlComponents.url else {
            fatalError("Failed to create url from components: \(urlComponents)")
        }
        return url
    }
}


extension ModelCollection where ModelType == Page {
    @discardableResult func newPage(title: String = "Untitled Page") -> Page {
        return self.newObject(context: ["title": title])
    }
}
