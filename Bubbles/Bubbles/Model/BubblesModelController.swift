//
//  BubblesModelController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class BubblesModelController: NSObject, ModelController {
    var allCollections = [ModelType: Any]()
    let settings = ModelSettings()

    lazy var identifier: UUID = {
        if let identifierString = self.settings.string(for: .documentIdentifier),
            let identifier = UUID(uuidString: identifierString) {
            return identifier
        }

        let identifier = UUID()
        self.settings.set(identifier.uuidString, for: .documentIdentifier)
        return identifier
    }()

    let undoManager: UndoManager
    init(undoManager: UndoManager) {
        self.undoManager = undoManager
        super.init()

        self.addModelCollection(for: Canvas.self)
        self.addModelCollection(for: CanvasPage.self)
        self.addModelCollection(for: Page.self)
        self.addModelCollection(for: Folder.self)
    }

    func object(with id: ModelID) -> ModelObject? {
        switch id.modelType {
        case Canvas.modelType:
            return self.collection(for: Canvas.self).objectWithID(id)
        case Page.modelType:
            return self.collection(for: Page.self).objectWithID(id)
        case CanvasPage.modelType:
            return self.collection(for: CanvasPage.self).objectWithID(id)
        case Folder.modelType:
            return self.collection(for: Folder.self).objectWithID(id)
        default:
            assertionFailure("Model type '\(id.modelType)' does not exist")
            return nil
        }
    }
}


//MARK: - ModelSettingsKeys
extension ModelSettings.Setting {
    static let pageSortKeySetting = ModelSettings.Setting(rawValue: "pageSortKey")
    static let rootFolder = ModelSettings.Setting(rawValue: "rootFolder")
    static let documentIdentifier = ModelSettings.Setting(rawValue: "identifier")
}
