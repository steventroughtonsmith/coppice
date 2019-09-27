//
//  ModelObject.swift
//  Bubbles
//
//  Created by Martin Pilkington on 26/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

//MARK: -
/// The protocol root for model objects, used where generics can't be
protocol ModelObject: class {
    var id: ModelID { get set }
    static var modelType: ModelType { get }
    var modelController: ModelController? { get }

    static func modelID(with: UUID) -> ModelID
    static func modelID(withUUIDString: String) -> ModelID?
}


extension ModelObject {
    static func modelID(with uuid: UUID) -> ModelID {
        return ModelID(modelType: self.modelType, uuid: uuid)
    }

    static func modelID(withUUIDString uuidString: String) -> ModelID? {
        return ModelID(modelType: self.modelType, uuidString: uuidString)
    }
}


//MARK: -
/// A more extensive ModelObject protocol supporting undo, relationships, etc
protocol CollectableModelObject: ModelObject, Hashable {
    var collection: ModelCollection<Self>? { get set }

    /// Called after the object was inserted into the collection. The `collection` property is guaranteed to get set when this is called
    func objectWasInserted()

    /// Called before the object will be deleted. The object should break any relationship
    func objectWillBeDeleted()

    /// Register an undo action for an attribute change
    /// - Parameter oldValue: The old value of the attribute
    /// - Parameter keyPath: The keypath of the attribute
    func didChange<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, oldValue: T)


    /// Return the objects for a to-many relationship
    /// - Parameter keyPath: The keypath on the returned type that holds the inverse relationship
    func relationship<T: CollectableModelObject>(for keyPath: ReferenceWritableKeyPath<T, Self?>) -> Set<T>
}


//MARK: -
extension CollectableModelObject {
    var modelController: ModelController? {
        return self.collection?.modelController
    }

    func objectWasInserted() {}

    func objectWillBeDeleted() {}
    
    func didChange<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, oldValue: T) {
        let id = self.id
        self.collection?.notifyOfChange(to: self)
        self.collection?.registerUndoAction(withName: nil) { (collection) in
            collection.setValue(oldValue, for: keyPath, ofObjectWithID: id)
        }
    }

    func didChangeRelationship<T: CollectableModelObject>(_ keyPath: ReferenceWritableKeyPath<Self, T?>, oldValue: T?, inverseKeyPath: KeyPath<T, Set<Self>>) {
        let id = self.id
        self.collection?.notifyOfChange(to: self)
        self.collection?.registerUndoAction(withName: nil) { (collection) in
            collection.setValue(oldValue, for: keyPath, ofObjectWithID: id)
        }

        if let value = oldValue ?? self[keyPath: keyPath] {
        	value.collection?.notifyOfChange(to: value)
        }
    }

    func relationship<T: CollectableModelObject>(for keyPath: ReferenceWritableKeyPath<T, Self?>) -> Set<T> {
        guard let modelController = self.modelController else {
            return Set<T>()
        }
        let collection = modelController.collection(for: T.self)
        return collection.objectsForRelationship(on: self, inverseKeyPath: keyPath)
    }
}
