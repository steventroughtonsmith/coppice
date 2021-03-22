//
//  TourInterfaceView.swift
//  Coppice
//
//  Created by Martin Pilkington on 29/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

protocol TourInterfaceViewDelegate: AnyObject {
    func hovered(over component: TourInterfaceComponentView?, in interfaceView: TourInterfaceView)
}

class TourInterfaceView: NSView, NSAccessibilityGroup {
    weak var delegate: TourInterfaceViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupSubviews()
    }


    private let sidebarView = TourInterfaceSidebarView()
    private let toolbarView = TourInterfaceToolbarView()
    private let editorView = TourInterfaceEditorView()
    private let inspectorsView = TourInterfaceInspectorsView()

    private func setupSubviews() {
        let lineAdjust = self.sidebarView.lineWidth / 2
        var (sidebarRect, contentRect) = self.bounds.divided(atDistance: 100, from: .minXEdge)
        contentRect.origin.x -= lineAdjust
        contentRect.size.width += lineAdjust

        var (toolbarRect, mainAreaRect) = contentRect.divided(atDistance: 30, from: .maxYEdge)
        mainAreaRect.size.height += lineAdjust

        var (inspectorsRect, editorRect) = mainAreaRect.divided(atDistance: 90, from: .maxXEdge)
        editorRect.size.width += lineAdjust

        self.sidebarView.frame = sidebarRect
        self.toolbarView.frame = toolbarRect
        self.editorView.frame = editorRect
        self.inspectorsView.frame = inspectorsRect

        self.subviews = [self.sidebarView, self.toolbarView, self.editorView, self.inspectorsView]
    }


    var currentTrackingArea: NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = self.currentTrackingArea {
            self.removeTrackingArea(area)
        }

        let area = NSTrackingArea(rect: self.bounds, options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited], owner: self, userInfo: nil)
        self.addTrackingArea(area)
        self.currentTrackingArea = area
    }


    override func mouseMoved(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        if let component = self.currentComponent, component.frame.contains(point) {
            return
        }

        for view in self.subviews {
            guard
                let component = view as? TourInterfaceComponentView,
                component.frame.contains(point)
            else {
                continue
            }
            self.currentComponent = component
        }
    }

    override func mouseEntered(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        for view in self.subviews {
            guard
                let component = view as? TourInterfaceComponentView,
                component.frame.contains(point)
            else {
                continue
            }
            self.currentComponent = component
        }
    }

    override func mouseExited(with event: NSEvent) {
        self.currentComponent = nil
    }

    fileprivate var currentComponent: TourInterfaceComponentView? {
        didSet {
            oldValue?.selected = false
            if let component = self.currentComponent {
                component.selected = true
                component.removeFromSuperview()
                self.addSubview(component)
            }
            self.delegate?.hovered(over: self.currentComponent, in: self)
        }
    }

    override func accessibilityTitle() -> String? {
        return NSLocalizedString("Coppice UI Illustration", comment: "Tour UI Illustration accessibility title")
    }

    override func accessibilityHelp() -> String? {
        return NSLocalizedString("Interact with this element to learn about the main parts of Coppice's UI", comment: "Tour UI Illustration accessibility help")
    }
}





class TourInterfaceComponentView: NSView, NSAccessibilityImage {
    override var isFlipped: Bool {
        return true
    }

    var selected: Bool = false {
        didSet { self.setNeedsDisplay(self.bounds) }
    }

    let lineWidth: CGFloat = 2
    let cornerRadius: CGFloat = 8

    func setupColours() {
        if (self.selected) {
            NSColor.illustrationSelectedBackground.setFill()
            NSColor.illustrationSelectedBorder.setStroke()
        } else {
            NSColor.illustrationBackground.setFill()
            NSColor.illustrationBorder.setStroke()
        }
    }

    var componentName: String {
        return ""
    }

    var componentDescription: String {
        return ""
    }

    override func accessibilityTitle() -> String? {
        return "\(self.componentName): \(self.componentDescription)"
    }
}


private class TourInterfaceSidebarView: TourInterfaceComponentView {
    override func draw(_ dirtyRect: NSRect) {
        self.setupColours()
        let path = NSBezierPath(roundedRect: self.bounds.insetBy(dx: 0.5, dy: 0.5), topLeftRadius: self.cornerRadius, bottomLeftRadius: self.cornerRadius)
        path.lineWidth = self.lineWidth
        path.fill()
        path.stroke()
        self.drawButtons()
    }

    private func drawButtons() {
        (0...2).forEach { (index) in
            let x = self.bounds.minX + 10 + CGFloat(17 * index)
            let rect = CGRect(x: x, y: self.bounds.minY + 10, width: 10, height: 10)
            let path = NSBezierPath(ovalIn: rect)
            path.lineWidth = self.lineWidth
            path.fill()
            path.stroke()
        }
    }

    override var componentName: String {
        return NSLocalizedString("Sidebar", comment: "Welcome tour sidebar name")
    }

    override var componentDescription: String {
        return NSLocalizedString("This is where all your Pages live", comment: "Welcome tour sidebar description")
    }

    override func accessibilityIdentifier() -> String {
        return "TourGraphicSidebar"
    }
}

private class TourInterfaceToolbarView: TourInterfaceComponentView {
    override func draw(_ dirtyRect: NSRect) {
        self.setupColours()
        let path = NSBezierPath(roundedRect: self.bounds.insetBy(dx: 0.5, dy: 0.5), topRightRadius: self.cornerRadius)
        path.lineWidth = self.lineWidth
        path.fill()
        path.stroke()
    }

    override var componentName: String {
        return NSLocalizedString("Toolbar", comment: "Welcome text toolbar name")
    }

    override var componentDescription: String {
        return NSLocalizedString("You can find common actions here within easy reach", comment: "Welcome tour toolbar description")
    }

    override func accessibilityIdentifier() -> String {
        return "TourGraphicToolbar"
    }
}

private class TourInterfaceEditorView: TourInterfaceComponentView {
    override func draw(_ dirtyRect: NSRect) {
        self.setupColours()
        let path = NSBezierPath(rect: self.bounds.insetBy(dx: 0.5, dy: 0.5))
        path.lineWidth = self.lineWidth
        path.fill()
        path.stroke()
    }

    override var componentName: String {
        return NSLocalizedString("Editor", comment: "Welcome tour editor name")
    }

    override var componentDescription: String {
        return NSLocalizedString("You can edit Pages or Canvases from here", comment: "Welcome tour editor description")
    }

    override func accessibilityIdentifier() -> String {
        return "TourGraphicEditor"
    }
}

private class TourInterfaceInspectorsView: TourInterfaceComponentView {
    override func draw(_ dirtyRect: NSRect) {
        self.setupColours()
        let path = NSBezierPath(roundedRect: self.bounds.insetBy(dx: 0.5, dy: 0.5), bottomRightRadius: self.cornerRadius)
        path.lineWidth = self.lineWidth

        path.fill()
        path.stroke()
    }

    override var componentName: String {
        return NSLocalizedString("Inspectors", comment: "Welcome tour inspectors name")
    }

    override var componentDescription: String {
        return NSLocalizedString("Additional controls to edit the item selected in the editor", comment: "Welcome tour inspectors description")
    }

    override func accessibilityIdentifier() -> String {
        return "TourGraphicInspectors"
    }
}
