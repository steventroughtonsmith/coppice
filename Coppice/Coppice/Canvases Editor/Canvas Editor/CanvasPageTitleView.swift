//
//  CanvasPageTitleView.swift
//  Coppice
//
//  Created by Martin Pilkington on 11/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

protocol CanvasPageTitleViewDelegate: class {
    func closeClicked(in titleView: CanvasPageTitleView)
    func didChangeTitle(to newTitle: String, in titleView: CanvasPageTitleView)
}

class CanvasPageTitleView: NSView {
    //MARK: - Public API
    @objc dynamic var title: String = "" {
        didSet {
            self.updateTitleState()
        }
    }

    weak var delegate: CanvasPageTitleViewDelegate?

    var enabled: Bool = true {
        didSet {
            self.titleLabel.isEnabled = self.enabled
            self.closeButton.isEnabled = self.enabled
        }
    }

    override var isHidden: Bool {
        didSet {
            self.titleLabel.isHidden = self.isHidden
            self.closeButton.isHidden = self.isHidden
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
        self.addSubview(self.titleLabel)
        self.addSubview(self.closeButton)

        let labelCenterX = self.titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        labelCenterX.priority = .init(749)
        NSLayoutConstraint.activate([
            self.closeButton.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 1),
            self.closeButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
            self.closeButton.widthAnchor.constraint(equalToConstant: 16),
            self.closeButton.heightAnchor.constraint(equalToConstant: 16),
            labelCenterX,
            self.titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 1),
            self.titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.closeButton.trailingAnchor, constant: 5),
            self.trailingAnchor.constraint(greaterThanOrEqualTo: self.titleLabel.trailingAnchor, constant: 5),
        ])
        self.updateTitleState()
    }


    //MARK: - Subviews
    lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        label.usesSingleLineMode = true
        label.textColor = .labelColor
        label.font = NSFont.systemFont(ofSize: 12)
        label.alignment = .center
        label.focusRingType = .none
        label.delegate = self

        label.setAccessibilityHelp(NSLocalizedString("Interact with this element to edit the title", comment: "Page title field accessibility help"))

        let customAction = NSAccessibilityCustomAction(name: NSLocalizedString("Edit Title", comment: "Edit Title of canvas page accessibility action name")) {[weak self] in
            self?.makeTitleEditable()
            return true
        }
        label.setAccessibilityCustomActions([customAction])
        return label
    }()

    lazy var closeButton: NSButton = {
        let button = NSButton(image: NSImage(named: "NSStopProgressFreestandingTemplate")!,
                              target: self,
                              action: #selector(closeClicked(_:)))
        button.isBordered = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAccessibilityLabel(NSLocalizedString("Close Page", comment: "Close Page button accessibility label"))
        return button
    }()


    //MARK: - Actions
    @objc dynamic func closeClicked(_ sender: Any?) {
        self.delegate?.closeClicked(in: self)
    }


    //MARK: - Title State
    private func updateTitleState() {
        if self.title.count > 0 {
            self.titleLabel.textColor = .textColor
            self.titleLabel.stringValue = self.title
            self.titleLabel.setAccessibilityLabel(self.title)
        } else {
            self.titleLabel.textColor = .placeholderTextColor
            self.titleLabel.stringValue = Page.localizedDefaultTitle
            self.titleLabel.setAccessibilityLabel(Page.localizedDefaultTitle)
        }
    }


    //MARK: - Title Editability
    override func mouseDown(with event: NSEvent) {
        let localPoint = self.convert(event.locationInWindow, from: nil)
        guard self.titleLabel.frame.contains(localPoint) && (event.clickCount == 2) else {
            super.mouseDown(with: event)
            return
        }
        self.makeTitleEditable()
    }

    private func makeTitleEditable() {
        self.titleLabel.isEditable = true
        self.titleLabel.textColor = .textColor
        self.window?.makeFirstResponder(self.titleLabel)
    }
}


extension CanvasPageTitleView: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        self.delegate?.didChangeTitle(to: self.titleLabel.stringValue, in: self)
        self.titleLabel.isEditable = false
    }
}
