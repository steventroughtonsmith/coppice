//
//  SidebarViewModelTypes.swift
//  Coppice
//
//  Created by Martin Pilkington on 31/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

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

    var commonAncestor: SourceListNode? {
        guard self.nodesShareParent == false else {
            return self.nodes.last?.parent
        }

        let allAncestors = self.nodes.map(\.ancestors)
        var i = 0
        var commonAncestor: SourceListNode? = nil
        while i < allAncestors.count {
            var currentAncestor: SourceListNode? = nil
            for ancestors in allAncestors {
                guard let ancestor = ancestors[safe: i] else {
                    return commonAncestor
                }
                if currentAncestor == nil {
                    currentAncestor = ancestor
                    continue
                }

                guard currentAncestor == ancestor else {
                    return commonAncestor
                }
            }
            commonAncestor = currentAncestor
            i += 1
        }

        return commonAncestor
    }
}

class SourceListNode: NSObject {
    enum CellType: Equatable {
        case navCell
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

    var accessibilityDescription: String? {
        return self.title
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

    var ancestors: [SourceListNode] {
        var currentParent = self.parent
        var ancestors = [SourceListNode]()
        while currentParent != nil {
            ancestors.insert(currentParent!, at: 0)
            currentParent = currentParent?.parent
        }
        return ancestors
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

    var activeSidebarSize: ActiveSidebarSize = .medium {
        didSet {
            self.willChangeValue(for: \.image)
            self.didChangeValue(for: \.image)
        }
    }
}


class CanvasesSourceListNode: SourceListNode {
    init() {
        super.init(item: .canvases, cellType: .navCell)
    }

    @objc dynamic override var title: String {
        get { return NSLocalizedString("Canvases", comment: "Canvases source list row title") }
        set { }
    }

    @objc dynamic override var image: NSImage? {
        return NSImage(named: Symbols.Sidebar.canvases(self.activeSidebarSize.symbolSize))
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
        return Folder.icon(for: self.activeSidebarSize.symbolSize)
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

    override var accessibilityDescription: String? {
        let type = NSLocalizedString("Folder", comment: "Folder table row accessibility description")
        return "\(self.title), \(type)"
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
        get { return self.page.title }
        set { self.page.title = newValue }
    }

    override var image: NSImage? {
        return self.page.content.contentType.icon(self.activeSidebarSize.symbolSize)
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

    override var accessibilityDescription: String? {
        guard self.title.count > 0 else {
            return "\(Page.localizedDefaultTitle), \(self.page.content.contentType.localizedName)"
        }
        return "\(self.title), \(self.page.content.contentType.localizedName)"
    }
}


