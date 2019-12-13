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

    class ChangeGroup {
        private(set) var changes = [ModelType: ChangeType]()
        func registerChange(for object: ModelType, ofType changeType: ChangeType) {
            self.changes[object] = changeType
        }

        func notify(_ observers: [Observation]) {
            for (object, changeType) in self.changes {
                observers.forEach { $0.notifyOfChange(to: object, changeType: changeType) }
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
        self.disableUndo {
            setupBlock?(newObject)
        }
        self.insert(newObject)
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
        guard let currentChangeGroup = self.changeGroups.last else {
            let changeGroup = ChangeGroup()
            changeGroup.registerChange(for: object, ofType: changeType)
            changeGroup.notify(self.observers)
            return
        }
        currentChangeGroup.registerChange(for: object, ofType: changeType)
    }

    private var changeGroups = [ChangeGroup]()


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

extension ModelCollection: ModelChangeGroupHandler {
    func pushChangeGroup() {
        self.changeGroups.append(ChangeGroup())
    }

    func popChangeGroup() {
        let changeGroup = self.changeGroups.popLast()
        changeGroup?.notify(self.observers)
    }
}
