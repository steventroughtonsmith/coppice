//
//  EditableLabelCell.swift
//  Coppice
//
//  Created by Martin Pilkington on 09/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class EditableLabelCell: NSTableCellView {
    override var objectValue: Any? {
        didSet {
            self.endEditing(nil)
        }
    }

    @IBOutlet weak var iconView: NSView?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.updateAccessibility()
    }


    private func updateAccessibility() {
        self.setAccessibilityTitleUIElement(nil)
        self.setAccessibilityChildren(nil)
    }

    override func accessibilityPerformPress() -> Bool {
        self.startEditing()
        return true
    }

    func startEditing() {
        guard let textField = self.textField else {
            return
        }

        textField.isEditable = true
        textField.isBordered = true
        textField.drawsBackground = true
        textField.backgroundColor = NSColor.controlBackgroundColor
        textField.target = self
        textField.action = #selector(self.endEditing(_:))
        textField.delegate = self
        self.window?.makeFirstResponder(textField)
    }

    @objc dynamic private func endEditing(_ sender: Any?) {
        guard let textField = self.textField else {
            return
        }
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = nil
        textField.drawsBackground = false
        textField.placeholderString = NSLocalizedString("Untitled Page", comment: "Untitled Page title placeholder")
    }

    override func cancelOperation(_ sender: Any?) {
        self.textField?.abortEditing()
        self.endEditing(nil)
    }
}

//MARK: - Accessibility
extension EditableLabelCell {}

extension EditableLabelCell: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        self.endEditing(nil)
    }
}
