//
//  ModelWriter.swift
//  Bubbles
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ModelWriter: NSObject {
    let modelController: ModelController
    init(modelController: ModelController) {
        self.modelController = modelController
    }

    func generateFileWrapper() throws -> FileWrapper {
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

        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let dataPlistWrapper = FileWrapper(regularFileWithContents: plistData)
        let contentFileWrapper = self.fileWrapper(forContent: content)

        return FileWrapper(directoryWithFileWrappers: [
            "data.plist": dataPlistWrapper,
            "content": contentFileWrapper
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

    func fileWrapper(forContent content: [ModelFile]) -> FileWrapper {
        var contentWrappers = [String: FileWrapper]()
        content.forEach {
            if let data = $0.data, let filename = $0.filename {
                contentWrappers[filename] = FileWrapper(regularFileWithContents: data)
            }
        }
        return FileWrapper(directoryWithFileWrappers: contentWrappers)
    }
}


/*
 CanvasPage
    - id
    - frame

    - page
    - canvas
    - parent


Canvas
     - id
     - dateCreate
     - dateModified
     - sortIndex
     - viewPort

 Page
     - id
     - title
     - tags
     - dateCreated
     - dateModified
     - userPreferredSize
     - contentType
     - content
 */





/*

 struct ModelPlistAttribute<ModelType: ModelObject> {
     let plistKey: String

     init<PropertyType>(plistKey: String,
          propertyKeyPath: ReferenceWritableKeyPath<ModelType, PropertyType>,
          valueConverter: @escaping ((Any?) -> PropertyType) = { $0 as! PropertyType },
          plistConverter: @escaping ((PropertyType) -> Any) = { $0 }) {
         self.plistKey = plistKey

         self.read = { modelObject in
             let value = modelObject[keyPath: propertyKeyPath]
             return plistConverter(value)
         }

         self.write = { value, modelObject in
             let typedValue = valueConverter(value)
             modelObject[keyPath: propertyKeyPath] = typedValue
         }
     }

     var read: (ModelType) -> Any?
     var write: (Any?, ModelType) -> ()
 }

 protocol PlistConvertable {
     associatedtype ModelType: ModelObject
     static var plistAttributeMap: [ModelPlistAttribute<ModelType>] { get }
 }
*/
