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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    //MARK: - Subscribers
    private enum SubscriberKey {
        case accessibilityDescription
        case image
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]


    //MARK: - Layout Engine

    private let layoutEngine: ImageEditorHotspotLayoutEngine = {
        let layoutEngine = ImageEditorHotspotLayoutEngine()
        layoutEngine.isEditable = true
        return layoutEngine
    }()

    private func setupLayoutEngine() {
        self.hotspotView.layoutEngine = self.layoutEngine

        let hissingWoods = ImageEditorRectangleHotspot(shape: .rectangle, rect: CGRect(x: 33, y: 210, width: 30, height: 170), url: nil, imageSize: self.viewModel.image?.size ?? .zero)
        let tavern = ImageEditorRectangleHotspot(shape: .oval, rect: CGRect(x: 460, y: 390, width: 50, height: 40), url: nil, imageSize: self.viewModel.image?.size ?? .zero)
        let barracks = ImageEditorRectangleHotspot(shape: .rectangle, rect: CGRect(x: 520, y: 150, width: 40, height: 50), url: nil, imageSize: self.viewModel.image?.size ?? .zero)

        self.layoutEngine.hotspots = [hissingWoods, tavern, barracks]
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
