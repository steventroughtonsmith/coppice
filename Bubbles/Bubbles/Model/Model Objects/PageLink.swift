//
//  PageLink.swift
//  Bubbles
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

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

    func withSource(_ source: ModelID? = nil) -> Self {
        return PageLink(destination: self.destination, source: source)
    }
}
