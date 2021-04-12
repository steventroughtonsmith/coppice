//
//  RecentDocumentTableCellView.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class RecentDocumentTableCellView: NSTableCellView {
    @IBOutlet weak var iconView: NSImageView!
    @IBOutlet weak var fileNameLabel: NSTextField!
    @IBOutlet weak var pathLabel: NSTextField!

    override var objectValue: Any? {
        didSet {
            self.reloadData()
        }
    }

    private func reloadData() {
        guard let url = self.objectValue as? URL else {
            return
        }
        self.fileNameLabel.stringValue = url.deletingPathExtension().lastPathComponent
        self.pathLabel.stringValue = url.deletingLastPathComponent().path
        self.iconView.image = NSWorkspace.shared.icon(forFile: url.path)
    }

    override var draggingImageComponents: [NSDraggingImageComponent] {
        let components = super.draggingImageComponents
        guard
            let imageComponent = components.first(where: { $0.key == .icon }),
            let labelComponent = components.first(where: { $0.key == .label })
        else {
            return components
        }

        let imageFrame = imageComponent.frame
        var labelFrame = labelComponent.frame
        labelFrame.origin.y = ((imageFrame.height - labelFrame.height) / 2) + imageFrame.origin.y

        labelComponent.frame = labelFrame

        return components
    }
}
