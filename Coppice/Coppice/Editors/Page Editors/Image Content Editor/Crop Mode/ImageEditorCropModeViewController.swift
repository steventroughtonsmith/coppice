//
//  ImageEditorCropModeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/01/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class ImageEditorCropModeViewController: NSViewController {
    var enabled: Bool = true

    @objc dynamic let viewModel: ImageEditorViewModel
    init(viewModel: ImageEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ImageEditorCropModeViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    //MARK: - View Lifecycle
    @IBOutlet var cropView: ImageEditorCropView!
    override func viewDidAppear() {
        super.viewDidAppear()

        guard let image = self.viewModel.image else {
            return
        }

        self.cropView.cropRect = image.size.toRect()
        self.cropView.imageSize = image.size
        self.cropView.insets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension ImageEditorCropModeViewController: PageContentEditor {
    func startEditing(at point: CGPoint) {}
    func stopEditing() {}
}
