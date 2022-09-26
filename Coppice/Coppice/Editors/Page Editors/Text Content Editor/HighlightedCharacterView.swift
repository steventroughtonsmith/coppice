//
//  HighlightedCharacterView.swift
//  Coppice
//
//  Created by Martin Pilkington on 29/08/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

class HighlightedCharacterView: NSView {
    lazy var background: NSBox = {
        let box = NSBox()
        box.boxType = .custom
        box.titlePosition = .noTitle
        box.fillColor = NSColor.systemBlue
        box.borderColor = NSColor.black.withAlphaComponent(0.3)
        box.cornerRadius = 5
        return box
    }()

    lazy var textField: NSTextField = {
        let textField = NSTextField(labelWithString: "")
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        self.addSubview(self.background, withInsets: NSEdgeInsetsZero)

        self.addSubview(self.textField)
        NSLayoutConstraint.activate([
            self.textField.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.textField.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }

    var attributedString: NSAttributedString? {
        didSet {
            guard let attributedString = self.attributedString?.mutableCopy() as? NSMutableAttributedString else {
                return
            }
            attributedString.removeAttribute(.link, range: attributedString.fullRange)

            let whiteContrast = NSColor.white.contrastRatio(to: .systemBlue)
            let blackContrast = NSColor.black.contrastRatio(to: .systemBlue)

            let textColor = whiteContrast >= blackContrast ? NSColor.white : NSColor.black

            attributedString.addAttribute(.foregroundColor, value: textColor, range: attributedString.fullRange)
            self.textField.attributedStringValue = attributedString
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
