//
//  PageSelectorContentTableCellView.swift
//  Coppice
//
//  Created by Martin Pilkington on 10/05/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa

class PageSelectorContentTableCellView: NSTableCellView, TableCell {
    static var identifier = NSUserInterfaceItemIdentifier(rawValue: "PageSelectorContentCell")
    static var nib = NSNib(nibNamed: "PageSelectorContentTableCellView", bundle: nil)

    var mode: PageSelectorViewController.DisplayMode = .fromWindow {
        didSet {
            self.updateControlSize()
        }
    }

    @IBOutlet var titleField: NSTextField!
    @IBOutlet var detailsField: NSTextField!

    override func prepareForReuse() {
        super.prepareForReuse()

        self.updateControlSize()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.updateControlSize()
    }

    private func updateControlSize() {
        self.isDisplayedFromView = (self.mode == .fromView)

        let controlSize: NSControl.ControlSize = (self.mode == .fromWindow) ? .regular : .small
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: controlSize))
        self.titleField.font = font
        self.detailsField.font = font
    }

    @objc dynamic var isDisplayedFromView: Bool = false
}
