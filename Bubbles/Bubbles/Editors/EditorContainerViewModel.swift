//
//  EditorContainerViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

protocol EditorContainerView: class {
    func editorChanged()
}

protocol Editor {
    var view: NSView { get }
}

class EditorContainerViewModel: NSObject {
    weak var view: EditorContainerView?

    let modelController: ModelController
    init(modelController: ModelController) {
        self.modelController = modelController
        super.init()
    }

    var currentObject: Any? {
        didSet {
            self.view?.editorChanged()
        }
    }

    var editor: Editor? {
        if let canvas = self.currentObject as? Canvas {
            let viewModel = DebugCanvasEditorViewModel(canvas: canvas, modelController: self.modelController)
            return DebugCanvasEditor(viewModel: viewModel)
        }
        if let page = self.currentObject as? Page {
            let viewModel = DebugPageEditorViewModel(page: page)
            return DebugPageEditor(viewModel: viewModel)
        }
        return nil
    }
}
