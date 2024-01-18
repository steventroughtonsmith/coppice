//
//  AddPageLayoutCalculator.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation
import M3Data

extension Canvas {
    //MARK: - Page Helpers
    public func existingCanvasPage(for page: Page) -> CanvasPage? {
        return self.pages.first(where: { $0.page?.id == page.id })
    }


    //MARK: - Add New Pages & Links
    @discardableResult public func addPages(_ pages: [Page], centredOn point: CGPoint? = nil) -> [CanvasPage] {
        guard let collection = self.modelController?.collection(for: CanvasPage.self) else {
            preconditionFailure("Could not find canvas page collection")
        }
        guard let firstPage = pages.first else {
            return []
        }

        let halfSize = CGPoint(x: firstPage.contentSize.width / 2, y: firstPage.contentSize.height / 2)
        let centrePoint = point ?? viewPort?.midPoint ?? .zero

        var nextOrigin = centrePoint.minus(halfSize).rounded()
        let step = 20

        var canvasPages = [CanvasPage]()
        for page in pages  {
            let canvasPage = collection.newObject() { canvasPage in
                canvasPage.page = page
                canvasPage.frame.origin = nextOrigin
                canvasPage.canvas = self
            }
            canvasPages.append(canvasPage)
            nextOrigin = nextOrigin.plus(CGPoint(x: step, y: step))
        }

        if pages.count == 1 {
            self.modelController?.undoManager.setActionName(NSLocalizedString("Add Page to Canvas", comment: "Add Page To Canvas Undo Action Name"))
        } else {
            self.modelController?.undoManager.setActionName(NSLocalizedString("Add Pages to Canvas", comment: "Add Pages To Canvas Undo Action Name"))
        }

        return canvasPages
    }

    @discardableResult public func addLink(_ link: PageLink, between page1: CanvasPage, and page2: CanvasPage) -> CanvasLink {
        guard let collection = self.modelController?.collection(for: CanvasLink.self) else {
            preconditionFailure("Could not find canvas link collection")
        }

        if let existingLink = collection.canvasLink(with: link) {
            return existingLink
        }

        return collection.newObject() {
            $0.link = link
            $0.sourcePage = page1
            $0.destinationPage = page2
            $0.canvas = self
        }
    }


    //MARK: - Open & Close Pages
    public enum OpenPageMode: Equatable {
        case new
        case existing
    }

    @discardableResult public func open(_ page: Page, linkedFrom sourcePage: CanvasPage, with pageLink: PageLink, mode: OpenPageMode = .new) -> [CanvasPage] {
        if mode == .existing, let existingPage = self.existingCanvasPage(for: page) {
            self.addLink(pageLink, between: sourcePage, and: existingPage)
            return [existingPage]
        }

        if let hierarchy = self.pageHierarchies.first(where: { $0.entryPoints.contains(where: { $0.pageLink == pageLink }) }) {
            return self.hierarchyRestorer.restore(hierarchy, from: sourcePage, for: pageLink)
        }

        let canvasPage = self.createLinkedCanvasPage(for: page, linkedFrom: sourcePage, with: pageLink)
        return [canvasPage]
    }

    private func createLinkedCanvasPage(for page: Page, linkedFrom sourcePage: CanvasPage, with pageLink: PageLink) -> CanvasPage {
        guard let modelController = self.modelController else {
            preconditionFailure("No Model Controller Set")
        }
        let canvasPageCollection = modelController.collection(for: CanvasPage.self)
        let canvasLinkCollection = modelController.collection(for: CanvasLink.self)

        let frame = self.frame(for: page, linkedFrom: sourcePage)
        modelController.pushChangeGroup()
        let canvasPage = canvasPageCollection.newObject() {
            $0.page = page
            $0.canvas = self
            $0.frame = frame
        }

        canvasLinkCollection.newObject() {
            $0.link = pageLink
            $0.sourcePage = sourcePage
            $0.destinationPage = canvasPage
            $0.canvas = self
        }

        modelController.popChangeGroup()
        return canvasPage
    }

    public func close(_ canvasPage: CanvasPage) {
        let builder = canvasPage.createHierarchyBuilder()

        let linksIn = canvasPage.linksIn
        self.removePageAndLinks(canvasPage, pageHierarchyBuilder: builder)
        //Delete all links into the page being deleted (as we always want to delete that page)
        //This has to happen after removing the page as we need these to exist to determine if there's a cycle
        linksIn.forEach { $0.delete() }

        if let modelController = self.modelController as? CoppiceModelController {
            let hierarchy = builder.buildHierarchy(in: modelController)
            hierarchy.canvas = self
        }
    }

    private func removePageAndLinks(_ canvasPage: CanvasPage, pageHierarchyBuilder: PageHierarchyBuilder) {
        pageHierarchyBuilder.add(canvasPage)
        //Go through all pages linking out from supplied page
        for linkOut in canvasPage.linksOut {
            let page = linkOut.destinationPage
            linkOut.delete()
            //If a destination page has no more links in and was not part of a cycle involving the supplied page, then remove it and children
            if let page, (page.linksIn.count == 0) && (page.doesLink(to: canvasPage) == false) {
                self.removePageAndLinks(page, pageHierarchyBuilder: pageHierarchyBuilder)
            }
        }
        //Remove the page
        canvasPage.delete()
    }


    //MARK: - Frame calculation
    private enum PageDirection: Equatable {
        case left
        case right
        case above
        case below

        var opposite: PageDirection {
            switch self {
            case .left: return .right
            case .right: return .left
            case .above: return .above
            case .below: return .below
            }
        }
    }

    private func frame(for page: Page, linkedFrom sourcePage: CanvasPage) -> CGRect {
        //TODO: Update or delete
        guard let firstChild = sourcePage.children.first else {
            return self.frameWithNoChildren(for: page, linkedFrom: sourcePage)
        }
        return self.frame(for: page, linkedFrom: sourcePage, withFirstChild: firstChild)
    }

    private func frameWithNoChildren(for page: Page, linkedFrom sourcePage: CanvasPage) -> CGRect {
        let contentSize = page.contentSize
        var directions = [PageDirection.right, .left, .below, .above]
        //TODO: Update or delete
        if let parent = sourcePage.parent {
            let parentEdge = self.direction(of: sourcePage, from: parent)
            directions.insert(parentEdge.opposite, at: 0)
        }

        var frames = directions.map {
            return self.frame(forContentSize: contentSize, placed: $0, from: sourcePage)
        }

        for page in self.pages {
            var indexesToRemove = [Int]()
            (0..<frames.count).forEach {
                if page.frame.intersects(frames[$0]) {
                    indexesToRemove.append($0)
                }
            }
            indexesToRemove.reversed().forEach { frames.remove(at: $0) }

            if frames.count == 0 {
                break
            }
        }

        guard let frame = frames.first else {
            return self.frame(forContentSize: contentSize, placed: .right, from: sourcePage)
        }

        return frame
    }

    private func frame(for page: Page, linkedFrom parentPage: CanvasPage, withFirstChild childPage: CanvasPage) -> CGRect {
        let parentFrame = parentPage.frame
        let size = page.contentSize
        let direction = self.direction(of: childPage, from: parentPage)
        let combinedFrame = self.combinedFrameOfSiblings(of: childPage, in: direction)
        switch direction {
        case .right:
            let deltaTop = abs(combinedFrame.minY - parentFrame.midY)
            let deltaBottom = abs(combinedFrame.maxY - parentFrame.midY)

            let y = (deltaTop <= deltaBottom) ? (combinedFrame.minY - GlobalConstants.linkedPageOffset - size.height)
                                              : (combinedFrame.maxY + GlobalConstants.linkedPageOffset)
            let origin = CGPoint(x: childPage.frame.minX, y: y)
            return CGRect(origin: origin, size: size)
        case .left:
            let deltaTop = abs(combinedFrame.minY - parentFrame.midY)
            let deltaBottom = abs(combinedFrame.maxY - parentFrame.midY)

            let y = (deltaTop <= deltaBottom) ? (combinedFrame.minY - GlobalConstants.linkedPageOffset - size.height)
                : (combinedFrame.maxY + GlobalConstants.linkedPageOffset)
            let origin = CGPoint(x: childPage.frame.maxX - size.width, y: y)
            return CGRect(origin: origin, size: size)
        case .above:
            let deltaLeft = abs(combinedFrame.minX - parentFrame.midX)
            let deltaRight = abs(combinedFrame.maxX - parentFrame.midX)

            let x = (deltaLeft < deltaRight) ? (combinedFrame.minX - GlobalConstants.linkedPageOffset - size.width)
                : (combinedFrame.maxX + GlobalConstants.linkedPageOffset)
            let origin = CGPoint(x: x, y: childPage.frame.maxY - size.height)
            return CGRect(origin: origin, size: size)
        case .below:
            let deltaLeft = abs(combinedFrame.minX - parentFrame.midX)
            let deltaRight = abs(combinedFrame.maxX - parentFrame.midX)

            let x = (deltaLeft < deltaRight) ? (combinedFrame.minX - GlobalConstants.linkedPageOffset - size.width)
                : (combinedFrame.maxX + GlobalConstants.linkedPageOffset)
            let origin = CGPoint(x: x, y: childPage.frame.minY)
            return CGRect(origin: origin, size: size)
        }
    }

    private func combinedFrameOfSiblings(of canvasPage: CanvasPage, in direction: PageDirection) -> CGRect {
        var frame = canvasPage.frame

        guard let parent = canvasPage.parent else {
            return frame
        }

        for child in parent.children {
            switch direction {
            case .right:
                if (child.frame.minX > parent.frame.maxX) {
                    frame = frame.union(child.frame)
                }
            case .left:
                if (child.frame.maxX < parent.frame.minX) {
                    frame = frame.union(child.frame)
                }
            case .below:
                if (child.frame.minY > parent.frame.maxY) {
                    frame = frame.union(child.frame)
                }
            case .above:
                if (child.frame.maxY < parent.frame.minY) {
                    frame = frame.union(child.frame)
                }
            }
        }
        return frame
    }

    private func direction(of canvasPage: CanvasPage, from otherPage: CanvasPage) -> PageDirection {
        let point = canvasPage.frame.origin.minus(otherPage.frame.origin)
        if (abs(point.x) < abs(point.y)) {
            return (point.y < 0) ? .above : .below
        }
        return (point.x < 0) ? .left : .right
    }

    private func frame(forContentSize size: CGSize, placed direction: PageDirection, from canvasPage: CanvasPage) -> CGRect {
        let frame = canvasPage.frame
        switch direction {
        case .left:
            let x = frame.minX - GlobalConstants.linkedPageOffset - size.width
            let y = frame.midY - (size.height / 2)
            let point = CGPoint(x: x, y: y).rounded()
            return CGRect(origin: point, size: size)
        case .right:
            let x = frame.maxX + GlobalConstants.linkedPageOffset
            let y = frame.midY - (size.height / 2)
            let point = CGPoint(x: x, y: y).rounded()
			return CGRect(origin: point, size: size)
        case .above:
            let x = frame.midX - (size.width / 2)
            let y = frame.minY - GlobalConstants.linkedPageOffset - size.height
            let point = CGPoint(x: x, y: y).rounded()
            return CGRect(origin: point, size: size)
        case .below:
            let x = frame.midX - (size.width / 2)
            let y = frame.maxY + GlobalConstants.linkedPageOffset
            let point = CGPoint(x: x, y: y).rounded()
            return CGRect(origin: point, size: size)
        }
    }
}

extension CanvasPage {
    #if TEST
    static var overrideBuilder: PageHierarchyBuilder?
    #endif
    //MARK: - Page Hierarchies
    func createHierarchyBuilder() -> PageHierarchyBuilder {
        #if TEST
        if let overrideBuilder = Self.overrideBuilder {
            return overrideBuilder
        }
        #endif
        return PageHierarchyBuilder(rootPage: self)
    }
}
