//
//  ImageEditorViewModeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/01/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class ImageEditorViewModeViewController: NSViewController {
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet var placeholderView: ImageEditorPlaceholderView!

    @objc dynamic let viewModel: ImageEditorViewModel
    init(viewModel: ImageEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ImageEditorViewModeViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    var enabled: Bool = true

    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updatePlaceholderLabel()
        self.fixConstraintsOnBigSur()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        self.imageView.imageScaling = self.isInCanvas ? .scaleProportionallyUpOrDown : .scaleProportionallyDown
        self.subscribers[.accessibilityDescription] = self.viewModel.publisher(for: \.accessibilityDescription).sink { [weak self] description in
            self?.imageView.setAccessibilityValueDescription(description)
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.updatePlaceholderLabel()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()

        self.subscribers[.accessibilityDescription]?.cancel()
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case accessibilityDescription
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    //MARK: - Constraints Fix
    @IBOutlet var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var placeholderViewTopConstraint: NSLayoutConstraint!

    private func fixConstraintsOnBigSur() {
        self.imageViewTopConstraint.isActive = false
        self.placeholderViewTopConstraint.isActive = false
        if #available(macOS 11.0, *) {
            self.imageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
            self.placeholderView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        }
    }

    //MARK: - Placeholder Label
    @IBOutlet var placeholderLabel: NSTextField!
    private func updatePlaceholderLabel() {
        if (self.view.window?.firstResponder == self.imageView) || !self.isInCanvas {
            self.placeholderLabel.stringValue = NSLocalizedString("Drag or paste an image here", comment: "Image Editor default placeholder")
        } else {
            self.placeholderLabel.stringValue = NSLocalizedString("Double-click to edit image", comment: "Image Editor on canvas placeholder")
        }
    }
}

extension ImageEditorViewModeViewController: PageContentEditor {
    func startEditing(at point: CGPoint) {
        self.view.window?.makeFirstResponder(self.imageView)
        self.updatePlaceholderLabel()
    }

    func stopEditing() {
        if (self.view.window?.firstResponder == self.imageView) {
            self.view.window?.makeFirstResponder(nil)
        }
        self.updatePlaceholderLabel()
    }
}
