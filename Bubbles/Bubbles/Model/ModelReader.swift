//
//  ModelReader.swift
//  Bubbles
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ModelReader: NSObject {

    enum Errors: Error {
        case corruptData
        case missingCollection(String)
        case missingID([String: Any])
    }

    let modelController: ModelController
    init(modelController: ModelController) {
        self.modelController = modelController
        super.init()
    }

    func read(_ fileWrapper: FileWrapper) throws {
        guard let plistWrapper = fileWrapper.fileWrappers?["data.plist"],
            let contentWrappers = fileWrapper.fileWrappers?["content"]?.fileWrappers else {
            return
        }

        guard let plistData = plistWrapper.regularFileContents else {
            return
        }

        guard let plistDict = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
            throw Errors.corruptData
        }
        let plist = try ModelPlist(plist: plistDict)

        self.modelController.settings.update(withPlist: plist.settings)

        self.createAndDeleteObjects(ofType: CanvasPage.self, using: plist.canvasPages)
        self.createAndDeleteObjects(ofType: Canvas.self, using: plist.canvases)
        self.createAndDeleteObjects(ofType: Page.self, using: plist.pages)

        try self.updateObjects(ofType: Page.self, using: plist.pages, content: contentWrappers)
        try self.updateObjects(ofType: Canvas.self, using: plist.canvases, content: contentWrappers)
        try self.updateObjects(ofType: CanvasPage.self, using: plist.canvasPages, content: contentWrappers)

    }

    private func createAndDeleteObjects<T: CollectableModelObject>(ofType type: T.Type, using plistItems: [ModelID: [String: Any]]) {
        let collection = self.modelController.collection(for: type)
        collection.disableUndo {
            let existingIDs = Set(collection.all.map { $0.id })
            let newIDs = Set(plistItems.keys)

            let itemsToAdd = newIDs.subtracting(existingIDs)
            let itemsToRemove = existingIDs.subtracting(newIDs)

            for id in itemsToRemove {
                if let item = collection.objectWithID(id) {
                    collection.delete(item)
                }
            }

            for id in itemsToAdd {
                collection.newObject() { $0.id = id }
            }
        }
    }

    private func updateObjects<T: CollectableModelObject>(ofType type: T.Type, using plist: [ModelID: [String: Any]], content: [String: FileWrapper]) throws {
        let collection = self.modelController.collection(for: type)

        try collection.disableUndo {
            for (id, plistItem) in plist {
                guard let item = collection.objectWithID(id) else {
                    return
                }

                var plistItemWithModelFiles = plistItem
                for modelFileProperty in type.modelFileProperties {
                    let modelFilePlist = plistItemWithModelFiles[modelFileProperty] as? [String: Any]
                    guard let type = modelFilePlist?["type"] as? String else {
                        continue
                    }

                    let metadata = modelFilePlist?["metadata"] as? [String: Any]
                    let modelFile: ModelFile
                    if let filename = modelFilePlist?["filename"] as? String {
                        let data = content[filename]?.regularFileContents
                        modelFile = ModelFile(type: type, filename: filename, data: data, metadata: metadata)
                    } else {
                        modelFile = ModelFile(type: type, filename: nil, data: nil, metadata: metadata)
                    }

                    plistItemWithModelFiles[modelFileProperty] = modelFile
                }
                try item.update(fromPlistRepresentation: plistItemWithModelFiles)
            }
        }
    }
}


private struct ModelPlist {
    let canvases: [ModelID: [String: Any]]
    let pages: [ModelID: [String: Any]]
    let canvasPages: [ModelID: [String: Any]]
    let settings: [String: Any]

    init(plist: [String: Any]) throws {
        guard let canvasPlist = plist["canvases"] as? [[String: Any]] else {
            throw ModelReader.Errors.missingCollection("canvases")
        }
        guard let pagesPlist = plist["pages"] as? [[String: Any]] else {
            throw ModelReader.Errors.missingCollection("pages")
        }
        guard let canvasPagesPlist = plist["canvasPages"] as? [[String: Any]] else {
            throw ModelReader.Errors.missingCollection("canvasPages")
        }

        self.canvases = try ModelPlist.mapToModelIDKeys(canvasPlist)
        self.pages = try ModelPlist.mapToModelIDKeys(pagesPlist)
        self.canvasPages = try ModelPlist.mapToModelIDKeys(canvasPagesPlist)

        self.settings = (plist["settings"] as? [String: Any]) ?? [:]
    }

    private static func mapToModelIDKeys(_ collection: [[String: Any]]) throws -> [ModelID: [String: Any]] {
        var newCollection = [ModelID: [String: Any]]()
        for plistItem in collection {
            guard let idString = plistItem["id"] as? String, let id = ModelID(string: idString) else {
                throw ModelReader.Errors.missingID(plistItem)
            }
            newCollection[id] = plistItem
        }
        return newCollection
    }
}
