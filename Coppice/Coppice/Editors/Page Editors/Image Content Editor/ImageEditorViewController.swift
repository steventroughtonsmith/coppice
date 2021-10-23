//
//  ImageEditorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 13/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class ImageEditorViewController: NSViewController, NSMenuItemValidation, NSToolbarItemValidation {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        (self.view as? ImageEditorView)?.backgroundColour = NSColor.pageEditorBackground
        self.updatePlaceholderLabel()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        self.imageView.imageScaling = self.isInCanvas ? .scaleProportionallyUpOrDown : .scaleProportionallyDown
        self.imageDescriptionObserver = self.viewModel.publisher(for: \.accessibilityDescription).sink { [weak self] description in
            self?.imageView.setAccessibilityValueDescription(description)
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.updatePlaceholderLabel()
    }


    var imageDescriptionObserver: AnyCancellable!
    override func viewDidDisappear() {
        super.viewDidDisappear()

        self.imageDescriptionObserver?.cancel()
        self.imageDescriptionObserver = nil
    }

    var simulateInCanvas: Bool = false

    var isInCanvas: Bool {
        if self.simulateInCanvas {
            return true
        }
        return (self.parentEditor as? PageEditorViewController)?.viewModel.isInCanvas ?? false
    }


    @IBAction func editLink(_ sender: Any?) {
        //We need an empty implementation just so validation occurs
    }

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        if item.action == #selector(self.editLink(_:)) {
            item.toolTip = NSLocalizedString("Image Pages don't current support links", comment: "Image Page link to page disabled tooltip")
            return false
        }
        return true
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(self.editLink(_:)) {
            menuItem.toolTip = NSLocalizedString("Image Pages don't current support links", comment: "Image Pages link to page disabled tooltip")
            return false
        }
        return true
    }


    @IBOutlet var placeholderLabel: NSTextField!
    private func updatePlaceholderLabel() {
        if (self.view.window?.firstResponder == self.imageView) || !self.isInCanvas {
            self.placeholderLabel.stringValue = NSLocalizedString("Drag or paste an image here", comment: "Image Editor default placeholder")
        } else {
            self.placeholderLabel.stringValue = NSLocalizedString("Double-click to edit image", comment: "Image Editor on canvas placeholder")
        }
    }
}


extension ImageEditorViewController: PageContentEditor {
    var inspectors: [Inspector] {
        return [self.imageEditorInspectorViewController]
    }

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


extension ImageEditorViewController: ImageEditorViewProtocol {}
