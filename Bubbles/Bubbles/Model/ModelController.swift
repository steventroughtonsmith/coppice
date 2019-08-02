//
//  ModelController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ModelController: NSObject {
    let undoManager: UndoManager
    init(undoManager: UndoManager) {
        self.undoManager = undoManager
        super.init()
        self.canvases.modelController = self
        self.pages.modelController = self
        self.canvasPages.modelController = self
    }

    func createTestData() {
        self.canvases.disableUndo {
            let canvas1 = self.canvases.newObject()
            canvas1.title = "First"
            let canvas2 = self.canvases.newObject()
            canvas2.title = "Second!"
        }

        self.pages.disableUndo {
            let page1 = self.pages.newObject()
            page1.title = "Foo"
            let page2 = self.pages.newObject()
            page2.title = "Bar"
            let page3 = self.pages.newObject()
            page3.title = "Baz"
        }
    }



    let canvases = ModelCollection<Canvas>()
    let pages = ModelCollection<Page>()
    let canvasPages = ModelCollection<CanvasPage>()

    func collection(for modelType: ModelType) -> Any {
        switch modelType {
        case Canvas.modelType:
            return self.canvases
        case Page.modelType:
            return self.pages
        case CanvasPage.modelType:
            return self.canvasPages
        default:
            fatalError("Model type '\(modelType)' does not exist")
        }
    }

    func object(with id: ModelID) -> ModelObject? {
        switch id.modelType {
        case Canvas.modelType:
            return self.canvases.objectWithID(id)
        case Page.modelType:
            return self.pages.objectWithID(id)
        case CanvasPage.modelType:
            return self.canvasPages.objectWithID(id)
        default:
            fatalError("Model type '\(id.modelType)' does not exist")
        }
    }

    //MARK: - Undo

    func registerUndoAction(withName name: String? = nil, invocationBlock: @escaping (ModelController) -> Void) {
        if let name = name {
            self.undoManager.setActionName(name)
        }
        self.undoManager.registerUndo(withTarget: self, handler: invocationBlock)
    }


}
