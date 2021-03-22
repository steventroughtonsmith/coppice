//
//  Folder.swift
//  Coppice
//
//  Created by Martin Pilkington on 08/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation


final public class Folder: NSObject, CollectableModelObject, FolderContainable {
    public static var modelType: ModelType = ModelType(rawValue: "Folder")!
    public static let rootFolderTitle = "__ROOT__FOLDER__"

    public var id: ModelID = ModelID(modelType: Folder.modelType)
    public weak var collection: ModelCollection<Folder>?

    @objc dynamic public var title: String = "New Folder" {
        didSet { self.didChange(\.title, oldValue: oldValue) }
    }

    public var dateCreated: Date = Date()

    public var dateModified: Date {
        guard self.contents.count > 0 else {
            return self.dateCreated
        }

        let sorted = self.contents.sorted(by: { $0.dateModified > $1.dateModified })
        return sorted[0].dateModified
    }

    public weak var containingFolder: Folder? {
        didSet { self.didChange(\.containingFolder, oldValue: oldValue) }
    }

    public var contents: [FolderContainable] = [] {
        didSet { self.didChange(\.contents, oldValue: oldValue) }
    }

    public var sortType: String {
        return "0Folder"
    }

    public private(set) var otherProperties = [String: Any]()

    public func insert(_ objects: [FolderContainable], below item: FolderContainable? = nil) {
        self.modelController?.pushChangeGroup()
        var contents: [FolderContainable?] = self.contents

        //We need to get the index before processing as the item we're inserting above might be an existing item
        var index: Int? = nil
        if let item = item, let indexOfItem = contents.firstIndex(where: { $0?.id == item.id }) {
            index = contents.index(after: indexOfItem)
        }

        for object in objects {
            if object.containingFolder == self {
                if let index = contents.firstIndex(where: { $0?.id == object.id }) {
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

    public func remove(_ objects: [FolderContainable]) {
        for object in objects {
            if let index = self.contents.firstIndex(where: { $0.id == object.id }) {
                self.contents.remove(at: index)
            }
        }
    }


    //MARK: - Sorting
    public enum SortingMethod: CaseIterable {
        case title
        case type
        case dateCreated
        case lastModified

        public var localizedString: String {
            switch self {
            case .title: return NSLocalizedString("Title", comment: "Title folder sorting method")
            case .type: return NSLocalizedString("Type", comment: "Type folder sorting method")
            case .dateCreated: return NSLocalizedString("Date Created", comment: "Date Created folder sorting method")
            case .lastModified: return NSLocalizedString("Last Modified", comment: "Last Modified folder sorting method")
            }
        }

        public func compare(_ first: FolderContainable, _ second: FolderContainable) -> Bool {
            switch self {
            case .title: return first.title < second.title
            case .type: return first.sortType < second.sortType
            case .dateCreated: return first.dateCreated > second.dateCreated
            case .lastModified: return first.dateModified > second.dateModified
            }
        }
    }

    public func sort(using method: SortingMethod) {
        self.contents = self.contents.sorted(by: method.compare)
    }


    //MARK: - Plist
    enum PlistKeys: String, CaseIterable {
        case id
        case title
        case contents
        case dateCreated
    }

    public var plistRepresentation: [String: Any] {
        var plist = self.otherProperties

        plist[PlistKeys.id.rawValue] = self.id.stringRepresentation
        plist[PlistKeys.title.rawValue] = self.title
        plist[PlistKeys.contents.rawValue] = self.contents.map { $0.id.stringRepresentation }
        plist[PlistKeys.dateCreated.rawValue] = self.dateCreated

        return plist
    }

    public func update(fromPlistRepresentation plist: [String: Any]) throws {
        guard self.id.stringRepresentation == (plist[PlistKeys.id.rawValue] as? String) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        guard let title = plist[PlistKeys.title.rawValue] as? String else {
            throw ModelObjectUpdateErrors.attributeNotFound(PlistKeys.title.rawValue)
        }
        guard let dateCreated = plist[PlistKeys.dateCreated.rawValue] as? Date else {
            throw ModelObjectUpdateErrors.attributeNotFound(PlistKeys.dateCreated.rawValue)
        }

        guard let contentsStrings = plist[PlistKeys.contents.rawValue] as? [String] else {
            throw ModelObjectUpdateErrors.attributeNotFound(PlistKeys.contents.rawValue)
        }

        let contentsIDs = contentsStrings.compactMap { ModelID(string: $0) }
        let contents = contentsIDs.compactMap { self.modelController?.object(with: $0) as? FolderContainable }
        guard contentsStrings.count == contents.count else {
            throw ModelObjectUpdateErrors.attributeNotFound(PlistKeys.contents.rawValue)
        }
        contents.forEach { $0.containingFolder = self }

        self.title = title
        self.dateCreated = dateCreated
        self.contents = contents

        let plistKeys = PlistKeys.allCases.map(\.rawValue)
        self.otherProperties = plist.filter { (key, _) -> Bool in
            return plistKeys.contains(key) == false
        }
    }
}
