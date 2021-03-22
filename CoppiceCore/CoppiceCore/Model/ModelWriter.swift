//
//  ModelWriter.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

public class ModelWriter: NSObject {
    public let modelController: ModelController
    public let documentVersion: Int
    public init(modelController: ModelController, documentVersion: Int) {
        self.modelController = modelController
        self.documentVersion = documentVersion
        super.init()
    }

    public func generateFileWrapper() throws -> FileWrapper {
        var content = [ModelFile]()
        var plist = [String: Any]()

        let (canvases, canvasContent) = self.generateData(for: Canvas.self)
        plist["canvases"] = canvases
        content.append(contentsOf: canvasContent)

        let (pages, pageContent) = self.generateData(for: Page.self)
        plist["pages"] = pages
        content.append(contentsOf: pageContent)

        let (canvasPages, canvasPageContent) = self.generateData(for: CanvasPage.self)
        plist["canvasPages"] = canvasPages
        content.append(contentsOf: canvasPageContent)

        let (folders, folderContent) = self.generateData(for: Folder.self)
        plist["folders"] = folders
        content.append(contentsOf: folderContent)

        plist["settings"] = self.modelController.settings.plistRepresentation

        plist["version"] = self.documentVersion

        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let dataPlistWrapper = FileWrapper(regularFileWithContents: plistData)
        let contentFileWrapper = self.fileWrapper(forContent: content)

        return FileWrapper(directoryWithFileWrappers: [
            "data.plist": dataPlistWrapper,
            "content": contentFileWrapper,
        ])
    }

    private func generateData<T: CollectableModelObject>(for type: T.Type) -> ([Any], [ModelFile]) {
        var plistItems = [Any]()
        var files = [ModelFile]()

        //We'll sort the items so we get a somewhat deterministic ordering on disk
        let sortedItems = self.modelController.collection(for: type).all.sorted { $0.id.uuid.uuidString < $1.id.uuid.uuidString }
        sortedItems.forEach { (object) in
            let plist = object.plistRepresentation.mapValues { (value) -> Any in
                guard let file = value as? ModelFile else {
                    return value
                }

                files.append(file)
                return file.plistRepresentation
            }
            plistItems.append(plist)
        }

        return (plistItems, files)
    }

    public func fileWrapper(forContent content: [ModelFile]) -> FileWrapper {
        var contentWrappers = [String: FileWrapper]()
        content.forEach {
            if let data = $0.data, let filename = $0.filename {
                contentWrappers[filename] = FileWrapper(regularFileWithContents: data)
            }
        }
        return FileWrapper(directoryWithFileWrappers: contentWrappers)
    }
}
