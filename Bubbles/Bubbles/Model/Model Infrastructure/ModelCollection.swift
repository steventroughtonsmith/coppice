//
//  ModelCollection.swift
//  Bubbles
//
//  Created by Martin Pilkington on 28/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

enum ModelChangeType: Equatable {
    case update
    case insert
    case delete
}


class ModelCollection<ModelType: CollectableModelObject> {


    struct Observation {
        fileprivate let id = UUID()
        fileprivate let filterIDs: [ModelID]?
        fileprivate let changeHandler: (Change) -> Void

        fileprivate func notifyOfChange(_ change: Change) {
            if ((self.filterIDs == nil) || (self.filterIDs?.contains(change.object.id) == true)) {
                changeHandler(change)
            }
        }
    }

    class Change {
        let object: ModelType
        init(object: ModelType) {
            self.object = object
        }

        private(set) var changeType: ModelChangeType = .update

        private var keyPaths = Set<PartialKeyPath<ModelType>>()
        var updatedKeyPaths: Set<PartialKeyPath<ModelType>> {
            guard self.changeType == .update else {
                return Set()
            }
            return self.keyPaths
        }

        func didUpdate<T>(_ keyPath: KeyPath<ModelType, T>) -> Bool {
            let partialKeyPath = keyPath as PartialKeyPath<ModelType>
            return self.updatedKeyPaths.contains(partialKeyPath)
        }

        func registerChange(ofType changeType: ModelChangeType, keyPath: PartialKeyPath<ModelType>? = nil) {
            if changeType == .update {
                precondition(keyPath != nil, "Must supply a key path for an update change")
                self.keyPaths.insert(keyPath!)
            }
            self.changeType = changeType
        }
    }

    class ChangeGroup {
        private(set) var changes = [ModelType: Change]()
        private func change(for object: ModelType) -> Change{
            if let change = self.changes[object] {
                return change
            }

            let change = Change(object: object)
            self.changes[object] = change
            return change
        }

        func registerChange(to object: ModelType, changeType: ModelChangeType, keyPath: PartialKeyPath<ModelType>? = nil) {
            self.change(for: object).registerChange(ofType: changeType, keyPath: keyPath)
        }

        func notify(_ observers: [Observation]) {
            for (_, change) in self.changes {
                observers.forEach { $0.notifyOfChange(change) }
            }
        }
    }

    weak var modelController: ModelController?

    private(set) var all = Set<ModelType>()

    func objectWithID(_ id: ModelID) -> ModelType? {
        return self.all.first { $0.id == id }
    }

    typealias ModelSetupBlock = (ModelType) -> Void
    @discardableResult func newObject(setupBlock: ModelSetupBlock? = nil) -> ModelType {
        self.modelController?.pushChangeGroup()
        let newObject = ModelType()
        newObject.collection = self
        self.insert(newObject)
        self.disableUndo {
            setupBlock?(newObject)
        }
        self.notifyOfChange(to: newObject, changeType: .insert)
        self.modelController?.popChangeGroup()
        return newObject
    }

    private func insert(_ object: ModelType) {
        self.all.insert(object)

        self.registerUndoAction() { collection in
            collection.delete(object)
        }

        self.disableUndo {
            object.objectWasInserted()
        }
        self.notifyOfChange(to: object, changeType: .insert)
    }

    func delete(_ object: ModelType) {
        if let index = self.all.firstIndex(where: {$0.id == object.id}) {
            self.registerUndoAction() { collection in
                collection.insert(object)
            }
            self.all.remove(at: index)
            self.disableUndo {
                object.objectWasDeleted()
            }
            self.notifyOfChange(to: object, changeType: .delete)
        }
    }


    //MARK: - Relationships
    func objectsForRelationship<R: ModelObject>(on object: R, inverseKeyPath: ReferenceWritableKeyPath<ModelType, R?>) -> Set<ModelType> {
        return self.all.filter { $0[keyPath: inverseKeyPath]?.id == object.id }
    }


    //MARK: - Observation
    private var observers = [Observation]()

    func addObserver(filterBy uuids: [ModelID]? = nil, changeHandler: @escaping (Change) -> Void) -> Observation {
        let observer = Observation(filterIDs: uuids, changeHandler: changeHandler)
        self.observers.append(observer)
        return observer
    }

    func removeObserver(_ observer: Observation) {
        if let index = self.observers.firstIndex(where: { $0.id == observer.id }) {
            self.observers.remove(at: index)
        }
    }

    func notifyOfChange(to object: ModelType, changeType: ModelChangeType = .update, keyPath: PartialKeyPath<ModelType>? = nil) {
        guard let currentChangeGroup = self.changeGroups.last else {
            let changeGroup = ChangeGroup()
            changeGroup.registerChange(to: object, changeType: changeType, keyPath: keyPath)
            changeGroup.notify(self.observers)
            return
        }
        currentChangeGroup.registerChange(to: object, changeType: changeType, keyPath: keyPath)
    }

    private var changeGroups = [ChangeGroup]()


    //MARK: - Undo
    func disableUndo(_ caller: () throws -> Void) rethrows {
        guard let undoManager = self.modelController?.undoManager else {
            try caller()
            return
        }

        undoManager.disableUndoRegistration()
        try caller()
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

extension ModelCollection: ModelChangeGroupHandler {
    func pushChangeGroup() {
        self.changeGroups.append(ChangeGroup())
    }

    func popChangeGroup() {
        let changeGroup = self.changeGroups.popLast()
        changeGroup?.notify(self.observers)
    }
}
