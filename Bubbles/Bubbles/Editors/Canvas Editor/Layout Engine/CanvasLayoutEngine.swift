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

    @discardableResult func addPage(withID id: UUID,
                                    contentFrame: CGRect,
                                    minimumContentSize: CGSize = GlobalConstants.minimumPageSize,
                                    titleBarAppearsOverContent: Bool = false,
                                    parentID: UUID? = nil) -> LayoutEnginePage {

        let page = LayoutEnginePage(id: id,
                                    contentFrame: contentFrame,
                                    minimumContentSize: minimumContentSize,
                                    titleBarAppearsOverContent: titleBarAppearsOverContent,
                                    parentID: parentID,
                                    layoutEngine: self)
        self.pages.append(page)
        self.pagesByUUID[id] = page
        self.informOfLayoutChange(with: self.recalculateCanvasSize())
        return page
    }

    func remove(_ pages: [LayoutEnginePage]) {
        self.pages = self.pages.filter { !pages.contains($0) }
        for page in pages {
            self.pagesByUUID.removeValue(forKey: page.id)
        }
        self.informOfLayoutChange(with: self.recalculateCanvasSize())
    }

    func updateContentFrame(_ frame: CGRect, titleBarAppearsOverContent: Bool = false, ofPageWithID uuid: UUID) {
        guard let page = self.pagesByUUID[uuid] else {
            return
        }
        guard page.contentFrame != frame else {
            return
        }
        page.titleBarAppearsOverContent = titleBarAppearsOverContent
        page.contentFrame = frame
        self.informOfLayoutChange(with: self.recalculateCanvasSize())
    }


    //MARK: - Retrieving Pages
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

    func allChildren(of rootPage: LayoutEnginePage) -> [LayoutEnginePage] {
        var pages = [LayoutEnginePage]()
        for page in self.pages {
            if rootPage.id == page.parentID {
                pages.append(page)
                pages.append(contentsOf: self.allChildren(of: page))
            }
        }
        return pages
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
        var arrows = [LayoutEngineArrow]()
        for page in self.pages {
            guard let parentID = page.parentID,
                let parent = self.pagesByUUID[parentID] else {
                continue
            }
            arrows.append(self.calculateArrowBetween(parent: parent, andChild: page))
        }

        self.arrows = arrows
    }

    private func calculateArrowBetween(parent: LayoutEnginePage, andChild child: LayoutEnginePage) -> LayoutEngineArrow {
        let arrowWidth = self.configuration.arrowWidth
        assert((Int(arrowWidth) % 2) == 1, "Arrow width should be an odd number!")
        let arrowOffset = (arrowWidth - 1) / 2

        let parentFrame = parent.layoutFrame
        let childFrame = child.layoutFrame

        let x: CGFloat
        let width: CGFloat
        let horizontalDirection: LayoutEngineArrow.Direction
        if (childFrame.midX > parentFrame.midX) {
            x = parentFrame.midX
            width = childFrame.midX - parentFrame.midX
            horizontalDirection = .maxEdge
        } else {
            x = childFrame.midX
            width = max(parentFrame.midX - childFrame.midX, 1) //ensure a minimum width of 1
            horizontalDirection = .minEdge
        }

        let y: CGFloat
        let height: CGFloat
        let verticalDirection: LayoutEngineArrow.Direction
        if (childFrame.midY > parentFrame.midY) {
            y = parentFrame.midY
            height = childFrame.midY - parentFrame.midY
            verticalDirection = .maxEdge
        } else {
            y = childFrame.midY
            height = max(parentFrame.midY - childFrame.midY, 1) //ensure a minimum height of 1
            verticalDirection = .minEdge
        }

        let frame = CGRect(x: x, y: y, width: width, height: height)
        let offsetFrame = frame.insetBy(dx: -arrowOffset, dy: -arrowOffset)

        return LayoutEngineArrow(parentID: parent.id,
                                 childID: child.id,
                                 frame: offsetFrame,
                                 horizontalDirection: horizontalDirection,
                                 verticalDirection: verticalDirection)
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
        let fullContext = LayoutContext(selectionChanged: self.hasSelectionChanged()).merged(with: canvasSizeContext)
        self.informOfLayoutChange(with: fullContext)
        self.currentMouseEventContext = nil
    }


    //MARK: - Manage Key Events
    private var keyEvents = [UInt16: CanvasEventContext]()

    private func keyEventContext(for keyCode: UInt16) -> CanvasEventContext? {
        if let event = self.keyEvents[keyCode] {
            return event
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
        guard let event = self.keyEventContext(for: keyCode) else {
            return
        }

        event.keyDown(withCode: keyCode, modifiers: modifiers, isARepeat: isARepeat, in: self)
        self.informOfLayoutChange(with: LayoutContext())
    }

    func keyUpEvent(keyCode: UInt16, modifiers: LayoutEventModifiers = []) {
        guard let event = self.keyEventContext(for: keyCode) else {
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

        func merged(with context: LayoutContext) -> LayoutContext {
            return LayoutContext(sizeChanged: self.sizeChanged || context.sizeChanged,
                                 pageOffsetChange: self.pageOffsetChange ?? context.pageOffsetChange,
                                 selectionChanged: self.selectionChanged || context.selectionChanged)
        }
    }

    struct Configuration {
        let pageTitleHeight: CGFloat
        let pageResizeEdgeHandleSize: CGFloat
        let pageResizeCornerHandleSize: CGFloat
        let pageResizeHandleOffset: CGFloat

        let contentBorder: CGFloat

        //Must be odd number
        let arrowWidth: CGFloat


        /// The margins from around the content to get to the layout
        var layoutFrameOffsetFromContent: LayoutMargins {
            return LayoutMargins(left: self.pageResizeHandleOffset,
                                 top: self.pageResizeHandleOffset + self.pageTitleHeight,
                                 right: self.pageResizeHandleOffset,
                                 bottom: self.pageResizeHandleOffset)
        }
        struct LayoutFrameOptions: OptionSet {
            let rawValue: Int

            static let includeTitleBar = LayoutFrameOptions(rawValue: 1 << 1)
        }

        func layoutFrameOffsetFromContent(options: LayoutFrameOptions) -> LayoutMargins {
            var top = self.pageResizeHandleOffset
            if options.contains(.includeTitleBar) {
                top += self.pageTitleHeight
            }

            return LayoutMargins(left: self.pageResizeHandleOffset,
                                 top: top,
                                 right: self.pageResizeHandleOffset,
                                 bottom: self.pageResizeHandleOffset)
        }

        /// The margins inside the layoutFrame to get the visible frame
        var visibleFrameInset: LayoutMargins {
            return LayoutMargins(left: self.pageResizeHandleOffset, top: self.pageResizeHandleOffset, right: self.pageResizeHandleOffset, bottom: self.pageResizeHandleOffset)
        }

    }

    struct LayoutMargins: Equatable {
        let left: CGFloat
        let top: CGFloat
        let right: CGFloat
        let bottom: CGFloat

        static let zero = LayoutMargins(left: 0, top: 0, right: 0, bottom: 0)
    }
}

extension CGRect {
    func grow(by layoutMargins: CanvasLayoutEngine.LayoutMargins) -> CGRect {
        return CGRect(x: (self.origin.x - layoutMargins.left),
                      y: (self.origin.y - layoutMargins.top),
                      width: (self.size.width + layoutMargins.left + layoutMargins.right),
                      height: (self.size.height + layoutMargins.top + layoutMargins.bottom))
    }

    func shrink(by layoutMargins: CanvasLayoutEngine.LayoutMargins) -> CGRect {
        return CGRect(x: (self.origin.x + layoutMargins.left),
                      y: (self.origin.y + layoutMargins.top),
                      width: (self.size.width - layoutMargins.left - layoutMargins.right),
                      height: (self.size.height - layoutMargins.top - layoutMargins.bottom))
    }
}
