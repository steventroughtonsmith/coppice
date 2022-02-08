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

protocol ImageEditorViewProtocol: AnyObject {}

class ImageEditorViewModel: ViewModel {
    weak var view: ImageEditorViewProtocol?

    @objc dynamic let imageContent: ImagePageContent
    let isInCanvas: Bool
    init(imageContent: ImagePageContent, isInCanvas: Bool, documentWindowViewModel: DocumentWindowViewModel) {
        self.imageContent = imageContent
        self.isInCanvas = isInCanvas
        super.init(documentWindowViewModel: documentWindowViewModel)
        self.regenerateCroppedImage()

        self.subscribers[.image] = imageContent.publisher(for: \.image).receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.regenerateCroppedImage()
        }
        self.subscribers[.cropRect] = imageContent.publisher(for: \.cropRect).receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.regenerateCroppedImage()
        }
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case image
        case cropRect
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]


    //MARK: - Properties

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == "image") {
            keyPaths.insert("imageContent.image")
        }
        if key == #keyPath(accessibilityDescription) {
            keyPaths.insert("imageContent.imageDescription")
        }
        if key == #keyPath(cropRect) {
            keyPaths.insert("imageContent.cropRect")
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
    @objc dynamic var croppedImage: NSImage?

    private func regenerateCroppedImage() {
        guard let image = self.image else {
            self.croppedImage = nil
            return
        }

        let croppedImage = NSImage(size: self.cropRect.size)
        croppedImage.lockFocus()
        //TODO: iOS don't flip the image
        image.draw(in: CGRect(origin: .zero, size: self.cropRect.size), from: self.cropRect.flipped(in: CGRect(origin: .zero, size: image.size)), operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        croppedImage.unlockFocus()

        self.croppedImage = croppedImage
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

	@Published var mode: Mode = .view


	//mode (.view, .crop, .hotspot)

	//rotate left/right
	//.cropInsets
	//.hotspots

	//LinkEditor
}
