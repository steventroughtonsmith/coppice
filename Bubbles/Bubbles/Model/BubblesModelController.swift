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

        self.addModelCollection(for: Canvas.self) { _ in Canvas() }
        self.addModelCollection(for: CanvasPage.self) { _ in CanvasPage() }
        self.addModelCollection(for: Page.self) { context in
            let title = (context["title"] as? String)
            return Page(title: title)
        }
    }

    func object(with id: ModelID) -> ModelObject? {
        switch id.modelType {
        case Canvas.modelType:
            return self.collection(for: Canvas.self).objectWithID(id)
        case Page.modelType:
            return self.collection(for: Page.self).objectWithID(id)
        case CanvasPage.modelType:
            return self.collection(for: CanvasPage.self).objectWithID(id)
        default:
            fatalError("Model type '\(id.modelType)' does not exist")
        }
    }
}

extension BubblesModelController {
    func createTestData() {
        self.collection(for: Canvas.self).disableUndo {
            let canvas1 = self.collection(for: Canvas.self).newObject()
            canvas1.title = "First"
            let canvas2 = self.collection(for: Canvas.self).newObject()
            canvas2.title = "Second!"
        }

        self.collection(for: Page.self).disableUndo {
            let page1 = self.collection(for: Page.self).newObject()
            page1.title = "Foo"
            let content = TextPageContent()
            content.text = NSAttributedString(string: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce vehicula sit amet felis ac commodo. Sed quis faucibus nibh. Nam ut urna libero.")
            page1.content = content
            let page2 = self.collection(for: Page.self).newObject()
            page2.title = "Bar"
            let page3 = self.collection(for: Page.self).newObject()
            page3.title = "Baz"
        }
    }

}
