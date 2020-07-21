//
//  SmallCanvasCell.swift
//  Coppice
//
//  Created by Martin Pilkington on 30/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class SmallCanvasCell: EditableLabelCell, CanvasCell {
    static var identifier = NSUserInterfaceItemIdentifier(rawValue: "SmallCanvasCell")

    @IBOutlet weak var thumbnailImageView: NSImageView!
    @IBOutlet weak var thumbnailBackground: NSBox!

    override var objectValue: Any? {
        didSet {
            guard let canvas = self.objectValue as? Canvas else {
                return
            }
            self.thumbnailBackground.fillColor = canvas.theme.canvasBackgroundColor
            self.thumbnailImageView.image = canvas.thumbnail
            self.thumbnailImageView.toolTip = canvas.title
        }
    }
}
