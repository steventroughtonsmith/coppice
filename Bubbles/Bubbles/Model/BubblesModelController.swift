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

        self.addModelCollection(for: Canvas.self)
        self.addModelCollection(for: CanvasPage.self)
        self.addModelCollection(for: Page.self) 
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
            self.collection(for: Canvas.self).newObject() { $0.title = "First" }
            self.collection(for: Canvas.self).newObject() { $0.title = "Second!" }
        }

        self.collection(for: Page.self).disableUndo {
            let page1 = self.collection(for: Page.self).newObject() { page in
                page.title = "Foo"
                let content = TextPageContent()
                content.text = NSAttributedString(string: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce vehicula sit amet felis ac commodo. Sed quis faucibus nibh. Nam ut urna libero.")
                page.content = content
            }
            self.collection(for: Page.self).newObject() { page in
                page.title = "Bar"
                let content = TextPageContent()
                let mutableText = NSMutableAttributedString(string: "This page links to this page")
                mutableText.addAttribute(.link, value: page1.linkToPage(from: page).url, range: NSRange(location: 19, length: 9))
                content.text = mutableText
                page.content = content
            }
            self.collection(for: Page.self).newObject() { $0.title = "Baz" }
        }
    }

}


//MARK: - Collection extensions
extension ModelCollection where ModelType == Page {
    @discardableResult func newPage(fromFileAt url: URL) -> Page? {
        guard let resourceValues = try? url.resourceValues(forKeys: Set([.typeIdentifierKey])),
            let typeIdentifier = resourceValues.typeIdentifier else {
            return nil
        }

        guard let contentType = PageContentType.contentType(forUTI: typeIdentifier) else {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        let page = self.newObject() {
            $0.title = (url.lastPathComponent as NSString).deletingPathExtension
            $0.content = contentType.createContent(data: data)
        }
        return page
    }
}
