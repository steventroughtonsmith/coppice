//
//  LargeCanvasCell.swift
//  Bubbles
//
//  Created by Martin Pilkington on 30/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class LargeCanvasCell: EditableLabelCell {
    static var identifier = NSUserInterfaceItemIdentifier(rawValue: "LargeCanvasCell")

    @IBOutlet weak var canvasPreview: CanvasPreviewView!
    override var objectValue: Any? {
        didSet {
            guard let canvasItem = self.objectValue as? CanvasSidebarItem else {
                return
            }
            self.canvasPreview.previewImage = canvasItem.thumbnail
        }
    }

    override func layout() {
        super.layout()
        self.canvasPreview.preferredMaxDimensions = CGSize(width: self.bounds.width - 10, height: 120)
        super.layout()
    }
}
