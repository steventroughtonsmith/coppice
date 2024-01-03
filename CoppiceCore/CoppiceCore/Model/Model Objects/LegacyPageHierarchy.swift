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

    init(id: ModelID, pageID: ModelID, frame: CGRect, children: [LegacyPageHierarchy]) {
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

    public func pageHierarchyPersistenceRepresentation(withSourceCanvasPageID sourceID: ModelID, sourcePageID: ModelID, andFrame sourceFrame: CGRect) -> [ModelPlistKey: PlistValue] {
        let (legacyPages, links) = self.flattenedHierarchyAndLinks()

        let pages = legacyPages.map { legacyPage -> [String: Any] in
            return [
                "canvasPageID": legacyPage.id.stringRepresentation,
                "pageID": legacyPage.pageID.stringRepresentation,
                "relativeContentFrame": NSStringFromRect(legacyPage.frame.moved(byX: -self.frame.origin.x, y: -self.frame.origin.y)),
            ]
        }

        let entryPoints: [String: Any] = [
            "pageLink": PageLink(destination: self.pageID, source: sourceID).url.absoluteString,
            "relativePosition": NSStringFromPoint(self.frame.origin.minus(sourceFrame.origin)),
        ]

        return [
            PageHierarchy.PlistKeys.rootPageID: self.id.stringRepresentation,
            PageHierarchy.PlistKeys.entryPoints: [entryPoints] as PlistValue,
            PageHierarchy.PlistKeys.pages: pages as PlistValue,
            PageHierarchy.PlistKeys.links: links as PlistValue,
        ]
    }

    func flattenedHierarchyAndLinks() -> (pages: [LegacyPageHierarchy], links: [[String: Any]]) {
        var pages = [self]
        var links = [[String: Any]]()
        for child in self.children {
            let (childPages, childLinks) = child.flattenedHierarchyAndLinks()
            pages.append(contentsOf: childPages)
            links.append(contentsOf: childLinks)

            links.append([
                "sourceID": self.id.stringRepresentation,
                "destinationID": child.id.stringRepresentation,
                "link": PageLink(destination: child.pageID, source: self.id).url.absoluteString,
            ])
        }

        return (pages, links)
    }
}
