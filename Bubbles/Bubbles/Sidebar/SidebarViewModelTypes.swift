//
//  SidebarViewModelTypes.swift
//  Bubbles
//
//  Created by Martin Pilkington on 31/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit


class SidebarNode: NSObject {
    enum CellType {
        case bigCell
        case smallCell
        case groupCell
    }

    @objc dynamic var title: String {
        get { return "Sidebar Item" }
        set { }
    }
    @objc dynamic var image: NSImage? {
        return nil
    }

    let item: DocumentWindowViewModel.SidebarItem
    let cellType: CellType

    init(item: DocumentWindowViewModel.SidebarItem, cellType: CellType = .smallCell) {
        self.item = item
        self.cellType = cellType
    }

    weak var parent: SidebarNode?
    private(set) var children = [SidebarNode]()
    func addChildren(_ children: [SidebarNode]) {
        children.forEach { $0.parent = self }
        self.children.append(contentsOf: children)
    }
}


class CanvasesSidebarNode: SidebarNode {
    init() {
        super.init(item: .canvases, cellType: .bigCell)
    }

    @objc dynamic override var title: String {
        get { return NSLocalizedString("Canvases", comment: "Canvases sidebar row title") }
        set { }
    }

    @objc dynamic override var image: NSImage? {
        return NSImage(named: .sidebarCanvas)
    }
}


class PagesGroupSidebarNode: SidebarNode {
    let rootFolder: Folder
    init(rootFolder: Folder) {
        self.rootFolder = rootFolder
        super.init(item: .folder(rootFolder.id), cellType: .groupCell)
    }

    @objc dynamic override var title: String {
        get { return NSLocalizedString("Pages", comment: "Pages group sidebar row title") }
        set { }
    }
}


//MARK: -
class FolderSidebarNode: SidebarNode {
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
}


//MARK: -
class PageSidebarNode: SidebarNode {
    @objc dynamic let page: Page
    init(page: Page) {
        self.page = page
        super.init(item: .page(page.id))
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == #keyPath(title) {
            keyPaths.insert("self.page.title")
        }
        return keyPaths
    }

    @objc dynamic override var title: String {
        get { return self.page.title  }
        set { self.page.title = newValue }
    }

    override var image: NSImage? {
        return self.page.content.contentType.icon
    }
}


