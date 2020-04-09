//
//  ImageEditorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 13/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorViewController: NSViewController {
    @IBOutlet weak var imageView: NSImageView!
    
    @objc dynamic let viewModel: ImageEditorViewModel
    init(viewModel: ImageEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ImageEditorViewController", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    var enabled: Bool = true

    private lazy var imageEditorInspectorViewController: ImageEditorInspectorViewController = {
        return ImageEditorInspectorViewController(viewModel: ImageEditorInspectorViewModel(imageContent: self.viewModel.imageContent, modelController: self.viewModel.modelController))
    }()

    override func viewWillAppear() {
        super.viewWillAppear()
        print("view will appear in parent: \(self.isInCanvas)")

        self.imageView.imageScaling = self.isInCanvas ? .scaleProportionallyUpOrDown : .scaleProportionallyDown
    }

    var isInCanvas: Bool {
        return (self.parentEditor as? PageEditorViewController)?.isInCanvas ?? false
    }
}


extension ImageEditorViewController: Editor {
    var inspectors: [Inspector] {
        return [self.imageEditorInspectorViewController]
    }
}


extension ImageEditorViewController: ImageEditorView {
    
}
