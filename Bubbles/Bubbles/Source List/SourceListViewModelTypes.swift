//
//  SidebarViewModelTypes.swift
//  Bubbles
//
//  Created by Martin Pilkington on 31/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

class SourceListNodeCollection: NSObject {
    private(set) var containsPages: Bool = false
    private(set) var containsFolders: Bool = false
    private(set) var containsCanvases: Bool = false

    private(set) var nodesShareParent: Bool = true

    private(set) var nodes: [SourceListNode] = []

    var count: Int {
        return nodes.count
    }

    func add(_ node: SourceListNode) {
        if let lastNode = self.nodes.last, self.nodesShareParent {
            self.nodesShareParent = (lastNode.parent === node.parent)
        }

        nodes.append(node)
        switch node.item {
        case .canvases, .canvas(_):
            self.containsCanvases = true
        case .page(_):
            self.containsPages = true
        case .folder(_):
            self.containsFolders = true
        }
    }
}

class SourceListNode: NSObject {
    enum CellType {
        case bigCell
        case smallCell
        case groupCell
    }

    @objc dynamic var title: String {
        get { return "Source List Item" }
        set { }
    }
    @objc dynamic var image: NSImage? {
        return nil
    }

    @objc dynamic var textColor: NSColor {
        return .textColor
    }

    let item: DocumentWindowViewModel.SidebarItem
    let cellType: CellType

    init(item: DocumentWindowViewModel.SidebarItem, cellType: CellType = .smallCell) {
        self.item = item
        self.cellType = cellType
    }

    weak var parent: SourceListNode?
    var children = [SourceListNode]() {
        didSet {
            self.children.forEach { $0.parent = self }
        }
    }

    /// The folder to create an item in if this item is selected
    var folderForCreation: Folder? {
        return nil
    }

    /// The item to create an item below inside the folderForCreation
    var folderItemForCreation: FolderContainable? {
        return nil
    }

    /// The item to be added to a folder containing this item
    var folderContainable: FolderContainable? {
        return nil
    }

    var pasteboardWriter: NSPasteboardWriting? {
        return nil
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let otherNode = object as? SourceListNode else {
            return false
        }
        return self.item == otherNode.item
    }

    static func == (lhs: SourceListNode, rhs: SourceListNode) -> Bool {
        return lhs.item == rhs.item
    }
}


class CanvasesSourceListNode: SourceListNode {
    init() {
        super.init(item: .canvases, cellType: .bigCell)
    }

    @objc dynamic override var title: String {
        get { return NSLocalizedString("Canvases", comment: "Canvases source list row title") }
        set { }
    }

    @objc dynamic override var image: NSImage? {
        return NSImage(named: .sidebarCanvas)
    }
}


class PagesGroupSourceListNode: SourceListNode {
    let rootFolder: Folder
    init(rootFolder: Folder) {
        self.rootFolder = rootFolder
        super.init(item: .folder(rootFolder.id), cellType: .groupCell)
    }

    @objc dynamic override var title: String {
        get { return NSLocalizedString("Pages", comment: "Pages group source list row title") }
        set { }
    }
}


//MARK: -
class FolderSourceListNode: SourceListNode {
    @objc dynamic let folder: Folder
    init(folder: Folder) {
        self.folder = folder
        super.init(item: .folder(folder.id))
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == #keyPath(title) {
            keyPaths.insert("self.folder.title")
        }
        return keyPaths
    }

    @objc dynamic override var title: String {
        get { return self.folder.title  }
        set { self.folder.title = newValue }
    }

    override var image: NSImage? {
        return NSImage(named: .sidebarFolder)
    }

    override var folderForCreation: Folder? {
        return self.folder
    }

    override var folderItemForCreation: FolderContainable? {
        return self.folder.contents.last
    }

    override var folderContainable: FolderContainable? {
        return self.folder
    }

    override var pasteboardWriter: NSPasteboardWriting? {
        return self.folder.pasteboardWriter
    }
}


//MARK: -
class PageSourceListNode: SourceListNode {
    @objc dynamic let page: Page
    init(page: Page) {
        self.page = page
        super.init(item: .page(page.id))
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == #keyPath(title)) || (key == #keyPath(textColor)) {
            keyPaths.insert("self.page.title")
        }
        return keyPaths
    }

    @objc dynamic override var title: String {
        get {
            let title = self.page.title
            return (title.count > 0) ? title : "Untitled Page"
        }
        set { self.page.title = newValue }
    }

    override var textColor: NSColor {
        return (self.page.title.count > 0) ? .textColor : .placeholderTextColor
    }

    override var image: NSImage? {
        return self.page.content.contentType.icon
    }

    override var folderForCreation: Folder? {
        return self.page.containingFolder
    }

    override var folderItemForCreation: FolderContainable? {
        return self.page
    }

    override var pasteboardWriter: NSPasteboardWriting? {
        return self.page.pasteboardWriter
    }

    override var folderContainable: FolderContainable? {
        return self.page
    }
}


