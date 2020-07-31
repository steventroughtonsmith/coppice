//
//  LargeCanvasCell.swift
//  Coppice
//
//  Created by Martin Pilkington on 30/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore

class LargeCanvasCell: EditableLabelCell, CanvasCell {
    static var identifier = NSUserInterfaceItemIdentifier(rawValue: "LargeCanvasCell")

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var thumbnailImageView: NSImageView!
    @IBOutlet weak var thumbnailBackground: NSBox!
    private var thumbnailObserver: AnyCancellable?
    override var objectValue: Any? {
        didSet {
            guard let canvas = self.objectValue as? Canvas else {
                return
            }
            self.thumbnailBackground.fillColor = canvas.theme.canvasBackgroundColor
            self.thumbnailImageView.image = canvas.thumbnail
        }
    }

    override func layout() {
        super.layout()
//        self.thumbnailImageView.frame = self.thumbnailImageView.frame.rounded()
//        self.nameLabel.frame = self.nameLabel.frame.rounded()
    }

}
