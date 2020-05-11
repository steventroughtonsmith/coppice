//
//  ModelRelationship.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

@propertyWrapper
struct ModelObjectReference<T: CollectableModelObject> {
    var modelID: ModelID?
    var modelController: ModelController?

    var wrappedValue: T? {
        get {
            guard let id = self.modelID else {
                return nil
            }
            return self.valueCollection?.objectWithID(id)
        }
        set {
            self.modelID = newValue?.id
        }
    }

    var projectedValue: Self {
        get { self }
        set { self = newValue}
    }

    private var valueCollection: ModelCollection<T>? {
        return self.modelController?.collection(for: T.self)
    }

    mutating func performCleanUp() {
        self.modelController = nil
    }
}
