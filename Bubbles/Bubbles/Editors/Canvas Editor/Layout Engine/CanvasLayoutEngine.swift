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
    func layoutChanged(with context: CanvasLayoutEngine.LayoutContext)
    var viewPortFrame: CGRect { get }
}


protocol CanvasLayoutEngineDelegate: class {
    func moved(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine)
    func remove(pages: [LayoutEnginePage], from layout: CanvasLayoutEngine)
}



class CanvasLayoutEngine: NSObject {
    weak var view: CanvasLayoutView?
    weak var delegate: CanvasLayoutEngineDelegate?

    let configuration: Configuration
    init(configuration: Configuration) {
        self.configuration = configuration
    }

    //MARK: - Manage Canvas
    private(set) var canvasSize: CGSize = .zero
    private var pageSpaceOffset: CGPoint = .zero

    func convertPointToPageSpace(_ point: CGPoint) -> CGPoint {
        return point.minus(self.pageSpaceOffset)
    }

    func convertPointToCanvasSpace(_ point: CGPoint) -> CGPoint {
        return point.plus(self.pageSpaceOffset)
    }

    private func recalculateCanvasSize() -> LayoutContext {
        var contentFrame: CGRect!
        for page in self.pages {
            guard let currentFrame = contentFrame else {
                contentFrame = page.layoutFrameInPageSpace.rounded()
                continue
            }
            contentFrame = currentFrame.union(page.layoutFrameInPageSpace.rounded())
        }

        if contentFrame == nil {
            contentFrame = .zero
        }

        contentFrame = contentFrame.insetBy(dx: -self.configuration.contentBorder, dy: -self.configuration.contentBorder)

        if var viewPortFrame = self.view?.viewPortFrame, self.pages.count > 0 {
            viewPortFrame.origin = self.convertPointToPageSpace(viewPortFrame.origin)
            contentFrame = contentFrame.union(viewPortFrame)
        }

        let newOffset = contentFrame.origin.multiplied(by: -1)
        let offsetChange = newOffset.minus(self.pageSpaceOffset)
        self.pageSpaceOffset = newOffset

        let canvasChanged = (self.canvasSize != contentFrame.size)
        self.canvasSize = contentFrame.size

        self.updateArrows()

        return LayoutContext(sizeChanged: canvasChanged, pageOffsetChange: offsetChange)
    }


    //MARK: - Manage Pages
    private(set) var pages = [LayoutEnginePage]()
    private var pagesByUUID = [UUID: LayoutEnginePage]()

    func add(_ pages: [LayoutEnginePage]) {
        for page in pages {
            guard self.pagesByUUID[page.id] == nil else {
                assertionFailure("Adding a page to the layout engine twice: \(page.id)")
                continue
            }
            page.layoutEngine = self
            self.pages.append(page)
            self.pagesByUUID[page.id] = page
        }

        self.informOfLayoutChange(with: self.recalculateCanvasSize())
    }

    func remove(_ pages: [LayoutEnginePage]) {
        self.pages = self.pages.filter { !pages.contains($0) }
        for page in pages {
            page.parent?.removeChild(page)
            self.pagesByUUID.removeValue(forKey: page.id)
        }
        self.informOfLayoutChange(with: self.recalculateCanvasSize())
    }

    func updateContentFrame(_ frame: CGRect, ofPageWithID uuid: UUID) {
        guard let page = self.pagesByUUID[uuid] else {
            return
        }
        guard page.contentFrame != frame else {
            return
        }
        page.contentFrame = frame
        self.informOfLayoutChange(with: self.recalculateCanvasSize())
    }


    //MARK: - Retrieving Pages
    func page(withID uuid: UUID) -> LayoutEnginePage? {
        return self.pagesByUUID[uuid]
    }

    func page(atCanvasPoint canvasPoint: CGPoint) -> LayoutEnginePage? {
        for page in self.pages.reversed() {
            if page.layoutFrame.contains(canvasPoint) {
                return page
            }
        }
        return nil
    }

    func pages(inCanvasRect canvasRect: CGRect) -> [LayoutEnginePage] {
        var pagesInRect = [LayoutEnginePage]()
        for page in self.pages {
            if page.layoutFrame.intersects(canvasRect) {
                pagesInRect.append(page)
            }
        }
        return pagesInRect
    }

    func modified(_ pages: [LayoutEnginePage]) {
        self.updateArrows()
    }

    func finishedModifying(_ pages: [LayoutEnginePage]) {
        self.updateEnabledPage()
        self.delegate?.moved(pages: pages, in: self)
    }

    func tellDelegateToRemove(_ pages: [LayoutEnginePage]) {
        self.delegate?.remove(pages: pages, from: self)
    }

    private func movePageToFront(_ page: LayoutEnginePage) {
        guard let index = self.pages.firstIndex(of: page) else {
            return // Page doesn't exist
        }

        self.pages.remove(at: index)
        self.pages.append(page)
    }


    //MARK: - Selection
    var selectedPages: [LayoutEnginePage] {
        return self.pages.filter { $0.selected }
    }

    var selectionRect: CGRect?

    func deselectAll() {
        self.selectedPages.forEach { $0.selected = false }
        self.updateEnabledPage()
        self.informOfLayoutChange(with: LayoutContext())
    }

    private var previousSelectionIDs = Set<UUID>()
    private func hasSelectionChanged() -> Bool {
        let newSelectionIDs = Set(self.selectedPages.map { $0.id })
        let selectionChanged = (self.previousSelectionIDs != newSelectionIDs)
        self.previousSelectionIDs = newSelectionIDs
        return selectionChanged
    }

    weak var enabledPage: LayoutEnginePage?
    private func updateEnabledPage() {
        guard self.selectedPages.count == 1, let page = self.selectedPages.first else {
            self.enabledPage = nil
            return
        }
        self.enabledPage = page
    }


    //MARK: - Manage Arrows
    private(set) var arrows = [LayoutEngineArrow]()

    func updateArrows() {
        let engine = ArrowLayoutEngine(pages: self.pages, layoutEngine: self)
        self.arrows = engine.calculateArrows()
    }


    //MARK: - Manage Mouse Events
    private var currentMouseEventContext: CanvasEventContext?

    private func createMouseEventContext(for location: CGPoint) -> CanvasEventContext? {
        //Canvas click
        guard let page = self.page(atCanvasPoint: location) else {
            return CanvasSelectionEventContext(originalSelection: self.selectedPages)
        }

        self.movePageToFront(page)

        //Page content click
        guard let pageComponent = page.component(at: location.minus(page.layoutFrame.origin)) else {
            return nil
        }

        switch pageComponent {
        case .titleBar, .content:
            return SelectAndMoveEventContext(page: page)
        default:
            return ResizePageEventContext(page: page, component: pageComponent)
        }
    }

    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers = [], eventCount: Int = 1) {
        self.currentMouseEventContext = self.createMouseEventContext(for: location)
        self.currentMouseEventContext?.downEvent(at: location, modifiers: modifiers, eventCount: eventCount, in: self)
        self.informOfLayoutChange(with: LayoutContext())
    }

    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers = [], eventCount: Int = 1) {
        self.currentMouseEventContext?.draggedEvent(at: location, modifiers: modifiers, eventCount: eventCount, in: self)
        self.informOfLayoutChange(with: LayoutContext())
    }

    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers = [], eventCount: Int = 1) {
        self.currentMouseEventContext?.upEvent(at: location, modifiers: modifiers, eventCount: eventCount, in: self)
        let canvasSizeContext = self.recalculateCanvasSize()
        let selectionChanged = self.hasSelectionChanged()
        let fullContext = LayoutContext(selectionChanged: selectionChanged, backgroundVisibilityChanged: selectionChanged).merged(with: canvasSizeContext)
        self.informOfLayoutChange(with: fullContext)
        self.currentMouseEventContext = nil
    }

    func moveEvent(at location: CGPoint, modifiers: LayoutEventModifiers = []) {
        self.currentlyHoveredPage = self.page(atCanvasPoint: location)
    }


    //MARK: - Hovering
    var currentlyHoveredPage: LayoutEnginePage? {
        didSet {
            guard oldValue != self.currentlyHoveredPage else {
                return
            }
            if oldValue?.selected == true {
                return
            }

            if self.currentlyHoveredPage?.selected == true {
                return
            }
            self.informOfLayoutChange(with: LayoutContext(backgroundVisibilityChanged: true))
        }
    }


    //MARK: - Manage Key Events
    private var keyEvents = [UInt16: CanvasEventContext]()

    private func keyEventContext(for keyCode: UInt16, createIfNeeded: Bool) -> CanvasEventContext? {
        if let event = self.keyEvents[keyCode] {
            return event
        }

        guard createIfNeeded else {
            return nil
        }

        let newEvent: CanvasEventContext
        if KeyboardMovePageEventContext.acceptedKeyCodes.contains(keyCode) {
            newEvent = KeyboardMovePageEventContext()
        } else if RemovePageEventContext.acceptedKeyCodes.contains(keyCode) {
            newEvent = RemovePageEventContext()
        } else {
            return nil
        }

        self.keyEvents[keyCode] = newEvent
        return newEvent
    }

    func keyDownEvent(keyCode: UInt16, modifiers: LayoutEventModifiers = [], isARepeat: Bool = false) {
        guard let event = self.keyEventContext(for: keyCode, createIfNeeded: true) else {
            return
        }

        event.keyDown(withCode: keyCode, modifiers: modifiers, isARepeat: isARepeat, in: self)
        self.informOfLayoutChange(with: LayoutContext())
    }

    func keyUpEvent(keyCode: UInt16, modifiers: LayoutEventModifiers = []) {
        //So if something else has first responder (like a text view), we'll still receive keyup even though we don't get key down
        //So we only want to fetch an existing event, not create a new one here. That way we only act if we also got the associated key down
        guard let event = self.keyEventContext(for: keyCode, createIfNeeded: false) else {
            return
        }
        event.keyUp(withCode: keyCode, modifiers: modifiers, in: self)
        self.keyEvents[keyCode] = nil
        self.informOfLayoutChange(with: LayoutContext())
    }

    //MARK: - Manage View
    func viewPortChanged() {
        //We don't care about view port changes while another event is happening
        guard self.currentMouseEventContext == nil else {
            return
        }
        self.informOfLayoutChange(with: self.recalculateCanvasSize())
    }

    private func informOfLayoutChange(with context: LayoutContext) {
        self.view?.layoutChanged(with: context)
    }
}


extension CanvasLayoutEngine {
    struct LayoutContext: Equatable {
        var sizeChanged = false
        var pageOffsetChange: CGPoint?
        var selectionChanged = false
        var backgroundVisibilityChanged = false

        func merged(with context: LayoutContext) -> LayoutContext {
            return LayoutContext(sizeChanged: self.sizeChanged || context.sizeChanged,
                                 pageOffsetChange: self.pageOffsetChange ?? context.pageOffsetChange,
                                 selectionChanged: self.selectionChanged || context.selectionChanged,
                                 backgroundVisibilityChanged: self.backgroundVisibilityChanged || context.backgroundVisibilityChanged)
        }
    }
}
