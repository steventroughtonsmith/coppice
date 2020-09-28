//
//  IconPopUpButtonCell.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class IconPopUpButtonCell: NSPopUpButtonCell {
    override func imageRect(forBounds rect: NSRect) -> NSRect {
        guard
            let image = self.image,
            let controlView = self.controlView,
            self.pullsDown
        else {
            return super.imageRect(forBounds: rect)
        }

        if #available(macOS 11, *) {
            var rect = super.imageRect(forBounds: rect)
            rect.origin.y -= 1
            return rect
        } else {
            let imageSize = image.size
            //Set the initial bounds we can draw in
            var imageRect = controlView.alignmentRect(forFrame: rect)
            imageRect.size.width -= 10;

            //Centre in view
            imageRect.origin.x = (imageRect.size.width - imageSize.width) - 4
            imageRect.origin.y = (imageRect.size.height - imageSize.height) / 2
            imageRect.size = imageSize
            return imageRect.rounded()
        }
        
    }

}
