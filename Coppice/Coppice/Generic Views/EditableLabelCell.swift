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


    func startEditing() {
        guard let textField = self.textField else {
            return
        }

        textField.isEditable = true
        textField.isBordered = true
        textField.drawsBackground = true
        textField.backgroundColor = NSColor.controlBackgroundColor
        textField.target = self
        textField.action = #selector(endEditing(_:))
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

extension EditableLabelCell: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        self.endEditing(nil)
    }
}
