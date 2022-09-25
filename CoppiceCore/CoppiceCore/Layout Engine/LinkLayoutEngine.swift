//
//  ArrowLayoutEngine.swift
//  Coppice
//
//  Created by Martin Pilkington on 14/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public class LinkLayoutEngine {
    public private(set) var links = [LayoutEngineLink]()
    private var linksByUUID = [UUID: LayoutEngineLink]()

    weak var canvasLayoutEngine: CanvasLayoutEngine?

    public func add(_ links: [LayoutEngineLink]) {
        guard links.count > 0 else {
            return
        }
        for link in links {
            guard self.linksByUUID[link.id] == nil else {
                assertionFailure("Adding a link to the layout engine twice: \(link.id)")
                continue
            }
            link.linkLayoutEngine = self
            link.canvasLayoutEngine = self.canvasLayoutEngine
            self.links.append(link)
            self.linksByUUID[link.id] = link
        }
        self.recalculate(withAffectedLinks: links)
    }

    public func remove(_ links: [LayoutEngineLink]) {
        guard links.count > 0 else {
            return
        }
        self.links = self.links.filter { !links.contains($0) }
        for link in links {
            link.linkLayoutEngine = nil
            self.linksByUUID.removeValue(forKey: link.id)
        }

        self.recalculate(withAffectedLinks: links)
    }

    public func updateLinks(forModifiedPages modifiedPages: [LayoutEnginePage]) {
        let pageIDs = modifiedPages.map(\.id)
        let affectedLinks = self.links.filter { pageIDs.contains($0.sourcePageID) || pageIDs.contains($0.destinationPageID) }
        self.recalculate(withAffectedLinks: affectedLinks)
    }


    private func recalculate(withAffectedLinks affectedLinks: [LayoutEngineLink]) {
        var affectedPages = Set<LayoutEnginePage>()
        for link in affectedLinks {
            guard
                let sourcePage = link.sourcePage,
                let destinationPage = link.destinationPage,
                let edge = destinationPage.edge(toSourcePage: sourcePage)
            else {
                continue
            }

            let destinationLocation = destinationPage.initialArrowLocation(for: edge)
            let sourceLocation = sourcePage.initialArrowLocation(for: edge.opposite)

            link.destinationPoint = ArrowPoint(point: destinationLocation, edge: edge)
            link.sourcePoint = ArrowPoint(point: sourceLocation, edge: edge.opposite)

            affectedPages.insert(sourcePage)
            affectedPages.insert(destinationPage)
        }

        for page in affectedPages {
            let links = self.links(for: page)
            for edge in LayoutEnginePage.Edge.allCases {
                let edgeLinks = links.links(for: edge, of: page)
                if edgeLinks.count > 0 {
                    self.process(edgeLinks, for: edge, of: page)
                }
            }
        }

        self.canvasLayoutEngine?.linksChanged()
    }

    private func links(for page: LayoutEnginePage) -> [LayoutEngineLink] {
        return self.links.filter { $0.sourcePageID == page.id || $0.destinationPageID == page.id }
    }

    func updateLinks(forOffsetChange offsetChange: CGPoint) {
        guard offsetChange != .zero else {
            return
        }

        for link in self.links {
            link.sourcePoint = link.sourcePoint.adjusted(by: offsetChange)
            link.destinationPoint = link.destinationPoint.adjusted(by: offsetChange)
        }
    }


    private func process(_ links: [LayoutEngineLink], for edge: LayoutEnginePage.Edge, of page: LayoutEnginePage) {
        switch edge {
        case .top, .bottom:
            self.processVerticalLinks(links, forEdge: edge, of: page)
        case .left, .right:
            self.processHorizontalLinks(links, forEdge: edge, of: page)
        }
    }

    private func processVerticalLinks(_ links: [LayoutEngineLink], forEdge edge: LayoutEnginePage.Edge, of page: LayoutEnginePage) {
        //We want to sort links left to right and place them equally
        let linksSortedByPagePosition = links.sorted { (link1, link2) in
            guard let page1 = link1.opposite(of: page) else {
                return true
            }
            guard let page2 = link2.opposite(of: page) else {
                return false
            }
            return page1.contentFrame.midX < page2.contentFrame.midX
        }
        let sectionSize = page.frameForArrows.width / CGFloat(linksSortedByPagePosition.count)
        let y = (edge == .top) ? page.frameForArrows.minY : page.frameForArrows.maxY

        (0..<linksSortedByPagePosition.count).forEach {
            let link = linksSortedByPagePosition[$0]
            let x = sectionSize * (CGFloat($0) + 0.5) + page.frameForArrows.minX
            if page == link.sourcePage {
                link.sourcePoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: edge)
            } else if page == link.destinationPage {
                link.destinationPoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: edge)
            }
        }
    }

    private func processHorizontalLinks(_ links: [LayoutEngineLink], forEdge edge: LayoutEnginePage.Edge, of page: LayoutEnginePage) {
        //We want to sort links left to right and place them equally
        let linksSortedByPagePosition = links.sorted { (link1, link2) in
            guard let page1 = link1.opposite(of: page) else {
                return true
            }
            guard let page2 = link2.opposite(of: page) else {
                return false
            }
            return page1.contentFrame.midY < page2.contentFrame.midY
        }
        let sectionSize = page.frameForArrows.height / CGFloat(linksSortedByPagePosition.count)
        let x = (edge == .left) ? page.frameForArrows.minX : page.frameForArrows.maxX

        (0..<linksSortedByPagePosition.count).forEach {
            let link = linksSortedByPagePosition[$0]
            let y = (sectionSize * (CGFloat($0) + 0.5)) + page.frameForArrows.minY
            if page == link.sourcePage {
                link.sourcePoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: edge)
            } else if page == link.destinationPage {
                link.destinationPoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: edge)
            }
        }
    }
}

extension LayoutEnginePage {
    fileprivate func initialArrowLocation(for edge: LayoutEnginePage.Edge) -> CGPoint {
        switch edge {
        case .left:
            return self.frameForArrows.point(atX: .min, y: .mid).rounded()
        case .right:
            return self.frameForArrows.point(atX: .max, y: .mid).rounded()
        case .top:
            return self.frameForArrows.point(atX: .mid, y: .min).rounded()
        case .bottom:
            return self.frameForArrows.point(atX: .mid, y: .max).rounded()
        }
    }
}

extension Array where Element == LayoutEngineLink {
    func links(for edge: LayoutEnginePage.Edge, of page: LayoutEnginePage) -> [Element] {
        return self.filter { (($0.sourcePageID == page.id) && ($0.sourcePoint.edge == edge)) || (($0.destinationPageID == page.id) && ($0.destinationPoint.edge == edge)) }
    }
}


//    public func calculateArrows() -> [LayoutEngineLink] {
//        var arrows = [LayoutEngineLink]()
//        for page in self.pages {
//            guard page.parent == nil else {
//                continue
//            }
//            let (_, pageArrows) = self.calculateArrows(for: page)
//            arrows.append(contentsOf: pageArrows)
//        }
//        return arrows
//    }
//
//    private func calculateArrows(for page: LayoutEnginePage, edgeFromParent: LayoutEnginePage.Edge? = nil) -> (ArrowPoint?, [LayoutEngineLink]) {
//        var pagePoint: ArrowPoint? = nil
//        //If the edge from the parent is set then we want to create an arrow for ourselves that will point back to the parent
//        if let parentEdge = edgeFromParent {
//            let point = self.location(for: parentEdge.opposite, of: page)
//            pagePoint = ArrowPoint(point: point, edge: parentEdge.opposite)
//        }
//        //We can exit early if we're a leaf of the tree
//        guard page.children.count > 0 else {
//            return (pagePoint, [])
//        }
//
//        var arrows = [LayoutEngineLink]()
//        //For each edge we want to get all links so we can calculate their start points
//        for edge in LayoutEnginePage.Edge.allCases {
//            var pointsToProcess = [ArrowPoint]()
//            for child in page.children(for: edge) {
//                let (point, pageArrows) = self.calculateArrows(for: child, edgeFromParent: edge)
//                if let point = point {
//                    pointsToProcess.append(point)
//                }
//                arrows.append(contentsOf: pageArrows)
//            }
//
//            //If the parent is on this edge then we need to include it in the calculation, in case there are children on the same edge
//            let includeParent = (pagePoint?.edge == edge)
//            guard (pointsToProcess.count > 0) || includeParent else {
//                continue
//            }
//
//            let (parentPoint, processedArrows) = self.process(pointsToProcess, for: edge, of: page, parent: (includeParent ? pagePoint : nil))
//            if let point = parentPoint {
//                pagePoint = point
//            }
//            arrows.append(contentsOf: processedArrows)
//        }
//        return (pagePoint, arrows)
//    }
//

//

//}

