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
        self.addSubview(self.titleLabel)
        self.addSubview(self.button)

        let labelCenterX = self.titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        labelCenterX.priority = .init(749)
        NSLayoutConstraint.activate([
            self.button.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 1),
            self.button.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
            self.button.widthAnchor.constraint(equalToConstant: 16),
            self.button.heightAnchor.constraint(equalToConstant: 16),
            labelCenterX,
            self.titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 1),
            self.titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.button.trailingAnchor, constant: 5),
            self.trailingAnchor.constraint(greaterThanOrEqualTo: self.titleLabel.trailingAnchor, constant: 5),
        ])
    }


    //MARK: - Subviews
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: self.title)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .labelColor
        label.font = NSFont.systemFont(ofSize: 12)
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


    //MARK: - Actions
    @objc dynamic func closeClicked(_ sender: Any?) {
        self.delegate?.closeClicked(in: self)
    }
}
