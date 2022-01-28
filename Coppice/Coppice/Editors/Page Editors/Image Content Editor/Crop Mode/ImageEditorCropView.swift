//
//  ImageEditorCropView.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/01/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorCropView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

		NSColor(white: 0, alpha: 0.5).set()
		self.bounds.fill()
    }
    
}
