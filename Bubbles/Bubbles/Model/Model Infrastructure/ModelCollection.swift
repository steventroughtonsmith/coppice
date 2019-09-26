//
//  ModelCollection.swift
//  Bubbles
//
//  Created by Martin Pilkington on 28/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

class ModelCollection<ModelType: CollectableModelObject> {
    enum ChangeType: Equatable {
        case update
        case insert
        case delete
    }

    struct Observation {
        fileprivate let id = UUID()
        fileprivate let filterIDs: [ModelID]?
        fileprivate let changeHandler: (ModelType, ChangeType) -> Void

        fileprivate func notifyOfChange(to object: ModelType, changeType: ChangeType) {
            if ((self.filterIDs == nil) || (self.filterIDs?.contains(object.id) == true)) {
                changeHandler(object, changeType)
            }
        }
    }

    typealias CustomInitialiser = ([String: Any]) -> ModelType
    let objectInitialiser: CustomInitialiser
    init(objectInitialiser: @escaping CustomInitialiser) {
        self.objectInitialiser = objectInitialiser
    }


    weak var modelController: ModelController?

    private(set) var all = Set<ModelType>()

    func objectWithID(_ id: ModelID) -> ModelType? {
        return self.all.first { $0.id == id }
    }

    @discardableResult func newObject(context: [String: Any] = [:]) -> ModelType {
        let newObject = self.objectInitialiser(context)
        newObject.collection = self
        self.all.insert(newObject)
        self.disableUndo {
            newObject.objectWasInserted()
        }
        self.notifyOfChange(to: newObject, changeType: .insert)
        return newObject
    }

    func delete(_ object: ModelType) {
        if let index = self.all.firstIndex(where: {$0.id == object.id}) {
            self.all.remove(at: index)
            self.notifyOfChange(to: object, changeType: .delete)
        }
    }


    //MARK: - Relationships
    func objectsForRelationship<R: ModelObject>(on object: R, inverseKeyPath: ReferenceWritableKeyPath<ModelType, R?>) -> Set<ModelType> {
        return self.all.filter { $0[keyPath: inverseKeyPath]?.id == object.id }
    }


    //MARK: - Observation
    private var observers = [Observation]()

    func addObserver(filterBy uuids: [ModelID]? = nil, changeHandler: @escaping (ModelType, ChangeType) -> Void) -> Observation {
        let observer = Observation(filterIDs: uuids, changeHandler: changeHandler)
        self.observers.append(observer)
        return observer
    }

    func removeObserver(_ observer: Observation) {
        if let index = self.observers.firstIndex(where: { $0.id == observer.id }) {
            self.observers.remove(at: index)
        }
    }

    func notifyOfChange(to object: ModelType, changeType: ModelCollection.ChangeType = .update) {
        for observer in self.observers {
            observer.notifyOfChange(to: object, changeType: changeType)
        }
    }


    //MARK: - Undo
    func disableUndo(_ caller: () -> Void) {
        guard let undoManager = self.modelController?.undoManager else {
            caller()
            return
        }

        undoManager.disableUndoRegistration()
        caller()
        undoManager.enableUndoRegistration()
    }

    func registerUndoAction(withName name: String? = nil, invocationBlock: @escaping (ModelCollection<ModelType>) -> Void) {
        guard let undoManager = self.modelController?.undoManager else {
            return
        }

        if let name = name {
            undoManager.setActionName(name)
        }
        undoManager.registerUndo(withTarget: self, handler: invocationBlock)
    }

    func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<ModelType, Value>, ofObjectWithID id: ModelID) {
        guard let object = self.objectWithID(id) else {
            return
        }
        object[keyPath: keyPath] = value
    }
}
