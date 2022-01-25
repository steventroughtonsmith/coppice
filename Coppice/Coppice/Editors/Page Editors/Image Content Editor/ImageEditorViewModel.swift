//
//  ImageEditorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 13/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
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
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == "image") {
            keyPaths.insert("imageContent.image")
        }
        if key == #keyPath(accessibilityDescription) {
            keyPaths.insert("imageContent.imageDescription")
        }
        return keyPaths
    }

    @objc dynamic var image: NSImage? {
        get { self.imageContent.image }
        set {
            self.documentWindowViewModel.registerStartOfEditing()
            self.imageContent.image = newValue
        }
    }

    @objc dynamic var accessibilityDescription: String? {
        return self.imageContent.imageDescription
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



	//mode (.view, .crop, .hotspot)

	//rotate left/right
	//.cropInsets
	//.hotspots

	//LinkEditor
}
