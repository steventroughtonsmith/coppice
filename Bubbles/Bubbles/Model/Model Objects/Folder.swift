//
//  Folder.swift
//  Bubbles
//
//  Created by Martin Pilkington on 08/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation


final class Folder: NSObject, CollectableModelObject, FolderContainable {
    static var modelType: ModelType = ModelType(rawValue: "Folder")!
    static let rootFolderTitle = "__ROOT__FOLDER__"

    var id: ModelID = ModelID(modelType: Folder.modelType)
    weak var collection: ModelCollection<Folder>?

    @objc dynamic var title: String = "New Folder" {
        didSet { self.didChange(\.title, oldValue: oldValue) }
    }

    weak var containingFolder: Folder?
    var contents: [FolderContainable] = [] {
        didSet { self.didChange(\.contents, oldValue: oldValue) }
    }

    func insert(_ objects: [FolderContainable], below item: FolderContainable? = nil) {
        self.modelController?.pushChangeGroup()
        var contents: [FolderContainable?] = self.contents

        //We need to get the index before processing as the item we're inserting above might be an existing item
        var index: Int? = nil
        if let item = item, let indexOfItem = contents.firstIndex(where: { $0?.id == item.id }) {
            index = contents.index(after: indexOfItem)
        }

        for object in objects {
            if object.containingFolder == self {
                if let index = contents.firstIndex(where: { $0?.id == object.id}) {
                    contents[index] = nil
                }
            } else {
                object.removeFromContainingFolder()
                object.containingFolder = self
            }
        }

        if let insertionIndex = index {
            contents.insert(contentsOf: objects, at: insertionIndex)
        } else {
            contents.insert(contentsOf: objects, at: 0)
        }

        self.contents = contents.compactMap { $0 }
        self.modelController?.popChangeGroup()
    }

    func remove(_ objects: [FolderContainable]) {
        for object in objects {
            if let index = self.contents.firstIndex(where: {$0.id == object.id}) {
                self.contents.remove(at: index)
            }
        }
    }



    //MARK: - Plist
    var plistRepresentation: [String : Any] {
        return [
            "id": self.id.stringRepresentation,
            "title": self.title,
            "contents": self.contents.map { $0.id.stringRepresentation }
        ]
    }

    func update(fromPlistRepresentation plist: [String : Any]) throws {
        guard self.id.stringRepresentation == (plist["id"] as? String) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        guard let title = plist["title"] as? String else {
            throw ModelObjectUpdateErrors.attributeNotFound("title")
        }
        self.title = title

        guard let contentsStrings = plist["contents"] as? [String] else {
            throw ModelObjectUpdateErrors.attributeNotFound("contents")
        }

        let contentsIDs = contentsStrings.compactMap { ModelID(string: $0) }
        let contents = contentsIDs.compactMap { self.modelController?.object(with: $0) as? FolderContainable }
        guard contentsStrings.count == contents.count else {
            throw ModelObjectUpdateErrors.attributeNotFound("contents")
        }
        contents.forEach { $0.containingFolder = self }
        self.contents = contents
    }
}
