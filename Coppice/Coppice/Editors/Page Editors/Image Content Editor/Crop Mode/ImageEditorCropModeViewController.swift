//
//  ImageEditorCropModeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/01/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorCropModeViewController: NSViewController {
    var enabled: Bool = true

	override func loadView() {
		self.view = ImageEditorCropView()
	}

    override func viewDidAppear() {
        super.viewDidAppear()

        (self.view as? ImageEditorCropView)?.cropRect = self.view.bounds.insetBy(dx: 40, dy: 40)
    }
}

extension ImageEditorCropModeViewController: PageContentEditor {
    func startEditing(at point: CGPoint) {}
    func stopEditing() {}
}
