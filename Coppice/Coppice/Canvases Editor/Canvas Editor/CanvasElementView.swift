//
//  ResizableCanvasElement.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

extension LayoutEnginePageComponent {
    static let horizontalResizeCursor = NSCursor(image: NSImage(named: "left-rightcursor")!, hotSpot: CGPoint(x: 11, y: 11))
    static let verticalResizeCursor = NSCursor(image: NSImage(named: "up-downcursor")!, hotSpot: CGPoint(x: 11, y: 11))
    static let topLeftDiagonalResizeCursor = NSCursor(image: NSImage(named: "topleft-bottomrightcursor")!, hotSpot: CGPoint(x: 11, y: 11))
    static let bottomLeftDiagonalResizeCursor = NSCursor(image: NSImage(named: "bottomleft-toprightcursor")!, hotSpot: CGPoint(x: 11, y: 11))

    func cursor(isAtLimit: Bool = false) -> NSCursor {
        switch (self) {
        case .resizeLeft, .resizeRight:
            return LayoutEnginePageComponent.horizontalResizeCursor
        case .resizeTop, .resizeBottom:
            return LayoutEnginePageComponent.verticalResizeCursor
        case .resizeTopLeft, .resizeBottomRight:
            return LayoutEnginePageComponent.topLeftDiagonalResizeCursor
        case .resizeTopRight, .resizeBottomLeft:
            return LayoutEnginePageComponent.bottomLeftDiagonalResizeCursor
        default:
            break
        }

        return NSCursor.arrow
    }
}

class CanvasElementView: NSView  {
    let cornerSize: CGFloat = 8
    let edgeSize: CGFloat = 5

    private lazy var disabledContentMouseStealer = NSView()

    override var isFlipped: Bool {
        return true
    }

    var enabled: Bool = true {
        didSet {
            self.updateMouseStealerVisibility()
        }
    }

    var selected: Bool = false

    var active: Bool {
        get { return self.backgroundView.active }
        set { self.backgroundView.active = newValue }
    }

    var showBackground: Bool = false {
        didSet {
            self.updateBackgroundVisibility(animated: true)
        }
    }

    var drawsShadow: Bool = true {
        didSet {
            self.contentContainerShadow.shadow = self.drawsShadow ? self.standardDropShadow : nil
            self.backgroundView.shadow = self.drawsShadow ? self.standardDropShadow : nil
        }
    }

    func apply(_ layoutPage: LayoutEnginePage) {
        self.updateSubviews(with: layoutPage)
        self.updateResizeRects(with: layoutPage)
        self.showBackground = layoutPage.showBackground
        self.titleView.enabled = layoutPage.showBackground
        self.backgroundView.selected = layoutPage.selected
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupSubviews()
    }


    //MARK: - Subviews
    lazy var titleView: CanvasPageTitleView = {
        let view = CanvasPageTitleView()
        return view
    }()

    lazy var contentContainer: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 5
        view.layer?.masksToBounds = true
        return view
    }()

    lazy var contentContainerShadow: NSView = {
        let view = ShadowView()
        view.wantsLayer = true
        view.shadow = self.standardDropShadow
        return view
    }()

    private lazy var backgroundView: CanvasPageBackgroundView = {
        let view = CanvasPageBackgroundView()
        view.wantsLayer = true
        view.shadow = self.standardDropShadow
        return view
    }()

    private lazy var debugView: RectDrawingView = {
        let view = RectDrawingView()
        view.autoresizingMask = [.height, .width]
        return view
    }()

    private func setupSubviews() {
        self.wantsLayer = true
        self.addSubview(self.backgroundView, withInsets: self.shadowInsets)

        self.addSubview(self.titleView)
        self.addSubview(self.contentContainerShadow)
        self.addSubview(self.contentContainer)
        //        self.addSubview(self.debugView)
        self.debugView.frame = self.bounds
        

        self.updateBackgroundVisibility(animated: false)
    }

    private let shadowInsets = NSEdgeInsets(top: 5, left: 10, bottom: 10, right: 10)


    private func updateSubviews(with layoutPage: LayoutEnginePage) {
        self.titleView.frame = layoutPage.titleBarFrame
        self.contentContainer.frame = layoutPage.contentContainerFrame
        self.contentContainerShadow.frame = layoutPage.contentContainerFrame.insetBy(dx: -1, dy: -1)
        self.disabledContentMouseStealer.frame = layoutPage.contentContainerFrame
    }


    override func updateLayer() {
        super.updateLayer()
        self.contentContainer.layer?.borderColor = self.contentContainerBorderColor?.cgColor
        self.backgroundView.shadow?.shadowColor = NSColor(named: "PageShadowColour")
    }

    private var standardDropShadow: NSShadow {
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = CGSize(width: 0, height: 3)
        return shadow
    }

    private var contentContainerBorderColor: NSColor? {
        if self.showBackground || self.selected {
            return NSColor(named: "PageViewContentBorder")
        } else {
            return NSColor(named: "PageViewStroke")
        }
    }


    //MARK: - Background Visibility


    private func updateBackgroundVisibility(animated: Bool) {
        let backgroundVisible = self.showBackground

        NSView.animate(withDuration: animated ? 0.3 : 0) {
            self.titleView.alphaValue = (backgroundVisible ? 1 : 0)
            self.backgroundView.alphaValue = (backgroundVisible ? 1 : 0)
            self.contentContainerShadow.alphaValue = (backgroundVisible ? 0 : 1)
        }
    }


    //MARK: - Mouse Stealer
    private func updateMouseStealerVisibility() {
        if (self.enabled) {
            self.disabledContentMouseStealer.removeFromSuperview()
        } else {
            self.addSubview(self.disabledContentMouseStealer)
        }
    }


    //MARK: - Resize Rects
    private var resizeRects = [LayoutEnginePageComponent: CGRect]()
    private func updateResizeRects(with layoutPage: LayoutEnginePage) {
        self.resizeRects.removeAll()
        for resizeComponent in LayoutEnginePageComponent.allCases {
            guard resizeComponent != .titleBar && resizeComponent != .content else {
                continue
            }
            let resizeRect = layoutPage.rectInLayoutFrame(for: resizeComponent)
            if resizeRect != .zero {
                self.resizeRects[resizeComponent] = resizeRect
            }
        }

        self.debugView.rects = [
            (layoutPage.rectInLayoutFrame(for: .resizeLeft), NSColor.blue.withAlphaComponent(0.7)),
            (layoutPage.rectInLayoutFrame(for: .resizeRight), NSColor.yellow.withAlphaComponent(0.7)),
            (layoutPage.rectInLayoutFrame(for: .resizeTop), NSColor.green.withAlphaComponent(0.7)),
            (layoutPage.rectInLayoutFrame(for: .resizeBottom), NSColor.red.withAlphaComponent(0.7))
        ]
    }

    private func isPointInResizeRect(_ point: CGPoint) -> Bool {
        for (_, rect) in self.resizeRects {
            if (rect.contains(point)) {
                return true
            }
        }
        return false
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let pointInBounds = self.convert(point, from: self.superview)
        guard self.bounds.contains(pointInBounds) else {
            return nil
        }
        if self.isPointInResizeRect(pointInBounds) {
            return self
        }
        let hitView = super.hitTest(point)
        if (hitView == self.titleView || hitView == self.contentContainer || hitView == self.backgroundView || hitView == self.disabledContentMouseStealer) {
            return self
        }
        return hitView
    }

    override func mouseDown(with event: NSEvent) {
        self.canvasView?.mouseDown(with: event)
    }


    //MARK: - Cursor Handling
    func cursor(for point: CGPoint) -> NSCursor? {
        let cursorRects = self.resizeRects + [(.titleBar, self.titleView.frame)]
        for (type, rect) in cursorRects {
            if (rect.contains(point)) {
                return type.cursor()
            }
        }
        if !self.enabled {
            return NSCursor.arrow
        }
        return nil
    }
}


class ShadowView: NSView {
    override var isFlipped: Bool {
        return true
    }
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: self.bounds, xRadius: 5, yRadius: 5)
        NSColor(named: "PageViewStroke")?.set()
        path.fill()
    }
}
