//
//  ResizableCanvasElement.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

extension LayoutEnginePageComponent {
    func cursor(isAtLimit: Bool = false) -> NSCursor {
        var cursorImage: NSImage? = nil
        switch (self) {
        case .resizeLeft:
            cursorImage = NSImage(named: "left-rightcursor")
        case .resizeRight:
            cursorImage = NSImage(named: "left-rightcursor")
        case .resizeTop:
            cursorImage = NSImage(named: "up-downcursor")
        case .resizeBottom:
            cursorImage = NSImage(named: "up-downcursor")
        case .resizeTopLeft:
            cursorImage = NSImage(named: "topleft-bottomrightcursor")
        case .resizeTopRight:
            cursorImage = NSImage(named: "bottomleft-toprightcursor")
        case .resizeBottomLeft:
            cursorImage = NSImage(named: "bottomleft-toprightcursor")
        case .resizeBottomRight:
            cursorImage = NSImage(named: "topleft-bottomrightcursor")
        default:
            break
        }


        guard let image = cursorImage else {
            return NSCursor.arrow
        }
        return NSCursor(image: image, hotSpot: NSPoint(x: 11, y: 11))
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

    var selected: Bool = false {
        didSet {
            guard self.selected != oldValue else {
                return
            }
            self.updateBackgroundVisibility(animated: true)
        }
    }

    var isMouseInside: Bool = false {
        didSet {
            guard self.isMouseInside != oldValue else {
                return
            }

            self.updateBackgroundVisibility(animated: true)
        }
    }

    func apply(_ layoutPage: LayoutEnginePage) {
        self.updateResizeRects(with: layoutPage)
        self.updateSubviews(with: layoutPage)
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

    private func setupSubviews() {
        self.wantsLayer = true
        self.addSubview(self.backgroundView, withInsets: self.shadowInsets)

        self.addSubview(self.titleView)
        self.addSubview(self.contentContainerShadow)
        self.addSubview(self.contentContainer)

        self.updateBackgroundVisibility(animated: false)
    }

    private let shadowInsets = NSEdgeInsets(top: 5, left: 10, bottom: 10, right: 10)



    private func updateSubviews(with layoutPage: LayoutEnginePage) {
        self.backgroundView.frame = layoutPage.visualPageFrame
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
        if self.isMouseInside || self.selected {
            return NSColor(named: "PageViewContentBorder")
        } else {
            return NSColor(named: "PageViewStroke")
        }
    }


    //MARK: - Background Visibility


    private func updateBackgroundVisibility(animated: Bool) {
        let backgroundVisible = self.isMouseInside || self.selected

        NSView.animate(withDuration: animated ? 0.3 : 0) {
            self.titleView.alphaValue = (backgroundVisible ? 1 : 0)
            self.backgroundView.alphaValue = (backgroundVisible ? 1 : 0)
            self.contentContainerShadow.alphaValue = (backgroundVisible ? 0 : 1)
//            #error("TODO")
            // Need to change layout so content view isn't inside the background but layout view
            // Need to change title view to be inside background, don't need to layout beyond setting height
            // Need to fade in/out shadow on content as border changes
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
            self.resizeRects[resizeComponent] = layoutPage.rectInLayoutFrame(for: resizeComponent)
        }
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
