//
//  ImageEditorHotspotModeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/01/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorHotspotModeViewController: NSViewController {
    var enabled: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
}

extension ImageEditorHotspotModeViewController: PageContentEditor {
    func startEditing(at point: CGPoint) {}
    func stopEditing() {}
}
