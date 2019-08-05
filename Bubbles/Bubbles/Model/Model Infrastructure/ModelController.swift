//
//  ModelController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 02/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol ModelController: class {
    var undoManager: UndoManager { get }
    var collections: [ModelType: Any] {get set}
    func add<T>(_ modelCollection: ModelCollection<T>, for modelType: ModelType)
    func removeModelCollection(for modelType: ModelType)

    func collection(for modelType: ModelType) -> Any
    func object(with id: ModelID) -> ModelObject?
}

extension ModelController {
    func add<T>(_ modelCollection: ModelCollection<T>, for modelType: ModelType) {
        self.collections[modelType] = modelCollection
        modelCollection.modelController = self
    }

    func removeModelCollection(for modelType: ModelType) {
        self.collections.removeValue(forKey: modelType)
    }

    func collection(for modelType: ModelType) -> Any {
        guard let model = self.collections[modelType] else {
            fatalError("Collection with type '\(modelType)' does not exist")
        }
        return model
    }
}
