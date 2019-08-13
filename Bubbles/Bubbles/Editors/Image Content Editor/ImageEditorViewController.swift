//
//  ImageEditorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 13/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorViewController: NSViewController, Editor {
    @IBOutlet weak var imageView: NSImageView!
    
    @objc dynamic let viewModel: ImageEditorViewModel
    init(viewModel: ImageEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ImageEditorViewController", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ImageEditorViewController: ImageEditorView {
    
}
