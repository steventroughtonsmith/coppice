//
//  CanvasPageTitleView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 11/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

protocol CanvasPageTitleViewDelegate: class {
    func closeClicked(in titleView: CanvasPageTitleView)
}

class CanvasPageTitleView: NSView {
    //MARK: - Public API
    var title: String = "" {
        didSet {
            self.titleLabel.stringValue = title
        }
    }

    weak var delegate: CanvasPageTitleViewDelegate?

    var style: Style = .standard {
        didSet {
            if oldValue != self.style {
                self.updateTitleBackground()
            }
        }
    }

    var isFocused: Bool = true {
        didSet {
            guard self.style == .transient else {
                self.titleBackground.alphaValue = 1
                return
            }
            self.titleBackground.alphaValue = self.isFocused ? 1 : 0
        }
    }


    //MARK: - Setup
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupSubviews()
    }

    private func setupSubviews() {
        self.titleBackground.addSubview(self.titleLabel)
        self.addSubview(self.titleBackground, withInsets: NSEdgeInsetsZero)
        self.addSubview(self.button)

        let labelCenterX = self.titleLabel.centerXAnchor.constraint(equalTo: self.titleBackground.centerXAnchor)
        labelCenterX.priority = .init(749)
        NSLayoutConstraint.activate([
            self.button.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.button.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
            self.button.widthAnchor.constraint(equalToConstant: 16),
            self.button.heightAnchor.constraint(equalToConstant: 16),
            labelCenterX,
            self.titleLabel.centerYAnchor.constraint(equalTo: self.titleBackground.centerYAnchor),
            self.titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.button.trailingAnchor, constant: 5),
            self.titleBackground.trailingAnchor.constraint(greaterThanOrEqualTo: self.titleLabel.trailingAnchor, constant: 5),
        ])
        self.updateTitleBackground()
    }


    //MARK: - Subviews
    private lazy var titleBackground: NSBox = {
        let view = NSBox()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.boxType = .custom
        view.borderType = .noBorder
        view.fillColor = .clear
        return view
    }()

    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: self.title)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var button: NSButton = {
        let button = NSButton(image: NSImage(named: "NSStopProgressFreestandingTemplate")!,
                              target: self,
                              action: #selector(closeClicked(_:)))
        button.isBordered = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()


    private func updateTitleBackground() {
        switch self.style {
        case .standard:
            self.titleBackground.fillColor = .clear
            self.titleLabel.textColor = NSColor.textColor
            self.titleBackground.alphaValue = 1
        case .transient:
            self.titleBackground.fillColor = NSColor(white: 0, alpha: 0.8)
            self.titleLabel.textColor = NSColor.white
            self.titleBackground.alphaValue = 0
        }
        self.updateTrackingAreas()
    }


    //MARK: - Actions
    @objc dynamic func closeClicked(_ sender: Any?) {
        self.delegate?.closeClicked(in: self)
    }


    //MARK: - Sub Types
    enum Style: Equatable {
        case standard
        case transient
    }
}
