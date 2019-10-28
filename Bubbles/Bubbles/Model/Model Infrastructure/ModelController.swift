//
//  ModelController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 02/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol ModelController: class, ModelChangeGroupHandler {
    var undoManager: UndoManager { get }
    var collections: [ModelType: Any] {get set}
    @discardableResult func addModelCollection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T>
    func removeModelCollection<T: CollectableModelObject>(for type: T.Type)

    func collection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T>
    func object(with id: ModelID) -> ModelObject?
}

extension ModelController {
    @discardableResult func addModelCollection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T> {
        let modelCollection = ModelCollection<T>()
        modelCollection.modelController = self
        self.collections[type.modelType] = modelCollection
        return modelCollection
    }

    func removeModelCollection<T: CollectableModelObject>(for type: T.Type) {
        self.collections.removeValue(forKey: type.modelType)
    }

    func collection<T: CollectableModelObject>(for type: T.Type) -> ModelCollection<T> {
        guard let model = self.collections[type.modelType] as? ModelCollection<T> else {
            fatalError("Collection with type '\(type.modelType)' does not exist")
        }
        return model
    }

    func pushChangeGroup() {
        self.collections.values
            .compactMap { $0 as? ModelChangeGroupHandler }
            .forEach { $0.pushChangeGroup() }
    }

    func popChangeGroup() {
        self.collections.values
            .compactMap { $0 as? ModelChangeGroupHandler }
            .forEach { $0.popChangeGroup() }
    }
}
