//
//  ImageEditorViewModeView.swift
//  Coppice
//
//  Created by Martin Pilkington on 05/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorViewModeView: NSView {
    @IBOutlet var imageView: NSImageView?
	@IBOutlet var hotspotView: ImageEditorHotspotView?

    override func hitTest(_ point: NSPoint) -> NSView? {
		guard
			let hotspotView = self.hotspotView,
			let imageView = self.imageView
		else {
			return super.hitTest(point)
		}

		let pointInHotspotView = hotspotView.convert(point, from: self.superview)

		return hotspotView.containsHotspots(at: pointInHotspotView) ? hotspotView : imageView
    }
}
