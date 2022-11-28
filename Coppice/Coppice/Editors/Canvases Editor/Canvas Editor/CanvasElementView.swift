//
//  ResizableCanvasElement.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

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

    var canvasPage: CanvasPage?

    func apply(_ layoutPage: LayoutEnginePage) {
        self.updateSubviews(with: layoutPage)
        self.updateResizeRects(with: layoutPage)
        self.updateAccessibilityResizeElements(with: layoutPage)
        self.updateMessageView(with: layoutPage.message)
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
        view.setAccessibilityLabel(NSLocalizedString("Page Content", comment: "Canvas page content view accessibility label"))
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

    private lazy var messageView: NSBox = {
        let box = NSBox()
        box.boxType = .custom
        box.borderWidth = 3
        box.cornerRadius = self.cornerSize - 2

        if let contentView = box.contentView {
            contentView.addSubview(self.messageLabel)
            NSLayoutConstraint.activate([
                self.messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 5),
                self.messageLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 5),
                contentView.bottomAnchor.constraint(greaterThanOrEqualTo: self.messageLabel.bottomAnchor, constant: 5),
                contentView.trailingAnchor.constraint(greaterThanOrEqualTo: self.messageLabel.trailingAnchor, constant: 5),
                self.messageLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                self.messageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ])
        }
        return box
    }()

    private lazy var messageLabel: NSTextField = {
        let messageLabel = NSTextField(labelWithString: "")
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = NSFont.boldSystemFont(ofSize: 15)
        messageLabel.alignment = .center
        messageLabel.lineBreakMode = .byTruncatingTail
        messageLabel.maximumNumberOfLines = 0
        return messageLabel
    }()

    private func setupSubviews() {
        self.wantsLayer = true
        self.addSubview(self.backgroundView, withInsets: self.shadowInsets)

        self.addSubview(self.titleView)
        self.addSubview(self.contentContainerShadow)
        self.addSubview(self.contentContainer)
        self.addSubview(self.messageView)
        //        self.addSubview(self.debugView)
        self.debugView.frame = self.bounds


        self.updateBackgroundVisibility(animated: false)
        self.updateMessageView(with: nil)
        self.setupAccessibility()
    }

    private let shadowInsets = NSEdgeInsets(top: 5, left: 10, bottom: 10, right: 10)

    private func updateSubviews(with layoutPage: LayoutEnginePage) {
        self.titleView.frame = layoutPage.titleBarFrame
        self.contentContainer.frame = layoutPage.contentContainerFrame
        self.contentContainerShadow.frame = layoutPage.contentContainerFrame.insetBy(dx: -1, dy: -1)
        self.disabledContentMouseStealer.frame = layoutPage.contentContainerFrame
        self.messageView.frame = layoutPage.contentContainerFrame
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

    func invertShadows() {
        let shadow = self.standardDropShadow
        shadow.shadowOffset = CGSize(width: 0, height: -shadow.shadowOffset.height)
        self.backgroundView.shadow = shadow
        self.contentContainerShadow.shadow = shadow
    }

    func restoreShadows() {
        self.backgroundView.shadow = self.standardDropShadow
        self.contentContainerShadow.shadow = self.standardDropShadow
    }


    //MARK: - Background Visibility
    private func updateBackgroundVisibility(animated: Bool) {
        let backgroundVisible = self.showBackground

        NSView.animate(withDuration: animated ? 0.3 : 0, animations: {
            self.titleView.alphaValue = (backgroundVisible ? 1 : 0)
            self.backgroundView.alphaValue = (backgroundVisible ? 1 : 0)
            self.contentContainerShadow.alphaValue = (backgroundVisible ? 0 : 1)
        }, completion: {
            self.updateAccessibility()
        })
    }


    //MARK: - Message
    private func updateMessageView(with message: LayoutEnginePage.Message?) {
        guard let message else {
            self.messageView.isHidden = true
            return
        }
        self.messageView.isHidden = false
        self.messageView.borderColor = message.color
        self.messageView.fillColor = message.color.withAlphaComponent(0.85)
        self.messageLabel.stringValue = message.message
        if message.color.contrastRatio(to: .white) >= 4.5 {
            self.messageLabel.textColor = .white
        } else {
            self.messageLabel.textColor = .black
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
            (layoutPage.rectInLayoutFrame(for: .resizeBottom), NSColor.red.withAlphaComponent(0.7)),
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
        if
            let currentEvent = NSApplication.shared.currentEvent,
            currentEvent.type == .scrollWheel,
            currentEvent.modifierFlags.contains(.option)
        {
            return hitView
        }
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


    private func setupAccessibility() {
        self.setAccessibilityElement(true)
        self.setAccessibilityRole(.group)
        self.updateAccessibility()
    }

    private func updateAccessibility() {
        var accessibilityChildren = [NSAccessibilityElementProtocol?]()
        accessibilityChildren.append(self.topLeftResizeHandleElement)
        if self.showBackground {
            accessibilityChildren = [self.titleView.closeButton, self.titleView.titleLabel]
        }
        accessibilityChildren.append(self.topRightResizeHandleElement)
        accessibilityChildren.append(self.contentContainer)

        accessibilityChildren.append(self.bottomLeftResizeHandleElement)
        accessibilityChildren.append(self.bottomRightResizeHandleElement)
		let children = accessibilityChildren.compactMap { $0 }
        self.setAccessibilityChildren(children)
		self.setAccessibilityChildrenInNavigationOrder(children)
    }

    var topLeftResizeHandleElement: MovableHandleAccessibilityElement?
    var topRightResizeHandleElement: MovableHandleAccessibilityElement?
    var bottomLeftResizeHandleElement: MovableHandleAccessibilityElement?
    var bottomRightResizeHandleElement: MovableHandleAccessibilityElement?

    private func updateAccessibilityResizeElements(with layoutPage: LayoutEnginePage) {
        guard self.window != nil else {
            return
        }
        self.updateElement(at: \.topLeftResizeHandleElement, with: layoutPage, component: .resizeTopLeft, label: NSLocalizedString("Top Left", comment: "Top Left accessibility resize handle label"))
        self.updateElement(at: \.topRightResizeHandleElement, with: layoutPage, component: .resizeTopRight, label: NSLocalizedString("Top Right", comment: "Top Right accessibility resize handle label"))
        self.updateElement(at: \.bottomRightResizeHandleElement, with: layoutPage, component: .resizeBottomRight, label: NSLocalizedString("Bottom Right", comment: "Bottom Right accessibility resize handle label"))
        self.updateElement(at: \.bottomLeftResizeHandleElement, with: layoutPage, component: .resizeBottomLeft, label: NSLocalizedString("Bottom Left", comment: "Bottom Left accessibility resize handle label"))
        self.updateAccessibility()
    }

    private func updateElement(at keyPath: ReferenceWritableKeyPath<CanvasElementView, MovableHandleAccessibilityElement?>,
                               with layoutPage: LayoutEnginePage,
                               component: LayoutEnginePageComponent,
                               label: String)
    {
        let handleElement: MovableHandleAccessibilityElement
        if let element = self[keyPath: keyPath] {
            handleElement = element
        } else {
            handleElement = self.createElement(with: layoutPage, component: component, label: label)
            self[keyPath: keyPath] = handleElement
        }

        //We need to set the frame in both parent space and in view space.
        let layoutFrame = layoutPage.rectInLayoutFrame(for: component)
        handleElement.setAccessibilityFrame(NSAccessibility.screenRect(fromView: self, rect: layoutFrame), callingDelegate: false)
    }

    private func createElement(with layoutPage: LayoutEnginePage, component: LayoutEnginePageComponent, label: String) -> MovableHandleAccessibilityElement {
        let layoutFrame = layoutPage.rectInLayoutFrame(for: component)
        let frame = NSAccessibility.screenRect(fromView: self, rect: layoutFrame)

        let element = MovableHandleAccessibilityElement.element(withRole: .handle,
                                                                frame: frame,
                                                                label: label,
                                                                parent: self) as! MovableHandleAccessibilityElement
		element.context = ResizeHandleContext(pageID: layoutPage.id, component: component)
        element.delegate = self
        return element
    }

	struct ResizeHandleContext {
		var pageID: UUID
		var component: LayoutEnginePageComponent
	}

    var customRotors: [CanvasAccessibilityRotor] = []

    override func accessibilityCustomRotors() -> [NSAccessibilityCustomRotor] {
        return self.customRotors.map(\.rotor)
    }
}

extension CanvasElementView: MovableHandleAccessibilityElementDelegate {
    func didMove(_ handle: MovableHandleAccessibilityElement, byDelta delta: CGPoint) -> CGPoint {
        guard
			let canvasView = self.canvasView,
			let resizeContext = handle.context as? ResizeHandleContext
		else {
            return .zero
        }
        return canvasView.accessibilityResize(resizeContext.component, ofPageWithID: resizeContext.pageID, by: delta)
    }
}

extension CanvasElementView: CanvasEditorItem {
    var representedObject: Any? {
        return self.canvasPage
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

