//
//  LinkControl.swift
//  LinkControl
//
//  Created by Martin Pilkington on 26/09/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import AppKit

@IBDesignable
class LinkControl: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.sharedInit()
    }

    private func sharedInit() {
        self.addSubview(self.iconView)
        self.addSubview(self.stackView, withInsets: NSEdgeInsets(top: 0, left: 0, bottom: 1, right: 0))

        self.stackView.addArrangedSubview(self.textField)
        self.stackView.addArrangedSubview(self.clearButton)

        NSLayoutConstraint.activate([
            self.iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 2),
            self.iconView.topAnchor.constraint(equalTo: self.topAnchor),
            self.iconView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1),
            self.iconView.heightAnchor.constraint(equalTo: self.iconView.widthAnchor),
            self.textField.bottomAnchor.constraint(equalTo: self.stackView.bottomAnchor),
            self.clearButton.bottomAnchor.constraint(equalTo: self.stackView.bottomAnchor),
            self.clearButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])

        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.layer?.masksToBounds = true
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: NSView.noIntrinsicMetric, height: 22)
    }

    //MARK: - Public Properties
    @IBInspectable var textValue: String {
        get { self.textField.stringValue }
        set {
            self.textField.stringValue = newValue
            self.clearButton.isHidden = newValue.isEmpty
            self.textField.isFullWidth = newValue.isEmpty
        }
    }

    @IBInspectable var placeholderString: String? {
        get { self.textField.placeholderString }
        set { self.textField.placeholderString = newValue }
    }

    @IBInspectable var icon: NSImage? {
        get { self.iconView.image }
        set { self.iconView.image = newValue }
    }

    @IBInspectable var clearButtonIcon: NSImage? {
        get { self.clearButton.image }
        set { self.clearButton.image = newValue }
    }

    @IBInspectable var isEnabled: Bool = true {
        didSet {
            guard self.isEnabled != oldValue else {
                return
            }
            self.iconView.isEnabled = self.isEnabled
            self.textField.isEnabled = self.isEnabled
            self.clearButton.isEnabled = self.isEnabled
            self.setNeedsDisplay(self.bounds)
        }
    }

    var textDelegate: NSTextFieldDelegate? {
        get { self.textField.delegate }
        set { self.textField.delegate = newValue }
    }

    //MARK: - Subviews
    private let iconView: NSImageView = {
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageAlignment = .alignCenter
        return imageView
    }()

    let textField: LinkControlTextField = {
        let textField = LinkControlTextField(string: "")
        textField.cell = LinkControlTextFieldCell(textCell: "Link Control")
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.drawsBackground = false
        textField.isBordered = false
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.setContentHuggingPriority(.defaultLow, for: .vertical)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textField.isEditable = true
        return textField
    }()

    let clearButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.stopProgressTemplateName)!, target: nil, action: nil)
        button.cell = LinkControlClearButtonCell()
        button.image = NSImage(named: NSImage.stopProgressTemplateName)
        button.imagePosition = .imageOnly
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 25).isActive = true
        button.bezelStyle = .shadowlessSquare
        button.showsBorderOnlyWhileMouseInside = true
        return button
    }()

    private let stackView: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .top
        stackView.spacing = 1
        return stackView
    }()


    //MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        self.drawBackground()
        self.drawBorder()
    }

    private func drawBackground() {
        var baseColor: NSColor = .controlColor
        if (self.effectiveAppearance.isDarkMode) {
            baseColor = .controlColor.withAlphaComponent(0.05)
            NSShadow(offset: CGSize(width: 0, height: -0.5), blurRadius: 0, color: NSColor(white: 0, alpha: 0.3)).set()
        } else {
            NSColor(white: 0, alpha: 0.05).set()
            var shadowFrame = self.stackView.frame
            shadowFrame.origin.y = 0.5
            NSBezierPath(roundedRect: shadowFrame, xRadius: 5, yRadius: 5).fill()
        }

        if (self.isEnabled == false) {
            baseColor = baseColor.withSystemEffect(.disabled)
        }

        baseColor.setFill()

        let backgroundPath = NSBezierPath(roundedRect: self.stackView.frame, xRadius: 5, yRadius: 5)
        backgroundPath.addClip()
        backgroundPath.fill()
    }

    private func drawBorder() {
        if self.effectiveAppearance.isDarkMode {
            NSColor(white: 1, alpha: 0.25).set()
        } else {
            NSColor(white: 0.8, alpha: 1).set()
        }

        let path = NSBezierPath(roundedRect: self.stackView.frame.insetBy(dx: 0.5, dy: 0.5), xRadius: 5, yRadius: 5)
        path.lineWidth = 1
        path.stroke()
    }
}

class LinkControlClearButtonCell: NSButtonCell {
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        if controlView.effectiveAppearance.isDarkMode {
            NSColor(white: 1, alpha: 0.5).set()
        } else {
            NSColor(white: 0, alpha: 0.8).set()
        }

        let path = NSBezierPath()
        path.lineWidth = 0.5
        path.move(to: .zero)
        path.line(to: CGPoint(x: 0, y: cellFrame.maxY))
        path.stroke()

        super.draw(withFrame: cellFrame, in: controlView)
    }

    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {
        if self.isHighlighted {
            NSColor.controlColor.withSystemEffect(.pressed).set()
        } else {
            NSColor.controlColor.set()
        }
        frame.fill()
    }
}

class LinkControlTextField: NSTextField {
    var isFullWidth = false

    override func drawFocusRingMask() {
        NSColor.black.set()

        var rect = self.bounds
        rect.origin.x += 1
        rect.size.width -= 1
        let path: NSBezierPath
        if self.isFullWidth {
            path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
        } else {
            path = NSBezierPath(roundedRect: rect, topLeftRadius: 5, bottomLeftRadius: 5)
        }
        path.fill()
    }
}

class LinkControlTextFieldCell: NSTextFieldCell {
    static let iconSize: CGFloat = 26

    private func adjustTextRect(_ rect: CGRect) -> CGRect {
        var newRect = rect
        newRect.origin.y += 2
        newRect.origin.x += Self.iconSize
        newRect.size.width -= (Self.iconSize + 8)
        return newRect
    }

    override func titleRect(forBounds rect: NSRect) -> NSRect {
        return self.adjustTextRect(super.drawingRect(forBounds: rect))
    }

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        return self.adjustTextRect(super.drawingRect(forBounds: rect))
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        let newRect = self.adjustTextRect(rect)
        super.edit(withFrame: newRect, in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        let newRect = self.adjustTextRect(rect)
        super.select(withFrame: newRect, in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
}
