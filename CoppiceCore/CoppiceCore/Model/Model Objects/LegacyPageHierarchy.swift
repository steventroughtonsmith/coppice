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

    public func pageHierarchyPlistRepresentation(withSourceCanvasPageID sourceID: ModelID, andFrame sourceFrame: CGRect) -> [ModelPlistKey: Any] {
        let (legacyPages, links) = self.flattenedHierarchyAndLinks()

        let pages = legacyPages.map { legacyPage -> [ModelPlistKey: Any] in
            return [
                .PageHierarchy.PageRef.canvasPageID: legacyPage.id,
                .PageHierarchy.PageRef.pageID: legacyPage.pageID,
                .PageHierarchy.PageRef.relativeContentFrame: legacyPage.frame.moved(byX: -self.frame.origin.x, y: -self.frame.origin.y)
            ]
        }


        return [
            .PageHierarchy.rootPageID: self.id,
            .PageHierarchy.entryPoints: [[
                ModelPlistKey.PageHierarchy.EntryPoint.pageLink: PageLink(destination: self.pageID).url,
                ModelPlistKey.PageHierarchy.EntryPoint.relativePosition: self.frame.origin.minus(sourceFrame.origin)
            ]],
            .PageHierarchy.pages: pages,
            .PageHierarchy.links: links,
        ]
    }

    private func flattenedHierarchyAndLinks() -> (pages: [LegacyPageHierarchy], links: [[ModelPlistKey: Any]]) {
        var pages = [self]
        var links = [[ModelPlistKey: Any]]()
        for child in self.children {
            let (childPages, childLinks) = child.flattenedHierarchyAndLinks()
            pages.append(contentsOf: childPages)
            links.append(contentsOf: childLinks)

            links.append([
                .PageHierarchy.LinkRef.sourceID: self.id,
                .PageHierarchy.LinkRef.destinationID: child.id,
                .PageHierarchy.LinkRef.link: PageLink(destination: child.pageID, source: self.pageID).url,
            ])
        }

        return (pages, links)
    }
}
