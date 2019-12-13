//
//  ModelObject.swift
//  Bubbles
//
//  Created by Martin Pilkington on 26/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

enum ModelObjectUpdateErrors: Error, Equatable {
    case idsDontMatch
    case attributeNotFound(String)
    case modelControllerNotSet
}

//MARK: -
/// The protocol root for model objects, used where generics can't be
protocol ModelObject: class {
    var id: ModelID { get set }
    static var modelType: ModelType { get }
    var modelController: ModelController? { get }

    init()


    static func modelID(with: UUID) -> ModelID
    static func modelID(withUUIDString: String) -> ModelID?

    //MARK: - Plist
    var plistRepresentation: [String: Any] { get }

    /// Update the model using the supplied Plist values.
    ///
    /// Implementations should check the plist to see if IDs match before updating
    /// - Parameter plist: The plist to update
    func update(fromPlistRepresentation plist: [String: Any]) throws

    static var modelFileProperties: [String] { get }
}


extension ModelObject {
    static func modelID(with uuid: UUID) -> ModelID {
        return ModelID(modelType: self.modelType, uuid: uuid)
    }

    static func modelID(withUUIDString uuidString: String) -> ModelID? {
        return ModelID(modelType: self.modelType, uuidString: uuidString)
    }

    static var modelFileProperties: [String] {
        return []
    }
}


//MARK: -
/// A more extensive ModelObject protocol supporting undo, relationships, etc
protocol CollectableModelObject: ModelObject, Hashable {
    var collection: ModelCollection<Self>? { get set }

    /// Called after the object was inserted into the collection. The `collection` property is guaranteed to get set when this is called
    func objectWasInserted()

    /// Called before the object will be deleted. The object should break any relationship
    func objectWasDeleted()

    /// Register an undo action for an attribute change
    /// - Parameter oldValue: The old value of the attribute
    /// - Parameter keyPath: The keypath of the attribute
    func didChange<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, oldValue: T)


    /// Return the objects for a to-many relationship
    /// - Parameter keyPath: The keypath on the returned type that holds the inverse relationship
    func relationship<T: CollectableModelObject>(for keyPath: ReferenceWritableKeyPath<T, Self?>) -> Set<T>

    func performUpdate(_ updateBlock: (Self) -> Void)
}


//MARK: -
extension CollectableModelObject {
    var modelController: ModelController? {
        return self.collection?.modelController
    }

    static func create(in modelController: ModelController, setupBlock: ((Self) -> Void)? = nil) -> Self {
        return modelController.collection(for: Self.self).newObject(setupBlock: setupBlock)
    }

    func objectWasInserted() {}

    func objectWasDeleted() {}
    
    func didChange<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, oldValue: T) {
        let id = self.id
        self.collection?.notifyOfChange(to: self)
        self.collection?.registerUndoAction(withName: nil) { (collection) in
            collection.setValue(oldValue, for: keyPath, ofObjectWithID: id)
        }
    }

    func didChangeRelationship<T: CollectableModelObject>(_ keyPath: ReferenceWritableKeyPath<Self, T?>, oldValue: T?, inverseKeyPath: KeyPath<T, Set<Self>>) {
        guard let relationshipObject = oldValue ?? self[keyPath: keyPath],
              let selfCollection = self.collection,
              let relationshipCollection = relationshipObject.collection else {
                return
        }
        let id = self.id
        let oldID = oldValue?.id
        selfCollection.notifyOfChange(to: self)
        selfCollection.registerUndoAction(withName: nil) { (collection) in
            var value: T? = nil
            if let objectID = oldID,
               let oldObject = relationshipCollection.objectWithID(objectID) {
                value = oldObject
            }
            collection.setValue(value, for: keyPath, ofObjectWithID: id)
        }

        relationshipCollection.notifyOfChange(to: relationshipObject)
    }

    func relationship<T: CollectableModelObject>(for keyPath: ReferenceWritableKeyPath<T, Self?>) -> Set<T> {
        guard let modelController = self.modelController else {
            return Set<T>()
        }
        let collection = modelController.collection(for: T.self)
        return collection.objectsForRelationship(on: self, inverseKeyPath: keyPath)
    }

    func performUpdate(_ updateBlock: (Self) -> Void) {
        self.modelController?.pushChangeGroup()
        updateBlock(self)
        self.modelController?.popChangeGroup()
    }
}


struct ModelFile {
    let type: String
    let filename: String?
    let data: Data?
    let metadata: [String: Any]?

    var plistRepresentation: [String: Any] {
        var plist: [String: Any] = ["type": self.type]
        if let filename = self.filename {
            plist["filename"] = filename
        }
        if let metadata = self.metadata {
            plist["metadata"] = metadata
        }
        return plist
    }
}
