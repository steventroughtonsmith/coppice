//
//  PageHierarchy.swift
//  Bubbles
//
//  Created by Martin Pilkington on 26/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class PageHierarchy {
    let id: ModelID
    let pageID: ModelID
    let frame: CGRect
    let children: [PageHierarchy]

    init?(canvasPage: CanvasPage) {
        guard let page = canvasPage.page else {
            return nil
        }
        self.id = canvasPage.id
        self.pageID = page.id
        self.frame = canvasPage.frame
        var children = [PageHierarchy]()
        for child in canvasPage.children {
            if let childHierarchy = PageHierarchy(canvasPage: child) {
                children.append(childHierarchy)
            }
        }
        self.children = children
    }

    init?(plistRepresentation: [String: Any]) {
        guard let idString = plistRepresentation["id"] as? String, let id = ModelID(string: idString) else {
            return nil
        }
        self.id = id

        guard let pageIDString = plistRepresentation["pageID"] as? String, let pageID = ModelID(string: pageIDString) else {
            return nil
        }
        self.pageID = pageID

        guard let frameString = plistRepresentation["frame"] as? String else {
            return nil
        }
        self.frame = NSRectFromString(frameString)

        guard let childrenPlists = plistRepresentation["children"] as? [[String: Any]] else {
            return nil
        }
        self.children = childrenPlists.compactMap { PageHierarchy(plistRepresentation: $0) }
    }

    var plistRepresentation: [String: Any] {
        let childPlists = self.children.map(\.plistRepresentation)
        return [
            "id": self.id.stringRepresentation,
            "pageID": self.pageID.stringRepresentation,
            "frame": NSStringFromRect(self.frame),
            "children": childPlists
        ]
    }
}
