//
//  ImageEditorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 13/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

protocol ImageEditorView: class {
}

class ImageEditorViewModel: ViewModel {
    weak var view: ImageEditorView?

    @objc dynamic let imageContent: ImagePageContent
    let mode: EditorMode
    init(imageContent: ImagePageContent, documentWindowViewModel: DocumentWindowViewModel, mode: EditorMode = .editing) {
        self.imageContent = imageContent
        self.mode = mode
        super.init(documentWindowViewModel: documentWindowViewModel)
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == "image") {
            keyPaths.insert("imageContent.image")
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
}
