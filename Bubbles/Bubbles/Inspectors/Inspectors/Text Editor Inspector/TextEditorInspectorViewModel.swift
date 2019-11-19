//
//  TextEditorInspectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 19/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

class TextEditorInspectorViewModel: BaseInspectorViewModel {
    let editor: Any
    let modelController: ModelController
    init(editor: Any, modelController: ModelController) {
        self.editor = editor
        self.modelController = modelController
        super.init()
    }

    override var title: String? {
        return NSLocalizedString("Text", comment: "Text editor inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.textEditor"
    }
}
