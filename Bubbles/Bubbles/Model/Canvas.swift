//
//  Canvas.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

final class Canvas: NSObject, CollectableModelObject {
    static let modelType: ModelType = ModelType(rawValue: "Canvas")!

    var id = ModelID(modelType: Canvas.modelType)
    weak var collection: ModelCollection<Canvas>?

    func objectWasInserted() {
        self.sortIndex = self.collection?.all.count ?? 0
    }

    
    //MARK: - Attributes
    @objc var title: String = "New Canvas" {
        didSet { self.didChange(\.title, oldValue: oldValue) }
    }
    var dateCreated = Date()
    var dateModified = Date()
    @objc dynamic var sortIndex = 0 {
        didSet { self.didChange(\.sortIndex, oldValue: oldValue) }
    }


    //MARK: - Relationships
    var pages: Set<CanvasPage> {
        return self.relationship(for: \.canvas)
    }


    //MARK: - Helpers
    func add(_ page: Page, centredOn point: CGPoint? = nil) {
        guard let canvasPage = self.modelController?.collection(for: CanvasPage.self).newObject() else {
            return
        }
        canvasPage.page = page

        if let point = point {
            canvasPage.position = point.minus(CGPoint(x: canvasPage.size.width / 2, y: canvasPage.size.height / 2)).rounded()
        }

        canvasPage.canvas = self
    }
}
