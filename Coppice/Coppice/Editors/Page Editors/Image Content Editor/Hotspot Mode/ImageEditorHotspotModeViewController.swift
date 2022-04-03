//
//  ImageEditorHotspotModeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/01/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class ImageEditorHotspotModeViewController: NSViewController {
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet var hotspotView: ImageEditorHotspotView!

    var enabled: Bool = true

    @objc dynamic let viewModel: ImageEditorViewModel
    init(viewModel: ImageEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ImageEditorHotspotModeViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.subscribers[.imageEditorHotspots]?.cancel()
    }

    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupLayoutEngine()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        self.imageView.imageScaling = self.isInCanvas ? .scaleProportionallyUpOrDown : .scaleProportionallyDown
        self.subscribers[.accessibilityDescription] = self.viewModel.publisher(for: \.accessibilityDescription).sink { [weak self] description in
            self?.imageView.setAccessibilityValueDescription(description)
        }
        self.subscribers[.image] = self.viewModel.publisher(for: \.image).sink { [weak self] image in
            let imageSize = image?.size ?? .zero
            self?.hotspotView.imageSize = imageSize
            self?.layoutEngine.imageSize = imageSize
            self?.hotspotView.cropRect = imageSize.toRect()
            self?.layoutEngine.cropRect = imageSize.toRect()
        }

        self.hotspotView.maintainsAspectRatio = (self.isInCanvas == false)

        if self.isInCanvas {
            NSLayoutConstraint.activate([
                self.hotspotView.widthAnchor.constraint(equalTo: self.imageView.widthAnchor),
                self.hotspotView.heightAnchor.constraint(equalTo: self.imageView.heightAnchor),
            ])
        }
    }

    override func viewWillDisappear() {
        self.subscribers[.accessibilityDescription]?.cancel()
        self.subscribers[.accessibilityDescription] = nil

        self.subscribers[.image]?.cancel()
        self.subscribers[.image] = nil
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case accessibilityDescription
        case image
        case imageEditorHotspots
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]


    //MARK: - Layout Engine

    private lazy var layoutEngine: ImageEditorHotspotLayoutEngine = {
        let layoutEngine = ImageEditorHotspotLayoutEngine()
        layoutEngine.isEditable = true
        layoutEngine.delegate = self
        return layoutEngine
    }()

    private func setupLayoutEngine() {
        self.hotspotView.layoutEngine = self.layoutEngine

        self.subscribers[.imageEditorHotspots] = self.viewModel.hotspotCollection.$imageEditorHotspots.sink { [weak self] hotspots in
            self?.layoutEngine.hotspots = hotspots
        }
    }

    //MARK: - Actions
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

extension ImageEditorHotspotModeViewController: PageContentEditor {
    func startEditing(at point: CGPoint) {}
    func stopEditing() {}
}

extension ImageEditorHotspotModeViewController: ImageEditorHotspotLayoutEngineDelegate {
    func layoutDidChange(in layoutEngine: ImageEditorHotspotLayoutEngine) {
        self.hotspotView.layoutEngineDidChange()
        self.viewModel.linkEditor.updateSelectedLink()
    }

    func didCommitEdit(in layoutEngine: ImageEditorHotspotLayoutEngine) {
        self.viewModel.imageContent.hotspots = self.layoutEngine.hotspots.compactMap(\.imageHotspot)
    }
}
