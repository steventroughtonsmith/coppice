//
//  LegacyPageHierarchy.swift
//  Coppice
//
//  Created by Martin Pilkington on 26/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Data

public class LegacyPageHierarchy {
    public let id: ModelID
    public let pageID: ModelID
    public let frame: CGRect
    public let children: [LegacyPageHierarchy]

    public convenience init?(canvasPage: CanvasPage) {
        guard let page = canvasPage.page else {
            return nil
        }
        let children = canvasPage.children.compactMap { LegacyPageHierarchy(canvasPage: $0) }
        self.init(id: canvasPage.id, pageID: page.id, frame: canvasPage.frame, children: children)
    }

    public init(id: ModelID, pageID: ModelID, frame: CGRect, children: [LegacyPageHierarchy]) {
        self.id = id
        self.pageID = pageID
        self.frame = frame
        self.children = children
    }

    public convenience init?(plistRepresentation: [String: Any]) {
        guard let idString = plistRepresentation["id"] as? String, let id = ModelID(string: idString) else {
            return nil
        }

        guard let pageIDString = plistRepresentation["pageID"] as? String, let pageID = ModelID(string: pageIDString) else {
            return nil
        }

        guard let frameString = plistRepresentation["frame"] as? String else {
            return nil
        }
        let frame = NSRectFromString(frameString)

        guard let childrenPlists = plistRepresentation["children"] as? [[String: Any]] else {
            return nil
        }
        let children = childrenPlists.compactMap { LegacyPageHierarchy(plistRepresentation: $0) }
        self.init(id: id, pageID: pageID, frame: frame, children: children)
    }

    public var plistRepresentation: [String: Any] {
        //Changing this will require a bump to the document
        let childPlists = self.children.map(\.plistRepresentation)

        return [
            "id": self.id.stringRepresentation,
            "pageID": self.pageID.stringRepresentation,
            "frame": NSStringFromRect(self.frame),
            "children": childPlists,
        ]
    }
}
