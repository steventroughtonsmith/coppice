//
//  CanvasLayoutEngine.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 31/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import Foundation

public struct LayoutEventModifiers: OptionSet {
    public let rawValue: UInt

    public static let shift = LayoutEventModifiers(rawValue: 1 << 0)
    public static let control = LayoutEventModifiers(rawValue: 1 << 1)
    public static let option = LayoutEventModifiers(rawValue: 1 << 2)
    public static let command = LayoutEventModifiers(rawValue: 1 << 3)

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}


public protocol CanvasLayoutView: AnyObject {
    func layoutChanged(with context: CanvasLayoutEngine.LayoutContext)
    var viewPortFrame: CGRect { get }
}


public protocol CanvasLayoutEngineDelegate: AnyObject {
    func moved(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine)
    func remove(items: [LayoutEngineItem], from layout: CanvasLayoutEngine)
    func reordered(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine)
    func finishLinking(withDestination: LayoutEnginePage?, in layout: CanvasLayoutEngine)
}



public class CanvasLayoutEngine: NSObject, LayoutEngine {
    public weak var view: CanvasLayoutView?
    public weak var delegate: CanvasLayoutEngineDelegate?

    public var editable = true

    public let configuration: Configuration
    public let eventContextFactory: LayoutEngineEventContextFactory
    public init(configuration: Configuration, eventContextFactory: LayoutEngineEventContextFactory = CanvasLayoutEngineEventContextFactory()) {
        self.configuration = configuration
        self.eventContextFactory = eventContextFactory
    }

    //MARK: - Manage Canvas
    public private(set) var canvasSize: CGSize = .zero
    private var pageSpaceOffset: CGPoint = .zero

    public func convertPointToPageSpace(_ point: CGPoint) -> CGPoint {
        return point.minus(self.pageSpaceOffset)
    }

    public func convertPointToCanvasSpace(_ point: CGPoint) -> CGPoint {
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

        self.linkLayoutEngine.updateLinks(forOffsetChange: offsetChange)

        let canvasChanged = (self.canvasSize != contentFrame.size)
        self.canvasSize = contentFrame.size

        return LayoutContext(sizeChanged: canvasChanged, pageOffsetChange: offsetChange, linksChanged: (offsetChange != .zero))
    }


    //MARK: - Manage Pages
    public private(set) var pages = [LayoutEnginePage]()
    private var pagesByUUID = [UUID: LayoutEnginePage]()

    public func add(_ pages: [LayoutEnginePage]) {
        guard pages.count > 0 else {
            return
        }
        for page in pages {
            guard self.pagesByUUID[page.id] == nil else {
                assertionFailure("Adding a page to the layout engine twice: \(page.id)")
                continue
            }
            page.canvasLayoutEngine = self
            self.pages.append(page)
            self.pagesByUUID[page.id] = page
        }

        self.updateZIndexes()
        self.linkLayoutEngine.updateLinks(forModifiedPages: pages)

        self.informOfLayoutChange(with: self.recalculateCanvasSize())
    }

    public func remove(_ pages: [LayoutEnginePage]) {
        guard pages.count > 0 else {
            return
        }
        self.pages = self.pages.filter { !pages.contains($0) }
        for page in pages {
            page.parent?.removeChild(page)
            self.pagesByUUID.removeValue(forKey: page.id)
        }
        self.updateZIndexes()
        self.informOfLayoutChange(with: self.recalculateCanvasSize())
    }

    public func updateContentFrame(_ frame: CGRect, ofPageWithID uuid: UUID) {
        guard let page = self.pagesByUUID[uuid] else {
            return
        }
        guard page.contentFrame != frame else {
            return
        }
        page.contentFrame = frame
        self.linkLayoutEngine.updateLinks(forModifiedPages: [page])
        self.informOfLayoutChange(with: self.recalculateCanvasSize())
    }

    public func normaliseFrames(of pages: [LayoutEnginePage]) {
        for page in pages {
            page.layoutFrame = page.layoutFrame.rounded()
        }
    }

    public var cursorPage: LayoutEnginePage?

    //MARK: - Retrieving Pages
    public func page(withID uuid: UUID) -> LayoutEnginePage? {
        if self.cursorPage?.id == uuid {
            return self.cursorPage
        }
        return self.pagesByUUID[uuid]
    }

    public func item(atCanvasPoint canvasPoint: CGPoint) -> LayoutEngineItem? {
        for page in self.pages.reversed() {
            if page.layoutFrame.contains(canvasPoint) {
                return page
            }
        }
        for link in self.links where link.layoutFrame.contains(canvasPoint) {
            let convertedPoint = canvasPoint.minus(link.layoutFrame.origin)
            if link.interactionPath.contains(convertedPoint) {
                return link
            }
        }
        return nil
    }

    public func items(inCanvasRect canvasRect: CGRect) -> [LayoutEngineItem] {
        var itemsInRect = [LayoutEngineItem]()
        for page in self.pages where page.layoutFrame.intersects(canvasRect) {
            itemsInRect.append(page)
        }
        for link in self.links where link.layoutFrame.intersects(canvasRect) {
            let canvasRectPath = NSBezierPath(rect: canvasRect.offsetBy(dx: -link.layoutFrame.origin.x, dy: -link.layoutFrame.origin.y))
            if link.interactionPath.intersects(with: canvasRectPath) {
                itemsInRect.append(link)
            }
        }
        return itemsInRect
    }

    public func modified(_ items: [LayoutEngineItem]) {
        let pages = items.pages
        if pages.count > 0 {
            self.linkLayoutEngine.updateLinks(forModifiedPages: pages)
        }
    }

    public func finishedModifying(_ items: [LayoutEngineItem]) {
        let pages = items.pages
        if pages.count > 0 {
            self.updateEnabledPage()
            self.normaliseFrames(of: pages)
            self.delegate?.moved(pages: pages, in: self)
        }
    }

    public func tellDelegateToRemove(_ items: [LayoutEngineItem]) {
        self.delegate?.remove(items: items, from: self)
    }


    //MARK: - Page Ordering

    public func movePageToFront(_ page: LayoutEnginePage) {
        guard let index = self.pages.firstIndex(of: page) else {
            return // Page doesn't exist
        }

        self.pages.remove(at: index)
        self.pages.append(page)
        self.updateZIndexes()
    }

    private func updateZIndexes() {
        var modifiedPages = [LayoutEnginePage]()
        for (index, page) in self.pages.enumerated() {
            guard page.zIndex != index else {
                continue
            }
            page.zIndex = index
            modifiedPages.append(page)
        }
        self.delegate?.reordered(pages: modifiedPages, in: self)
    }


    //MARK: - Selection
    public var selectedItems: [LayoutEngineItem] {
        var items: [LayoutEngineItem] = self.pages.filter(\.selected)
        items.append(contentsOf: self.links.filter(\.selected))
        return items
    }

    public var selectionRect: CGRect?

    public func selectAll() {
        self.select(self.pages, extendingSelection: true)
    }

    public func deselectAll() {
        self.deselect(self.selectedItems)
    }

    public func select(_ pages: [LayoutEngineItem], extendingSelection: Bool = false) {
        if extendingSelection {
            pages.forEach { $0.selected = true }
        } else {
            self.selectedItems.forEach { $0.selected = false }
            pages.forEach { $0.selected = true }
        }
        self.notifyOfSelectionUpdatedIfNeeded()
    }

    public func deselect(_ pages: [LayoutEngineItem]) {
        pages.forEach { $0.selected = false }
        self.notifyOfSelectionUpdatedIfNeeded()
    }

    private var notifyOfSelectionUpdate = true
    public func groupSelectionChange(_ block: () -> Void) {
        self.notifyOfSelectionUpdate = false
        block()
        self.notifyOfSelectionUpdate = true
        self.notifyOfSelectionUpdatedIfNeeded()
    }

    private func notifyOfSelectionUpdatedIfNeeded() {
        guard self.notifyOfSelectionUpdate else {
            return
        }
        self.updateEnabledPage()
        self.informOfLayoutChange(with: LayoutContext(selectionChanged: true))
    }

    private var previousSelectionIDs = Set<UUID>()
    private func hasSelectionChanged() -> Bool {
        let newSelectionIDs = Set(self.selectedItems.map { $0.id })
        let selectionChanged = (self.previousSelectionIDs != newSelectionIDs)
        self.previousSelectionIDs = newSelectionIDs
        return selectionChanged
    }

    //MARK: - Editability
    public weak var enabledPage: LayoutEnginePage?
    private func updateEnabledPage() {
        guard self.editable, self.selectedItems.pages.count == 1, let page = self.selectedItems.firstPage else {
            self.enabledPage = nil
            return
        }
        self.enabledPage = page
    }

    public private(set) var pageBeingEdited: LayoutEnginePage? {
        didSet {
            guard self.pageBeingEdited != oldValue else {
                return
            }
            oldValue?.isEditing = false
            self.pageBeingEdited?.isEditing = true
        }
    }

    public func startEditing(_ page: LayoutEnginePage, atContentPoint point: CGPoint) {
        if let currentPage = self.pageBeingEdited, (currentPage != page) {
            currentPage.view?.stopEditing()
        }
        self.pageBeingEdited = page
        page.view?.startEditing(atContentPoint: point)
    }

    public func stopEditingPages() {
        guard let page = self.pageBeingEdited else {
            return
        }
        page.view?.stopEditing()
        self.pageBeingEdited = nil
    }


    //MARK: - Manage Links
    public var links: [LayoutEngineLink] {
        return self.linkLayoutEngine.links
    }

    public func linkBetween(source: LayoutEnginePage, andDestination destination: LayoutEnginePage) -> LayoutEngineLink? {
        return self.links.first(where: { ($0.sourcePageID == source.id) && ($0.destinationPageID == destination.id) })
    }

    private lazy var linkLayoutEngine: LinkLayoutEngine = {
        let engine = LinkLayoutEngine()
        engine.canvasLayoutEngine = self
        return engine
    }()

    public func add(_ links: [LayoutEngineLink]) {
        self.linkLayoutEngine.add(links)
    }

    public func remove(_ links: [LayoutEngineLink]) {
        self.linkLayoutEngine.remove(links)
    }

    public func linksChanged() {
        self.informOfLayoutChange(with: LayoutContext(linksChanged: true))
    }

    //MARK: - Link Creation

    public var isLinking: Bool {
        return self.currentHoverEventContext is CreateLinkHoverEventContext
    }

    public func startLinking() {
        guard let editingPage = self.pageBeingEdited else {
            return
        }

        self.currentHoverEventContext = CreateLinkHoverEventContext(page: editingPage)
    }

    public func finishLinking(withDestination page: LayoutEnginePage?) {
        self.delegate?.finishLinking(withDestination: page, in: self)
        self.currentHoverEventContext = StandardHoverEventContext()
    }


    //MARK: - Manage Mouse Events
    private var currentMouseEventContext: CanvasMouseEventContext?

    public func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers = [], eventCount: Int = 1) {
        self.currentMouseEventContext = self.eventContextFactory.createMouseEventContext(for: location, in: self)
        self.currentMouseEventContext?.downEvent(at: location, modifiers: modifiers, eventCount: eventCount, in: self)
        self.informOfLayoutChange(with: LayoutContext())
    }

    public func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers = [], eventCount: Int = 1) {
        self.currentMouseEventContext?.draggedEvent(at: location, modifiers: modifiers, eventCount: eventCount, in: self)
        self.informOfLayoutChange(with: LayoutContext())
    }

    public func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers = [], eventCount: Int = 1) {
        self.currentMouseEventContext?.upEvent(at: location, modifiers: modifiers, eventCount: eventCount, in: self)
        let canvasSizeContext = self.recalculateCanvasSize()
        let selectionChanged = self.hasSelectionChanged()
        let fullContext = LayoutContext(selectionChanged: selectionChanged, backgroundVisibilityChanged: selectionChanged).merged(with: canvasSizeContext)
        self.informOfLayoutChange(with: fullContext)
        self.currentMouseEventContext = nil
    }


    //MARK: - Manage Hover Events
    public var pageUnderMouse: LayoutEnginePage? {
        didSet {
            guard oldValue != self.pageUnderMouse else {
                return
            }

            if (oldValue?.selected == true) || (self.pageUnderMouse?.selected == true) {
                return
            }
            self.informOfLayoutChange(with: LayoutContext(backgroundVisibilityChanged: true))
        }
    }

    private(set) var currentHoverEventContext: CanvasHoverEventContext = StandardHoverEventContext() {
        didSet {
            guard self.currentHoverEventContext !== oldValue else {
                return
            }
            oldValue.cleanUp(in: self)
        }
    }

    public func moveEvent(at location: CGPoint, modifiers: LayoutEventModifiers = []) {
        self.currentHoverEventContext.cursorMoved(to: location, modifiers: modifiers, in: self)
    }

    //MARK: - Manage Key Events
    private var keyEvents = [UInt16: CanvasKeyEventContext]()

    public func keyDownEvent(keyCode: UInt16, modifiers: LayoutEventModifiers = [], isARepeat: Bool = false) {
        //We store per code as we may get repeats and we only want to create the event on the first key down
        guard let event = self.keyEvents[keyCode] ?? self.eventContextFactory.createKeyEventContext(for: keyCode, in: self) else {
            return
        }

        self.keyEvents[keyCode] = event
        event.keyDown(withCode: keyCode, modifiers: modifiers, isARepeat: isARepeat, in: self)
        self.informOfLayoutChange(with: LayoutContext())
    }

    public func keyUpEvent(keyCode: UInt16, modifiers: LayoutEventModifiers = []) {
        //So if something else has first responder (like a text view), we'll still receive keyup even though we don't get key down
        //So we only want to fetch an existing event, not create a new one here. That way we only act if we also got the associated key down
        guard let event = self.keyEvents[keyCode] else {
            return
        }
        event.keyUp(withCode: keyCode, modifiers: modifiers, in: self)
        self.keyEvents[keyCode] = nil
        self.informOfLayoutChange(with: LayoutContext())
    }


    //MARK: - Accessibility Event
    public func accessibilityResize(_ component: LayoutEnginePageComponent, of page: LayoutEnginePage, by delta: CGPoint) -> CGPoint {
        let event = ResizePageEventContext(page: page, component: component)
        let finalDelta = event.resize(withDelta: delta, in: self)
        self.finishedModifying([page])
        self.informOfLayoutChange(with: LayoutContext())
        return finalDelta
    }


    //MARK: - Manage View
    public func viewPortChanged() {
        //We don't care about view port changes while another event is happening
        guard self.currentMouseEventContext == nil else {
            return
        }
        self.informOfLayoutChange(with: self.recalculateCanvasSize())
    }

    private func informOfLayoutChange(with context: LayoutContext) {
        self.view?.layoutChanged(with: context)
    }

    //MARK: - Appearance
    public var alwaysShowPageTitles: Bool = false {
        didSet {
            guard self.alwaysShowPageTitles != oldValue else {
                return
            }
            self.informOfLayoutChange(with: LayoutContext(backgroundVisibilityChanged: true))
        }
    }
}


extension CanvasLayoutEngine {
    public struct LayoutContext: Equatable {
        public var sizeChanged = false
        public var pageOffsetChange: CGPoint?
        public var selectionChanged = false
        public var backgroundVisibilityChanged = false
        public var linksChanged = false

        public func merged(with context: LayoutContext) -> LayoutContext {
            return LayoutContext(sizeChanged: self.sizeChanged || context.sizeChanged,
                                 pageOffsetChange: self.pageOffsetChange ?? context.pageOffsetChange,
                                 selectionChanged: self.selectionChanged || context.selectionChanged,
                                 backgroundVisibilityChanged: self.backgroundVisibilityChanged || context.backgroundVisibilityChanged,
                                 linksChanged: self.linksChanged || context.linksChanged)
        }

        public init(sizeChanged: Bool = false, pageOffsetChange: CGPoint? = nil, selectionChanged: Bool = false, backgroundVisibilityChanged: Bool = false, linksChanged: Bool = false) {
            self.sizeChanged = sizeChanged
            self.pageOffsetChange = pageOffsetChange
            self.selectionChanged = selectionChanged
            self.backgroundVisibilityChanged = backgroundVisibilityChanged
            self.linksChanged = linksChanged
        }
    }
}
