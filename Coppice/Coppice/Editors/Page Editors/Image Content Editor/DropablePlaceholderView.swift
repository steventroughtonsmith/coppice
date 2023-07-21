//
//  ImageEditorPlaceHolderView.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

protocol DropablePlaceholderViewDelegate: AnyObject {
    func placeholderView(shouldAcceptDropOf pasteboardItems: [NSPasteboardItem]) -> Bool
    func placeholderView(didAcceptDropOf pasteboardItems: [NSPasteboardItem]) -> Bool
}

class DropablePlaceholderView: NSView {
    weak var delegate: DropablePlaceholderViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        self.addSubview(self.textField)
        self.textField.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.textField.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.textField.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.5).isActive = true
        self.textField.textColor = self.colour
        self.textField.stringValue = self.text
    }


    //MARK: - Drawing
    @IBInspectable var colour: NSColor = NSColor(white: 0.5, alpha: 1)

    private var highlight: Bool = false {
        didSet {
            self.setNeedsDisplay(self.bounds)
            self.textField.textColor = self.drawingColour
        }
    }

    private var drawingColour: NSColor {
        if self.highlight {
            return NSColor.controlAccentColor
        }
        return self.colour.withAlphaComponent(0.75)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        self.drawingColour.set()
        let bounds = self.bounds.insetBy(dx: 2, dy: 2)
        guard bounds.size != .zero else {
            return
        }

        self.drawCorner(in: bounds, xEdge: .min, yEdge: .max, size: 10) //Top-left
        self.drawCorner(in: bounds, xEdge: .max, yEdge: .max, size: 10) //Top-right
        self.drawCorner(in: bounds, xEdge: .max, yEdge: .min, size: 10) //Bottom-right
        self.drawCorner(in: bounds, xEdge: .min, yEdge: .min, size: 10) //Bottom-left

        self.drawDashedLine(between: bounds.point(atX: .min, y: .max).plus(x: 10, y: 0),
                            and: bounds.point(atX: .max, y: .max).plus(x: -10, y: 0)) //Top
        self.drawDashedLine(between: bounds.point(atX: .max, y: .max).plus(x: 0, y: -10),
                            and: bounds.point(atX: .max, y: .min).plus(x: 0, y: 10)) //Right
        self.drawDashedLine(between: bounds.point(atX: .max, y: .min).plus(x: -10, y: 0),
                            and: bounds.point(atX: .min, y: .min).plus(x: 10, y: 0)) //Bottom
        self.drawDashedLine(between: bounds.point(atX: .min, y: .min).plus(x: 0, y: 10),
                            and: bounds.point(atX: .min, y: .max).plus(x: 0, y: -10)) //Left
    }


    private func drawCorner(in bounds: CGRect, xEdge: CGRect.RectPoint, yEdge: CGRect.RectPoint, size: CGFloat) {
        let cornerPath = NSBezierPath()
        let cornerPoint = bounds.point(atX: xEdge, y: yEdge)
        cornerPath.move(to: cornerPoint.plus(x: 0, y: (yEdge == .min) ? size : -size))
        cornerPath.curve(to: cornerPoint.plus(x: (xEdge == .min) ? size : -size, y: 0),
                         controlPoint1: cornerPoint.plus(x: 0, y: (yEdge == .min) ? (size * 0.25) : -(size * 0.25)),
                         controlPoint2: cornerPoint.plus(x: (xEdge == .min) ? (size * 0.25) : -(size * 0.25), y: 0))
        cornerPath.lineWidth = 4
        cornerPath.stroke()
    }

    private func drawDashedLine(between firstPoint: CGPoint, and secondPoint: CGPoint) {
        let path = NSBezierPath()
        path.move(to: firstPoint)
        path.line(to: secondPoint)
        path.lineWidth = 4

        let steps: [CGFloat] = [10.0, 10.0]
        path.setLineDash(steps, count: 2, phase: 10.0)
        path.stroke()
    }

    //MARK: - Text
    @IBInspectable var text: String = "" {
        didSet {
            guard self.text != oldValue else {
                return
            }
            self.setAccessibilityTitle(self.text)
            self.textField.stringValue = self.text
        }
    }

    private let textField: NSTextField = {
        let textField = NSTextField(labelWithString: "")
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = NSFont.boldSystemFont(ofSize: 20)
        textField.maximumNumberOfLines = 3
        textField.lineBreakMode = .byWordWrapping
        textField.alignment = .center
        return textField
    }()


    //MARK: - Dropability
    var acceptedTypes: [NSPasteboard.PasteboardType] = [] {
        didSet {
            self.unregisterDraggedTypes()
            self.registerForDraggedTypes(self.acceptedTypes)
        }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let dragOperation = self.draggingUpdated(sender)
        if dragOperation != [] {
            self.highlight = true
        }
        return dragOperation
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard
            sender.draggingPasteboard.availableType(from: self.acceptedTypes) != nil,
            let items = sender.draggingPasteboard.pasteboardItems
        else {
            return []
        }

        if let delegate = self.delegate {
            return delegate.placeholderView(shouldAcceptDropOf: items) ? .copy : []
        }

        return (items.count > 0) ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.highlight = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        self.highlight = false
        guard let items = sender.draggingPasteboard.pasteboardItems else {
            return false
        }

        if let delegate = self.delegate {
            return delegate.placeholderView(didAcceptDropOf: items)
        }

        return false
    }
}
