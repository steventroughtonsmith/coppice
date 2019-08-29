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

class ImageEditorViewModel: NSObject {
    weak var view: ImageEditorView?

    let imageContent: ImagePageContent
    let modelController: BubblesModelController
    init(imageContent: ImagePageContent, modelController: BubblesModelController) {
        self.imageContent = imageContent
        self.modelController = modelController
        super.init()
    }

    @objc dynamic var image: NSImage? {
        get { self.imageContent.image }
        set { self.imageContent.image = newValue }
    }
}
