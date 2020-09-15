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
        guard let image = self.image, self.pullsDown else {
            return super.imageRect(forBounds: rect)
        }

        let imageSize = image.size

        //Set the initial bounds we can draw in
        var imageRect = rect
        imageRect.size.width -= 10;

        //Centre in view
        imageRect.origin.x = (imageRect.size.width - imageSize.width) / 2
        imageRect.origin.y = (imageRect.size.height - imageSize.height) / 2
        imageRect.size = imageSize
        return imageRect.rounded()
    }

}
