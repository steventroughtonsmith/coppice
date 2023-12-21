//
//  ImageEditorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 13/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import Combine
import CoppiceCore

protocol ImageEditorViewProtocol: AnyObject {
    func switchToCanvasCropMode()
    func exitCanvasCropMode()
}

class ImageEditorViewModel: ViewModel {
    weak var view: ImageEditorViewProtocol?

    let imageContent: ImagePageContent
    let viewMode: PageContentEditorViewMode
    let pageLinkManager: ImagePageLinkManager?
    init(imageContent: ImagePageContent, viewMode: PageContentEditorViewMode, documentWindowViewModel: DocumentWindowViewModel, pageLinkManager: ImagePageLinkManager?) {
        self.imageContent = imageContent
        self.viewMode = viewMode
        self.hotspotCollection = ImageHotspotCollection(imageContent: imageContent)
        self.pageLinkManager = pageLinkManager
        super.init(documentWindowViewModel: documentWindowViewModel)
        self.regenerateCroppedImage()

        self.subscribers[.image] = imageContent.$image.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.willChangeValue(for: \.image)
            self?.willChangeValue(for: \.isLoading)
            self?.didChangeValue(for: \.image)
            self?.didChangeValue(for: \.isLoading)
            self?.needsRegenerateCroppedImage = true
        }
        self.subscribers[.cropRect] = imageContent.$cropRect.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.willChangeValue(for: \.cropRect)
            self?.didChangeValue(for: \.cropRect)
            self?.needsRegenerateCroppedImage = true
        }
        self.subscribers[.imageDescription] = imageContent.$imageDescription.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.willChangeValue(for: \.accessibilityDescription)
            self?.didChangeValue(for: \.accessibilityDescription)
        }
        self.subscribers[.searchString] = documentWindowViewModel.publisher(for: \.searchString).sink { [weak self] searchString in
            self?.updateHightlightedRect(withSearchString: searchString)
        }

        self.subscribers[.isProEnabled] = CoppiceSubscriptionManager.shared.$state
            .sink { [weak self] newValue in
                self?.isProEnabled = (newValue == .enabled)
            }

        self.pageLinkManager?.setNeedsRescan()
    }

    let hotspotCollection: ImageHotspotCollection

    @Published private(set) var isProEnabled = false

    //MARK: - Subscribers
    private enum SubscriberKey {
        case image
        case cropRect
        case imageDescription
        case searchString
        case isProEnabled
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]


    //MARK: - Properties

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
         if key == #keyPath(croppedImage) {
            keyPaths.insert("cachedCroppedImage")
        }
        return keyPaths
    }

    @objc dynamic var image: NSImage? {
        get { self.imageContent.image }
        set {
            self.documentWindowViewModel.registerStartOfEditing()
            self.imageContent.setImage(newValue, operation: .replace)
            self.needsRegenerateCroppedImage = true
        }
    }

    @objc dynamic var cropRect: CGRect {
        get { self.imageContent.cropRect }
        set {
            self.imageContent.cropRect = newValue
            self.needsRegenerateCroppedImage = true
        }
    }

    @objc dynamic var accessibilityDescription: String? {
        return self.imageContent.imageDescription
    }

    @objc dynamic var isLoading: Bool {
        return self.image != nil && self.cachedCroppedImage == nil
    }

    //MARK: - Cropped Image
    @objc dynamic private var cachedCroppedImage: NSImage?
    @objc dynamic var croppedImage: NSImage? {
        get { self.cachedCroppedImage }
        set {
            self.image = newValue
        }
    }

    private var needsRegenerateCroppedImage: Bool = false {
        didSet {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.regenerateCroppedImage), object: nil)
            if self.needsRegenerateCroppedImage {
                self.perform(#selector(self.regenerateCroppedImage), with: nil, afterDelay: 0)
            }
        }
    }

    @objc dynamic private func regenerateCroppedImage() {
        guard self.image != nil else {
            self.cachedCroppedImage = nil
            return
        }

        self.documentWindowViewModel.modelController.croppedImageCache.croppedImage(for: self.imageContent) { [weak self] image in
            self?.cachedCroppedImage = image
        }
    }

	//MARK: - Rotation
	func rotateLeft() {
		if let rotatedImage = self.image?.rotate90Degrees(.left) {
            self.imageContent.setImage(rotatedImage, operation: .rotate(.left))
		}
	}

	func rotateRight() {
		if let rotatedImage = self.image?.rotate90Degrees(.right) {
            self.imageContent.setImage(rotatedImage, operation: .rotate(.right))
		}
	}

	//MARK: - Mode
    enum Mode: Int {
		case view
		case crop
		case hotspot
	}

    @Published private(set) var mode: Mode = .view

    func updateMode(_ mode: Mode) {
        self.mode = mode
        if self.viewMode == .canvas, case .crop = mode {
            self.view?.switchToCanvasCropMode()
            self.mode = .view
        } else {
            self.view?.exitCanvasCropMode()
        }
    }


    //MARK: - Linking
    lazy var linkEditor: ImageEditorLinkEditor = {
        let linkEditor = ImageEditorLinkEditor()
        linkEditor.viewModel = self
        return linkEditor
    }()

    //MARK: - Search
    var highlightRect: CGRect?

    private func updateHightlightedRect(withSearchString searchString: String?) {
        guard
            let searchString = searchString,
            let match = self.imageContent.firstMatch(forSearchString: searchString) as? ImagePageContent.Match,
            let range = Range(match.range, in: match.string)
        else {
            self.highlightRect = nil
            return
        }

        self.highlightRect = match.recognisedText.normalisedBoundingBox(for: range,
                                                                        imageSize: self.image?.size ?? .zero,
                                                                        orientation: self.imageContent.orientation)
    }
}
