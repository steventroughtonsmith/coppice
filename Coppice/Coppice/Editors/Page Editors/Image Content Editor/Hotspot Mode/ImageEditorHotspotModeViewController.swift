//
//  ImageEditorHotspotModeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/01/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore

class ImageEditorHotspotModeViewController: NSViewController {
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet var hotspotView: ImageEditorHotspotView!
    @IBOutlet var proOverlay: HotspotTypeProOverlayView!
    @IBOutlet var hotspotTypeSegmentedControl: TranslucentSegmentedControl!

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
        self.imageView.cell?.setAccessibilityElement(false)
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.layoutArea)
        self.view.setAccessibilityLabel("Image Hotspot Editor")
        self.setupCreateHotspotAccessibilityActions(isProEnabled: false)

        self.hotspotTypeSegmentedControl.appearance = NSAppearance(named: .darkAqua)
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

        self.subscribers[.proEnabled] = self.viewModel.$isProEnabled.sink { [weak self] isProEnabled in
            self?.proOverlay.isHidden = isProEnabled
            if isProEnabled == false {
                self?.hotspotTypeSegmentedControl.setSelected(true, forSegment: 0)
                self?.layoutEngine.hotspotKindForCreation = .rectangle
            }
            self?.setupCreateHotspotAccessibilityActions(isProEnabled: isProEnabled)
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
        self.updateHotspotAccessibilityElements()
        self.setupLayoutEngine()
    }

    override func viewWillDisappear() {
        self.subscribers[.accessibilityDescription]?.cancel()
        self.subscribers[.accessibilityDescription] = nil

        self.subscribers[.image]?.cancel()
        self.subscribers[.image] = nil

        self.subscribers[.imageEditorHotspots] = nil
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case accessibilityDescription
        case image
        case imageEditorHotspots
        case proEnabled
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
        guard self.viewModel.isProEnabled else {
            sender.setSelected(true, forSegment: 0)
            self.layoutEngine.hotspotKindForCreation = .rectangle
            return
        }

        if sender.selectedSegment == 0 {
            self.layoutEngine.hotspotKindForCreation = .rectangle
        } else if sender.selectedSegment == 1 {
            self.layoutEngine.hotspotKindForCreation = .oval
        } else if sender.selectedSegment == 2 {
            self.layoutEngine.hotspotKindForCreation = .polygon
        }
    }

    //MARK: - Creation
    func createRectangleHotspot() {
        guard let imageSize = self.viewModel.image?.size else {
            return
        }
        self.viewModel.imageContent.hotspots.append(ImageHotspot.rectangle(centredInImageOfSize: imageSize))
    }

    func createOvalHotspot() {
        guard let imageSize = self.viewModel.image?.size else {
            return
        }
        self.viewModel.imageContent.hotspots.append(ImageHotspot.oval(centredInImageOfSize: imageSize))
    }

    func createPolygonHotspot(withSides sides: Int) {
        guard let imageSize = self.viewModel.image?.size else {
            return
        }
        self.viewModel.imageContent.hotspots.append(ImageHotspot.polygon(withSides: sides, centredInImageOfSize: imageSize))
    }

    //MARK: - Accessibility
    private var accessibilityElements: [ImageEditorHotspotAccessibilityElement] = []
    private func updateHotspotAccessibilityElements() {
        let newElements = self.layoutEngine.hotspots.map { hotspot -> ImageEditorHotspotAccessibilityElement in
            if let existingElement = self.accessibilityElements.first(where: { $0.hotspot.imageHotspot == hotspot.imageHotspot }) {
                return existingElement
            }
            return ImageEditorHotspotAccessibilityElement(hotspot: hotspot, hotspotView: self.hotspotView, modelController: self.viewModel.modelController, isEditable: true)
        }

        newElements.forEach { $0.refresh() }

        self.accessibilityElements = newElements
        self.hotspotView.setAccessibilityChildren(newElements)
    }

    private func setupCreateHotspotAccessibilityActions(isProEnabled: Bool) {
        var customActions = [NSAccessibilityCustomAction]()
        customActions.append(NSAccessibilityCustomAction(name: "Create Rectangle Hotspot") {
            self.createRectangleHotspot()
            return true
        })

        if isProEnabled {
            customActions.append(NSAccessibilityCustomAction(name: "Create Oval Hotspot") {
                self.createOvalHotspot()
                return true
            })

            let sides = [5, 6, 8, 10]
            for side in sides {
                customActions.append(NSAccessibilityCustomAction(name: "Create \(side)-sided Hotspot") {
                    self.createPolygonHotspot(withSides: side)
                    return true
                })
            }
        }

        self.hotspotView.setAccessibilityCustomActions(customActions.reversed())
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
        self.updateHotspotAccessibilityElements()
    }

    func didCommitEdit(in layoutEngine: ImageEditorHotspotLayoutEngine) {
        self.viewModel.imageContent.hotspots = self.layoutEngine.hotspots.compactMap(\.imageHotspot)
    }
}
