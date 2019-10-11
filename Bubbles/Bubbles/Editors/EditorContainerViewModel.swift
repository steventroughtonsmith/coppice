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

class EditorContainerViewModel: NSObject {
    weak var view: EditorContainerView?

    let modelController: ModelController
    init(modelController: ModelController) {
        self.modelController = modelController
        super.init()
    }

    var pageContentTypeObservation: NSKeyValueObservation?

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

    var editor: NSViewController? {
        if (UserDefaults.standard.bool(forKey: "M3UseDebugEditors")) {
            return self.debugEditor
        }
        if let canvas = self.currentObject as? Canvas {
            let viewModel = CanvasEditorViewModel(canvas: canvas, modelController: self.modelController)
            return CanvasEditorViewController(viewModel: viewModel)
        }
        if let page = self.currentObject as? Page {
            let viewModel = PageEditorViewModel(page: page, modelController: self.modelController)
            return PageEditorViewController(viewModel: viewModel)
        }
        return nil
    }


    private var debugEditor: NSViewController? {
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
