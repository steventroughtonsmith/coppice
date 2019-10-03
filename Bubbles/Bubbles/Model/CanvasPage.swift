//
//  CanvasPage.swift
//  Bubbles
//
//  Created by Martin Pilkington on 22/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

final class CanvasPage: NSObject, CollectableModelObject {
    static let modelType: ModelType = ModelType(rawValue: "CanvasPage")!

    var id = ModelID(modelType: CanvasPage.modelType)
    weak var collection: ModelCollection<CanvasPage>?

    //MARK: - Attributes
    var frame: CGRect = .zero {
        didSet { self.didChange(\.frame, oldValue: oldValue) }
    }

    
    //MARK: - Relationships
    weak var page: Page? {
        didSet {
            if let page = self.page {
                self.frame.size = page.contentSize
            }
            self.didChangeRelationship(\.page, oldValue: oldValue, inverseKeyPath: \.canvases)
        }
    }
    weak var canvas: Canvas? {
        didSet { self.didChangeRelationship(\.canvas, oldValue: oldValue, inverseKeyPath: \.pages) }
    }

    weak var parent: CanvasPage?
    var children: Set<CanvasPage> {
        self.relationship(for: \.parent)
    }

    func objectWillBeDeleted() {
        self.page = nil
        self.canvas = nil
        self.parent = nil
    }
}
