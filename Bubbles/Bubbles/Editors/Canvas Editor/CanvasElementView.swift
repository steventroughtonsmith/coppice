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
        view.layer?.backgroundColor = NSColor.red.cgColor
        return view
    }()

    private lazy var backgroundView: CanvasPageBackgroundView = {
        let view = CanvasPageBackgroundView()
        return view
    }()

    private func setupSubviews() {
        self.addSubview(self.backgroundView, withInsets: self.shadowInsets)

        self.backgroundView.addSubview(self.titleView)
        self.backgroundView.addSubview(self.contentContainer)
    }

    private let shadowInsets = NSEdgeInsets(top: 5, left: 10, bottom: 10, right: 10)



    private func updateSubviews(with layoutPage: LayoutEnginePage) {
        self.backgroundView.frame = layoutPage.visualPageFrame
        self.titleView.frame = layoutPage.titleFrameInsideVisualPage
        self.contentContainer.frame = layoutPage.contentFrameInsideVisualPage
        self.disabledContentMouseStealer.frame = layoutPage.contentFrameInsideVisualPage
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
        if (hitView == self.titleView || hitView == self.titleView || hitView == self.backgroundView || hitView == self.disabledContentMouseStealer) {
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
