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
    @IBOutlet var hotspotView: ImageEditorHotspotView!

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
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        self.imageView.imageScaling = self.isInCanvas ? .scaleProportionallyUpOrDown : .scaleProportionallyDown
        self.subscribers[.accessibilityDescription] = self.viewModel.publisher(for: \.accessibilityDescription).sink { [weak self] description in
            self?.imageView.setAccessibilityValueDescription(description)
        }
        self.subscribers[.image] = self.viewModel.publisher(for: \.image).sink { [weak self] image in
            self?.hotspotView.imageSize = image?.size ?? .zero
            self?.layoutEngine.imageSize = image?.size ?? .zero
        }

        self.hotspotView.maintainsAspectRatio = (self.isInCanvas == false)

        if self.isInCanvas {
            NSLayoutConstraint.activate([
                self.hotspotView.widthAnchor.constraint(equalTo: self.imageView.widthAnchor),
                self.hotspotView.heightAnchor.constraint(equalTo: self.imageView.heightAnchor),
            ])
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.updatePlaceholderLabel()
        self.setupLayoutEngine()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()

        self.subscribers[.accessibilityDescription]?.cancel()
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case accessibilityDescription
        case image
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    //MARK: - Placeholder Label
    @IBOutlet var placeholderLabel: NSTextField!
    private func updatePlaceholderLabel() {
        if (self.view.window?.firstResponder == self.imageView) || !self.isInCanvas {
            self.placeholderLabel.stringValue = NSLocalizedString("Drag or paste an image here", comment: "Image Editor default placeholder")
        } else {
            self.placeholderLabel.stringValue = NSLocalizedString("Double-click to edit image", comment: "Image Editor on canvas placeholder")
        }
    }


    //MARK: - Hotspots
    private let layoutEngine = ImageEditorHotspotLayoutEngine()

    private func setupLayoutEngine() {
        self.hotspotView.layoutEngine = self.layoutEngine

        let hissingWoods = ImageEditorRectangleHotspot(shape: .rectangle, rect: CGRect(x: 33, y: 210, width: 30, height: 170), url: nil, mode: .edit, imageSize: self.viewModel.image?.size ?? .zero)
        let tavern = ImageEditorRectangleHotspot(shape: .oval, rect: CGRect(x: 460, y: 390, width: 50, height: 40), url: nil, mode: .edit, imageSize: self.viewModel.image?.size ?? .zero)
        let barracks = ImageEditorRectangleHotspot(shape: .rectangle, rect: CGRect(x: 520, y: 150, width: 40, height: 50), url: nil, mode: .edit, imageSize: self.viewModel.image?.size ?? .zero)

        self.layoutEngine.hotspots = [hissingWoods, tavern, barracks]
    }

    @IBAction func toggleHotspotKind(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            self.layoutEngine.hotspotKindForCreation = .rectangle
        } else if sender.selectedSegment == 1 {
            self.layoutEngine.hotspotKindForCreation = .oval
        } else if sender.selectedSegment == 2 {
            self.layoutEngine.hotspotKindForCreation = .polygon
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
