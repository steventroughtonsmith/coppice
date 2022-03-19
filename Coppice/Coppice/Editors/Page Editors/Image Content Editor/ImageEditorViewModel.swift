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

    @objc dynamic let imageContent: ImagePageContent
    let viewMode: PageContentEditorViewMode
    init(imageContent: ImagePageContent, viewMode: PageContentEditorViewMode, documentWindowViewModel: DocumentWindowViewModel) {
        self.imageContent = imageContent
        self.viewMode = viewMode
        self.hotspotCollection = ImageHotspotCollection(imageContent: imageContent)
        super.init(documentWindowViewModel: documentWindowViewModel)
        self.regenerateCroppedImage()

        self.subscribers[.image] = imageContent.publisher(for: \.image).receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.regenerateCroppedImage()
        }
        self.subscribers[.cropRect] = imageContent.publisher(for: \.cropRect).receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.regenerateCroppedImage()
        }
    }

    let hotspotCollection: ImageHotspotCollection

    //MARK: - Subscribers
    private enum SubscriberKey {
        case image
        case cropRect
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]


    //MARK: - Properties

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == #keyPath(image) {
            keyPaths.insert("imageContent.image")
        } else if key == #keyPath(accessibilityDescription) {
            keyPaths.insert("imageContent.imageDescription")
        } else if key == #keyPath(cropRect) {
            keyPaths.insert("imageContent.cropRect")
        } else if key == #keyPath(croppedImage) {
            keyPaths.insert("cachedCroppedImage")
        }
        return keyPaths
    }

    @objc dynamic var image: NSImage? {
        get { self.imageContent.image }
        set {
            self.documentWindowViewModel.registerStartOfEditing()
            self.imageContent.image = newValue
            self.regenerateCroppedImage()
        }
    }

    @objc dynamic var cropRect: CGRect {
        get { self.imageContent.cropRect }
        set {
            self.imageContent.cropRect = newValue
            self.regenerateCroppedImage()
        }
    }

    @objc dynamic var accessibilityDescription: String? {
        return self.imageContent.imageDescription
    }

    //MARK: - Cropped Image
    @objc dynamic private var cachedCroppedImage: NSImage?
    @objc dynamic var croppedImage: NSImage? {
        get { self.cachedCroppedImage }
        set {
            self.image = newValue
        }
    }

    private func regenerateCroppedImage() {
        guard let image = self.image else {
            self.cachedCroppedImage = nil
            return
        }

        let croppedImage = NSImage(size: self.cropRect.size)
        croppedImage.lockFocus()
        //TODO: iOS don't flip the image
        image.draw(in: CGRect(origin: .zero, size: self.cropRect.size), from: self.cropRect.flipped(in: CGRect(origin: .zero, size: image.size)), operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        croppedImage.unlockFocus()

        self.cachedCroppedImage = croppedImage
    }


	//MARK: - Rotation
	func rotateLeft() {
		if let rotatedImage = self.image?.rotate90Degrees(.left) {
			self.image = rotatedImage
		}
	}

	func rotateRight() {
		if let rotatedImage = self.image?.rotate90Degrees(.right) {
			self.image = rotatedImage
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


	//mode (.view, .crop, .hotspot)

	//rotate left/right
	//.cropInsets
	//.hotspots

	//LinkEditor
}
