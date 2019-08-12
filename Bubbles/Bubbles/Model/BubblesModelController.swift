//
//  BubblesModelController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class BubblesModelController: NSObject, ModelController {
    var collections = [ModelType: Any]()

    let undoManager: UndoManager
    init(undoManager: UndoManager) {
        self.undoManager = undoManager
        super.init()

        self.add(ModelCollection<Canvas>() { _ in Canvas() }, for: Canvas.modelType)
        self.add(ModelCollection<CanvasPage>() { _ in CanvasPage() }, for: CanvasPage.modelType)

        let pageCollection = ModelCollection<Page>() { context in
            let title = (context["title"] as? String)
            return Page(title: title)
        }
        self.add(pageCollection, for: Page.modelType)
    }
    
    var canvases: ModelCollection<Canvas> { self.collection(for: Canvas.modelType) as! ModelCollection<Canvas> }
    var pages: ModelCollection<Page> { self.collection(for: Page.modelType) as! ModelCollection<Page> }
    var canvasPages: ModelCollection<CanvasPage> { self.collection(for: CanvasPage.modelType) as! ModelCollection<CanvasPage> }

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
}

extension BubblesModelController {
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
            let content = TextPageContent()
            content.text = NSAttributedString(string: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce vehicula sit amet felis ac commodo. Sed quis faucibus nibh. Nam ut urna libero.")
            page1.content = content
            let page2 = self.pages.newObject()
            page2.title = "Bar"
            let page3 = self.pages.newObject()
            page3.title = "Baz"
        }
    }

}
