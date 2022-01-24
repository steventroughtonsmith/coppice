//
//  ImageEditorInspectorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class ImageEditorInspectorViewModel: BaseInspectorViewModel {
    @objc dynamic let editorViewModel: ImageEditorViewModel
    init(editorViewModel: ImageEditorViewModel) {
        self.editorViewModel = editorViewModel
        super.init()
    }

    override var title: String? {
        return NSLocalizedString("Image", comment: "Image editor inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.imageEditor"
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == #keyPath(imageDescription) {
            keyPaths.insert("self.editorViewModel.imageContent.imageDescription")
        }
        return keyPaths
    }

    @objc dynamic var imageDescription: String {
        get {
			return self.editorViewModel.imageContent.imageDescription ?? ""
        }
        set {
			self.editorViewModel.imageContent.imageDescription = newValue
        }
    }
}
