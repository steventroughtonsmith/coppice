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

        self.cropView.cropRect = self.viewModel.cropRect
        self.cropView.imageSize = image.size
        self.cropView.insets = NSEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)

        self.cropView.delegate = self

        self.subscribers[.cropRect] = self.viewModel.publisher(for: \.cropRect).assign(to: \.cropRect, on: self.cropView)
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.subscribers[.cropRect]?.cancel()
        self.subscribers[.cropRect] = nil
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case cropRect
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]
}

extension ImageEditorCropModeViewController: PageContentEditor {
    func startEditing(at point: CGPoint) {}
    func stopEditing() {}
}

extension ImageEditorCropModeViewController: ImageEditorCropViewDelegate {
    func didFinishChangingCropRect(in view: ImageEditorCropView) {
        self.viewModel.cropRect = self.cropView.cropRect
    }
}
