//
//  ModelObject.swift
//  Bubbles
//
//  Created by Martin Pilkington on 26/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

/// Used for determining model type
struct ModelType: RawRepresentable, Equatable, Hashable {
    typealias RawValue = String

    let rawValue: String
    init?(rawValue: String) {
        self.rawValue = rawValue
    }
}


//MARK: -
/// The protocol root for model objects, used where generics can't be
protocol ModelObject: class {
    var id: UUID { get set }
    static var modelType: ModelType { get }
    var modelController: ModelController? { get }
}


//MARK: -
/// A more extensive ModelObject protocol supporting undo, relationships, etc
protocol CollectableModelObject: ModelObject, Hashable {
    var collection: ModelCollection<Self>? { get set }

    init()

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
    
    func didChange<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, oldValue: T) {
        let id = self.id
        self.collection?.notifyOfChange(to: self, keyPath: keyPath)
        self.collection?.registerUndoAction(withName: nil) { (collection) in
            collection.setValue(oldValue, for: keyPath, ofObjectWithID: id)
        }
    }

    func relationship<T: CollectableModelObject>(for keyPath: ReferenceWritableKeyPath<T, Self?>) -> Set<T> {
        guard let modelController = self.modelController else {
            return Set<T>()
        }
        guard let collection = modelController.collection(for: T.modelType) as? ModelCollection<T> else {
            print("Collection types did not match")
            return Set<T>()
        }
        return collection.objectsForRelationship(on: self, inverseKeyPath: keyPath)
    }
}
