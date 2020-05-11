//
//  ImageEditorInspectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 03/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorInspectorViewModel: BaseInspectorViewModel {
    @objc dynamic let imageContent: ImagePageContent
    let modelController: ModelController
    init(imageContent: ImagePageContent, modelController: ModelController) {
        self.imageContent = imageContent
        self.modelController = modelController
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
            keyPaths.insert("self.imageContent.imageDescription")
        }
        return keyPaths
    }

    @objc dynamic var imageDescription: String {
        get {
            return self.imageContent.imageDescription ?? ""
        }
        set {
            self.imageContent.imageDescription = newValue
        }
    }
}
