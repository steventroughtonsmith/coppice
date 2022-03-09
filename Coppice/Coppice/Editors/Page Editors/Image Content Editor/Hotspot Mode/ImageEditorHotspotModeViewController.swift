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

    let viewModel: ImageEditorHotspotModeViewModel
    init(viewModel: ImageEditorHotspotModeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ImageEditorHotspotModeViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
}

extension ImageEditorHotspotModeViewController: PageContentEditor {
    func startEditing(at point: CGPoint) {}
    func stopEditing() {}
}
