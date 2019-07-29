//
//  ModelCollection.swift
//  Bubbles
//
//  Created by Martin Pilkington on 28/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

struct ModelCollectionObservation<Type: CollectableModelObject> {
    fileprivate let id = UUID()
    fileprivate let filterIDs: [UUID]?
    fileprivate let changeHandler: (Type) -> Void

    fileprivate func notifyOfChange(to object: Type) {
        if ((self.filterIDs == nil) || (self.filterIDs?.contains(object.id) == true)) {
            changeHandler(object)
        }
    }
}

class ModelCollection<Type: CollectableModelObject> {

    weak var modelController: ModelController?

    private(set) var all = Set<Type>()

    func objectWithID(_ id: UUID) -> Type? {
        return self.all.first { $0.id == id }
    }

    func newObject() -> Type {
        let newObject = Type()
        newObject.collection = self
        self.all.insert(newObject)
        return newObject
    }

    func delete(_ object: Type) {
        if let index = self.all.firstIndex(where: {$0.id == object.id}) {
            self.all.remove(at: index)
        }
    }

    func objectsForRelationship<R: ModelObject>(on object: R, inverseKeyPath: ReferenceWritableKeyPath<Type, R?>) -> Set<Type> {
        return self.all.filter { $0[keyPath: inverseKeyPath]?.id == object.id }
    }


    private var observers = [ModelCollectionObservation<Type>]()

    func addObserver(filterBy uuids: [UUID]? = nil, changeHandler: @escaping (Type) -> Void) -> ModelCollectionObservation<Type> {
        let observer = ModelCollectionObservation(filterIDs: uuids, changeHandler: changeHandler)
        self.observers.append(observer)
        return observer
    }

    func removeObserver(_ observer: ModelCollectionObservation<Type>) {
        if let index = self.observers.firstIndex(where: { $0.id == observer.id }) {
            self.observers.remove(at: index)
        }
    }

    func notifyOfChange<Value>(to object: Type, keyPath: ReferenceWritableKeyPath<Type, Value>) {
        for observer in self.observers {
            observer.notifyOfChange(to: object)
        }
    }

    func registerUndoAction(withName name: String? = nil, invocationBlock: @escaping (ModelCollection<Type>) -> Void) {
        guard let undoManager = self.modelController?.undoManager else {
            return
        }

        if let name = name {
            undoManager.setActionName(name)
        }
        undoManager.registerUndo(withTarget: self, handler: invocationBlock)
    }

    func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<Type, Value>, ofObjectWithID id: UUID) {
        guard let object = self.objectWithID(id) else {
            return
        }
        object[keyPath: keyPath] = value
    }
}
