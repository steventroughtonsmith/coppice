//
//  SourceListTableCellView.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

class SourceListTableCellView: EditableLabelCell, SidebarSizable {
    @IBOutlet var iconWidthConstraint: NSLayoutConstraint!
    @IBOutlet var iconHeightConstraint: NSLayoutConstraint!

    var activeSidebarSize: ActiveSidebarSize = .medium {
        didSet {
            self.textField?.font = NSFont.controlContentFont(ofSize: self.activeSidebarSize.smallRowFontSize)
            self.iconWidthConstraint.constant = self.activeSidebarSize.smallRowGlyphSize.width
            self.iconHeightConstraint.constant = self.activeSidebarSize.smallRowGlyphSize.height
        }
    }

    override var draggingImageComponents: [NSDraggingImageComponent] {
        let components = super.draggingImageComponents
        guard
            let textField = self.textField,
            let newStyle = textField.attributedStringValue.mutableCopy() as? NSMutableAttributedString,
            let labelIndex = components.firstIndex(where: { $0.key == .label })
        else {
            return components
        }

        //Set to the label colour and draw
        newStyle.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSMakeRange(0, newStyle.length))
        let image = NSImage(size: textField.bounds.size, flipped: false) { (rect) -> Bool in
            newStyle.draw(in: rect)
            return true
        }

        //We'll just update the label contents as everything else is already setup for us
        components[labelIndex].contents = image

        return components
    }
}
