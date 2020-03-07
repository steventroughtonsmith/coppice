//
//  SmallCanvasCell.swift
//  Bubbles
//
//  Created by Martin Pilkington on 30/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class SmallCanvasCell: EditableLabelCell {
    static var identifier = NSUserInterfaceItemIdentifier(rawValue: "SmallCanvasCell")

    @IBOutlet weak var canvasPreview: CanvasPreviewView!
    override var objectValue: Any? {
        didSet {
            guard let canvas = self.objectValue as? Canvas else {
                return
            }
            self.canvasPreview.previewImage = canvas.thumbnail
            self.canvasPreview.toolTip = canvas.title
        }
    }

    override func awakeFromNib() {
        self.canvasPreview.preferredMaxDimensions = CGSize(width: 48, height: 48)
    }
}
