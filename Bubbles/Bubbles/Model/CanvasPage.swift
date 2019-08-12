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
    weak var page: Page? {
        didSet { self.didChange(\.page, oldValue: oldValue) }
    }
    weak var canvas: Canvas? {
        didSet { self.didChange(\.canvas, oldValue: oldValue) }
    }
    var position: CGPoint = .zero {
        didSet { self.didChange(\.position, oldValue: oldValue) }
    }
    var size: CGSize = .zero {
        didSet { self.didChange(\.size, oldValue: oldValue) }
    }

    
    //MARK: - Relationships
    weak var parent: CanvasPage?
    var children: Set<CanvasPage> {
        self.relationship(for: \.parent)
    }
}
