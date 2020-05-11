//
//  AddPageLayoutCalculator.swift
//  Bubbles
//
//  Created by Martin Pilkington on 22/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

extension Canvas {
    //MARK: - Add New Pages
    @discardableResult func addPages(_ pages: [Page], centredOn point: CGPoint? = nil) -> [CanvasPage] {
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


    //MARK: - Open & Close Pages
    @discardableResult func open(_ page: Page, linkedFrom sourcePage: CanvasPage) -> [CanvasPage] {
        guard let collection = self.modelController?.collection(for: CanvasPage.self) else {
            preconditionFailure("Could not find canvas page collection")
        }

        guard let existingHierarchy = self.closedPageHierarchies[sourcePage.id]?[page.id] else {
            let frame = self.frame(for: page, linkedFrom: sourcePage)
            let canvasPage = collection.newObject() {
                $0.page = page
                $0.parent = sourcePage
                $0.canvas = self
                $0.frame = frame
            }
            return [canvasPage]
        }

        self.closedPageHierarchies[sourcePage.id]?[page.id] = nil
        return self.open(existingHierarchy, linkedFrom: sourcePage)
    }

    private func open(_ hierarchy: PageHierarchy, linkedFrom sourcePage: CanvasPage) -> [CanvasPage] {
        guard let canvasPageCollection = self.modelController?.collection(for: CanvasPage.self),
            let pageCollection = self.modelController?.collection(for: Page.self) else {
                preconditionFailure("Could not find canvas page collection")
        }

        var canvasPages = [CanvasPage]()

        let pageForHierarchy = canvasPageCollection.newObject() {
            $0.id = hierarchy.id
            $0.page = pageCollection.objectWithID(hierarchy.pageID)
            $0.frame = hierarchy.frame
            $0.canvas = self
            $0.parent = sourcePage
        }
        canvasPages.append(pageForHierarchy)
        for child in hierarchy.children {
            canvasPages.append(contentsOf: self.open(child, linkedFrom: pageForHierarchy))
        }

        return canvasPages
    }

    func close(_ canvasPage: CanvasPage) {
        if let parent = canvasPage.parent, let page = canvasPage.page, let hierarchy = PageHierarchy(canvasPage: canvasPage) {
            var hierarchies = self.closedPageHierarchies[parent.id] ?? [ModelID: PageHierarchy]()
            hierarchies[page.id] = hierarchy
            self.closedPageHierarchies[parent.id] = hierarchies
        }

        self.removeCanvasPages(startingFrom: canvasPage)
    }

    private func removeCanvasPages(startingFrom canvasPage: CanvasPage) {
        for child in canvasPage.children {
            self.removeCanvasPages(startingFrom: child)
        }
        canvasPage.parent = nil
        canvasPage.collection?.delete(canvasPage)
    }


    //MARK: - Frame calculation
    private enum PageDirection : Equatable {
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
        guard let firstChild = sourcePage.children.first else {
            return self.frameWithNoChildren(for: page, linkedFrom: sourcePage)
        }
        return self.frame(for: page, linkedFrom: sourcePage, withFirstChild: firstChild)
    }

    private func frameWithNoChildren(for page: Page, linkedFrom sourcePage: CanvasPage) -> CGRect {
        let contentSize = page.contentSize
        var directions = [PageDirection.right, .left, .below, .above]
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
