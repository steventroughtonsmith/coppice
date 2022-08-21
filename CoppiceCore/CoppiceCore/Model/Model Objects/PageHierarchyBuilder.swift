//
//  PageHierarchyBuilder.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 20/08/2022.
//

import Foundation
import M3Data

class PageHierarchyBuilder {
    private let rootPageID: ModelID
    private let entryPoints: [PageHierarchy.EntryPoint]
    private let hierarchyOrigin: CGPoint
    init(rootPage: CanvasPage) {
        self.rootPageID = rootPage.id
        self.hierarchyOrigin = rootPage.frame.origin

        var entryPoints = [PageHierarchy.EntryPoint]()
        for link in rootPage.linksIn {
            guard
                let sourcePage = link.sourcePage,
                let pageLink = link.link
            else {
                continue
            }
            let relativePosition = rootPage.frame.origin.minus(sourcePage.frame.origin)
            entryPoints.append(PageHierarchy.EntryPoint(pageLink: pageLink, relativePosition: relativePosition))
        }
        self.entryPoints = entryPoints
    }


    private var pageRefs = [PageHierarchy.PageRef]()
    private var linkRefs = [PageHierarchy.LinkRef]()
    func add(_ canvasPage: CanvasPage) {
        guard let pageID = canvasPage.page?.id else {
            return
        }

        var relativeFrame = canvasPage.frame
        relativeFrame.origin = relativeFrame.origin.minus(self.hierarchyOrigin)

        pageRefs.append(PageHierarchy.PageRef(canvasPageID: canvasPage.id, pageID: pageID, relativeContentFrame: relativeFrame))

        for linkOut in canvasPage.linksOut {
            guard
                let sourceID = linkOut.sourcePage?.id,
                let destinationID = linkOut.destinationPage?.id,
                let pageLink = linkOut.link
            else {
                continue
            }
            linkRefs.append(PageHierarchy.LinkRef(sourceID: sourceID, destinationID: destinationID, link: pageLink))
        }
    }

    func buildHierarchy(in modelController: CoppiceModelController) -> PageHierarchy {
        return modelController.pageHierarchyCollection.newObject() {
            $0.entryPoints = self.entryPoints
            $0.pages = self.pageRefs
            $0.links = self.linkRefs
            $0.rootPageID = self.rootPageID
        }
    }
}
