//
//  ModelCollection.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

public enum ModelChangeType: Equatable {
    case update
    case insert
    case delete
}


public class ModelCollection<ModelType: CollectableModelObject> {

    public struct Observation {
        fileprivate let id = UUID()
        fileprivate let filterIDs: [ModelID]?
        fileprivate let changeHandler: (Change) -> Void

        fileprivate func notifyOfChange(_ change: Change) {
            if ((self.filterIDs == nil) || (self.filterIDs?.contains(change.object.id) == true)) {
                changeHandler(change)
            }
        }
    }

    public class Change {
        public let object: ModelType
        public init(object: ModelType) {
            self.object = object
        }

        public private(set) var changeType: ModelChangeType = .update

        private var keyPaths = Set<PartialKeyPath<ModelType>>()
        public var updatedKeyPaths: Set<PartialKeyPath<ModelType>> {
            guard self.changeType == .update else {
                return Set()
            }
            return self.keyPaths
        }

        public func didUpdate<T>(_ keyPath: KeyPath<ModelType, T>) -> Bool {
            let partialKeyPath = keyPath as PartialKeyPath<ModelType>
            return self.updatedKeyPaths.contains(partialKeyPath)
        }

        public func registerChange(ofType changeType: ModelChangeType, keyPath: PartialKeyPath<ModelType>? = nil) {
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

    public init() {}

    public weak var modelController: ModelController?

    public private(set) var all = Set<ModelType>()

    public func objectWithID(_ id: ModelID) -> ModelType? {
        return self.all.first { $0.id == id }
    }

    public func contains(_ object: ModelType) -> Bool {
        return self.all.contains(object)
    }

    public typealias ModelSetupBlock = (ModelType) -> Void
    @discardableResult public func newObject(setupBlock: ModelSetupBlock? = nil) -> ModelType {
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

    public func delete(_ object: ModelType) {
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
    public func objectsForRelationship<R: ModelObject>(on object: R, inverseKeyPath: ReferenceWritableKeyPath<ModelType, R?>) -> Set<ModelType> {
        return self.all.filter { $0[keyPath: inverseKeyPath]?.id == object.id }
    }


    //MARK: - Observation
    private var observers = [Observation]()

    public func addObserver(filterBy uuids: [ModelID]? = nil, changeHandler: @escaping (Change) -> Void) -> Observation {
        let observer = Observation(filterIDs: uuids, changeHandler: changeHandler)
        self.observers.append(observer)
        return observer
    }

    public func removeObserver(_ observer: Observation) {
        if let index = self.observers.firstIndex(where: { $0.id == observer.id }) {
            self.observers.remove(at: index)
        }
    }

    public func notifyOfChange(to object: ModelType, changeType: ModelChangeType = .update, keyPath: PartialKeyPath<ModelType>? = nil) {
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
    public func disableUndo(_ caller: () throws -> Void) rethrows {
        guard let undoManager = self.modelController?.undoManager else {
            try caller()
            return
        }

        undoManager.disableUndoRegistration()
        try caller()
        undoManager.enableUndoRegistration()
    }

    public func registerUndoAction(withName name: String? = nil, invocationBlock: @escaping (ModelCollection<ModelType>) -> Void) {
        guard let undoManager = self.modelController?.undoManager else {
            return
        }

        if let name = name {
            undoManager.setActionName(name)
        }
        undoManager.registerUndo(withTarget: self, handler: invocationBlock)
    }

    public func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<ModelType, Value>, ofObjectWithID id: ModelID) {
        guard let object = self.objectWithID(id) else {
            return
        }
        object[keyPath: keyPath] = value
    }
}

extension ModelCollection: ModelChangeGroupHandler {
    public func pushChangeGroup() {
        self.changeGroups.append(ChangeGroup())
    }

    public func popChangeGroup() {
        let changeGroup = self.changeGroups.popLast()
        changeGroup?.notify(self.observers)
    }
}
