//
//  ImageEditorViewModeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/01/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore

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

        self.subscribers[.cropRect] = self.viewModel.publisher(for: \.cropRect).sink { [weak self] cropRect in
            self?.layoutEngine.cropRect = cropRect
            self?.hotspotView.cropRect = cropRect
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

        self.highlightIfNecessary()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()

        self.subscribers[.accessibilityDescription]?.cancel()
        self.subscribers[.image]?.cancel()
        self.subscribers[.cropRect]?.cancel()
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case accessibilityDescription
        case image
        case imageEditorHotspots
        case cropRect
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
    private lazy var layoutEngine: ImageEditorHotspotLayoutEngine = {
        let layoutEngine = ImageEditorHotspotLayoutEngine()
        layoutEngine.isEditable = false
        layoutEngine.delegate = self
        return layoutEngine
    }()

    private func setupLayoutEngine() {
        self.hotspotView.layoutEngine = self.layoutEngine

        self.subscribers[.imageEditorHotspots] = self.viewModel.hotspotCollection.$imageEditorHotspots.sink { [weak self] hotspots in
            self?.layoutEngine.hotspots = hotspots
        }
    }

    //MARK: - Search
    private func highlightIfNecessary() {
        guard let highlightRect = self.viewModel.highlightRect else {
            return
        }
        self.hotspotView.highlight(highlightRect)
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

    func isLink(at point: CGPoint) -> Bool {
        let imageSize = self.hotspotView.frame.size
        return self.layoutEngine.hotspot(at: self.hotspotView.convertPointToImageSpace(point.flip(in: imageSize))) != nil
    }

    func openLink(at point: CGPoint) {
        let imageSize = self.hotspotView.frame.size
        guard let hotspot = self.layoutEngine.hotspot(at: self.hotspotView.convertPointToImageSpace(point.flip(in: imageSize))) else {
            return
        }
        self.didClickOnHotspot(hotspot, in: self.layoutEngine)
    }
}

extension ImageEditorViewModeViewController: ImageEditorHotspotLayoutEngineDelegate {
    func layoutDidChange(in layoutEngine: ImageEditorHotspotLayoutEngine) {
        self.hotspotView.layoutEngineDidChange()
        self.viewModel.linkEditor.updateSelectedLink()
    }

    func didClickOnHotspot(_ hotspot: ImageEditorHotspot, in layoutEngine: ImageEditorHotspotLayoutEngine) {
        guard let url = hotspot.url else {
            return
        }

        if let pageLink = PageLink(url: url) {
            self.open(pageLink)
        } else {
            NSWorkspace.shared.open(url)
        }
    }
}
