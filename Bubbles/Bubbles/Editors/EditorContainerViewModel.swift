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

    let modelController: BubblesModelController
    init(modelController: BubblesModelController) {
        self.modelController = modelController
        super.init()
    }

    var currentObjectID: ModelID? {
        didSet {
            self.view?.editorChanged()
        }
    }

    var currentObject: ModelObject? {
        guard let objectID = self.currentObjectID else {
            return nil
        }
        return self.modelController.object(with: objectID)
    }

    var editor: Editor? {
        if (UserDefaults.standard.bool(forKey: "M3UseDebugEditors")) {
            return self.debugEditor
        }
        if let page = self.currentObject as? Page {
            switch page.content.contentType {
            case .text:
                let viewModel = TextEditorViewModel(textContent: (page.content as! TextPageContent),
                                                    modelController: self.modelController)
                return TextEditorViewController(viewModel: viewModel)
            }
        }
        return nil
    }


    private var debugEditor: Editor? {
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
