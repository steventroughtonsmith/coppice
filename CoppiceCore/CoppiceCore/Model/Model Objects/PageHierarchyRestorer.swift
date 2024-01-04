//
//  PageHierarchyRestorer.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 21/08/2022.
//

import Foundation

class PageHierarchyRestorer {
    let canvas: Canvas
    init(canvas: Canvas) {
        self.canvas = canvas
    }

    func restore(_ pageHierarchy: PageHierarchy, from source: CanvasPage, for link: PageLink) -> [CanvasPage] {
        guard
            let modelController = self.canvas.modelController as? CoppiceModelController,
            let entryPoint = pageHierarchy.entryPoints.first(where: { $0.pageLink == link })
        else {
            return []
        }

        let hierarchyOffset = source.frame.origin.plus(entryPoint.relativePosition)
        let canvasPages = pageHierarchy.pages.map { pageRef in
            return modelController.canvasPageCollection.newObject(modelID: pageRef.canvasPageID) {
                $0.updatePageID(pageRef.pageID)
                $0.canvas = self.canvas
                var absoluteFrame = pageRef.relativeContentFrame
                absoluteFrame.origin = absoluteFrame.origin.plus(hierarchyOffset)
                $0.frame = absoluteFrame
            }
        }

        if let rootPage = canvasPages.first(where: { $0.id == pageHierarchy.rootPageID }) {
            self.canvas.addLink(link, between: source, and: rootPage)
        }

        for linkRef in pageHierarchy.links {
            guard
                let sourcePage = modelController.canvasPageCollection.objectWithID(linkRef.sourceID),
                let destinationPage = modelController.canvasPageCollection.objectWithID(linkRef.destinationID)
            else {
                continue
            }
            self.canvas.addLink(linkRef.link, between: sourcePage, and: destinationPage)
        }

        modelController.pageHierarchyCollection.delete(pageHierarchy)

        return canvasPages
    }
}
