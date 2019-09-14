//
//  CanvasLayoutEngine.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 31/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

struct LayoutEventModifiers: OptionSet {
    let rawValue: UInt

    static let shift = LayoutEventModifiers(rawValue: 1 << 0)
    static let control = LayoutEventModifiers(rawValue: 1 << 1)
    static let option = LayoutEventModifiers(rawValue: 1 << 2)
    static let command = LayoutEventModifiers(rawValue: 1 << 3)
}


protocol CanvasLayoutView: class {
    func layoutChanged()
    var viewPortFrame: CGRect { get }
}


protocol CanvasLayoutEngineDelegate: class {
    func moved(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine)
}


protocol CanvasEventContext {
    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, in layout: CanvasLayoutEngine)
    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, in layout: CanvasLayoutEngine)
    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, in layout: CanvasLayoutEngine)
}


class CanvasLayoutEngine: NSObject {
    weak var view: CanvasLayoutView?
    weak var delegate: CanvasLayoutEngineDelegate?

    var contentBorder: CGFloat = 1000

    //MARK: - Manage Canvas
    private(set) var canvasSize: CGSize = .zero
    private var pageSpaceOffset: CGPoint = .zero {
        didSet {
//            if (self.pageSpaceOffset != oldValue) {
                self.updatePageCanvasFrames()
//            }
        }
    }

    func convertPointToPageSpace(_ point: CGPoint) -> CGPoint {
        return point.minus(self.pageSpaceOffset)
    }

    func convertPointToCanvasSpace(_ point: CGPoint) -> CGPoint {
        return point.plus(self.pageSpaceOffset)
    }

    private func recalculateCanvasSize() {
        var contentFrame: CGRect!
        for page in self.pages {
            guard let currentFrame = contentFrame else {
                contentFrame = page.pageFrame
                continue
            }
            contentFrame = currentFrame.union(page.pageFrame)
        }

        if contentFrame == nil {
            contentFrame = .zero
        }

        contentFrame = contentFrame.insetBy(dx: -self.contentBorder, dy: -self.contentBorder)

        if var viewPortFrame = self.view?.viewPortFrame {
            viewPortFrame.origin = self.convertPointToPageSpace(viewPortFrame.origin)
            contentFrame = contentFrame.union(viewPortFrame)
        }

        self.canvasSize = contentFrame.size
        self.pageSpaceOffset = contentFrame.origin.multiplied(by: -1)
        self.view?.layoutChanged()
    }

    private func updatePageCanvasFrames() {
        for page in self.pages {
            page.canvasOrigin = self.convertPointToCanvasSpace(page.pageOrigin)
        }
    }

    
    //MARK: - Manage Pages
    private(set) var pages = [LayoutEnginePage]()

    func add(_ pages: [LayoutEnginePage]) {
        for page in pages {
            self.pages.append(page)
        }
        self.recalculateCanvasSize()
    }

    func remove(_ pages: [LayoutEnginePage]) {
        self.pages = self.pages.filter { !pages.contains($0) }
        self.recalculateCanvasSize()
    }

    var selectedPages: [LayoutEnginePage] {
        return self.pages.filter { $0.selected }
    }
    var selectionRect: CGRect?

    func page(atCanvasPoint canvasPoint: CGPoint) -> LayoutEnginePage? {
        for page in self.pages.reversed() {
            if page.canvasFrame.contains(canvasPoint) {
                return page
            }
        }
        return nil
    }

    func pages(inCanvasRect canvasRect: CGRect) -> [LayoutEnginePage] {
        var pagesInRect = [LayoutEnginePage]()
        for page in self.pages {
            if page.canvasFrame.intersects(canvasRect) {
                pagesInRect.append(page)
            }
        }
        return pagesInRect
    }

    func deselectAll() {
        self.selectedPages.forEach { $0.selected = false }
        self.view?.layoutChanged()
    }

    func finishedModifying(_ pages: [LayoutEnginePage]) {
        self.delegate?.moved(pages: pages, in: self)
    }

    private func movePageToFront(_ page: LayoutEnginePage) {
        guard let index = self.pages.firstIndex(of: page) else {
            return // Page doesn't exist
        }

        self.pages.remove(at: index)
        self.pages.append(page)
    }


    //MARK: - Manage Events
    private var currentEventContext: CanvasEventContext?

    private func createEventContext(for location: CGPoint) -> CanvasEventContext? {
        //Canvas click
        guard let page = self.page(atCanvasPoint: location) else {
            return CanvasSelectionEventContext(originalSelection: self.selectedPages)
        }

        self.movePageToFront(page)

        //Page content click
        guard let pageComponent = page.component(at: location.minus(page.canvasOrigin)) else {
            return nil
        }

        switch pageComponent {
        case .titleBar:
            return PageTitleBarEventContext(page: page)
        default:
            return ResizePageEventContext(page: page, component: pageComponent)
        }
    }

    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers = []) {
        self.currentEventContext = self.createEventContext(for: location)
        self.currentEventContext?.downEvent(at: location, modifiers: modifiers, in: self)
        self.view?.layoutChanged()
    }

    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers = []) {
        self.currentEventContext?.draggedEvent(at: location, modifiers: modifiers, in: self)
        self.view?.layoutChanged()
    }

    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers = []) {
        self.currentEventContext?.upEvent(at: location, modifiers: modifiers, in: self)
        self.recalculateCanvasSize()
        self.view?.layoutChanged()
    }
}
