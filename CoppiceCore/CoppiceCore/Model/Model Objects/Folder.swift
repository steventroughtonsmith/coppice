//
//  Folder.swift
//  Coppice
//
//  Created by Martin Pilkington on 08/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import M3Data

@Model
final public class Folder: FolderContainable {
    public static let rootFolderTitle = "__ROOT__FOLDER__"

    //MARK: - Persisted Attributes
    @Attribute public var title: String = "New Folder"
    @Attribute public var dateCreated: Date = Date()
    @Attribute private var contents: [ModelID] = [] {
        didSet { self.didChange(\.contents, oldValue: oldValue) }
    }

    //MARK: - Calculated properties
    public var dateModified: Date {
        guard self.folderContents.count > 0 else {
            return self.dateCreated
        }

        let sorted = self.folderContents.sorted(by: { $0.dateModified > $1.dateModified })
        return sorted[0].dateModified
    }

    public weak var containingFolder: Folder? {
        didSet { self.didChange(\.containingFolder, oldValue: oldValue) }
    }

    public var folderContents: [FolderContainable] {
        get {
            return self.contents.compactMap { self.modelController?.object(with: $0) as? FolderContainable }
        }
        set {
            self.contents = newValue.map(\.id)
        }
    }

    public var sortType: String {
        return "0Folder"
    }

    //MARK: - Folder Management
    public func insert(_ objects: [FolderContainable], below item: FolderContainable? = nil) {
        self.modelController?.pushChangeGroup()
        var contents: [FolderContainable?] = self.folderContents

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

        self.folderContents = contents.compactMap { $0 }
        self.modelController?.popChangeGroup()
    }

    public func remove(_ objects: [FolderContainable]) {
        for object in objects {
            if let index = self.folderContents.firstIndex(where: { $0.id == object.id }) {
                self.folderContents.remove(at: index)
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
        self.folderContents = self.folderContents.sorted(by: method.compare)
    }


    //MARK: - Path
    public var pathString: String? {
        guard self.title != Folder.rootFolderTitle else {
            return nil
        }

        var folders = [Folder]()
        var currentFolder: Folder? = self
        while currentFolder != nil, currentFolder?.title != Folder.rootFolderTitle {
            folders.append(currentFolder!)
            currentFolder = currentFolder?.containingFolder
        }

        return folders.map(\.title).joined(separator: "  ◁  ")
    }
}
