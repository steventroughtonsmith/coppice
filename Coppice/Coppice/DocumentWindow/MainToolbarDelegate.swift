//
//  MainToolbarDelegate.swift
//  Coppice
//
//  Created by Martin Pilkington on 29/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

extension NSToolbarItem.Identifier {
    static let newPage = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.NewPage")
    static let newCanvas = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.NewCanvas")
    static let linkToPage = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.LinkToPage")
    static let toggleInspectors = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.ToggleInspectors")
    static let search = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.searchItem")
}

class MainToolbarDelegate: NSObject {
    @IBOutlet var searchField: NSSearchField? {
        didSet {
            if #available(OSX 10.16, *) {
                if let field = self.searchField {
                    (self.searchItem as? NSSearchToolbarItem)?.searchField = field
                }
            } else {
                self.searchItem.view = self.searchField
            }
        }
    }

    @IBOutlet var newPageSegmentedControl: NSSegmentedControl? {
        didSet {
            self.newPageItem.view = self.newPageSegmentedControl
        }
    }

    var newPageItem: NSToolbarItem = {
        return NSToolbarItem(itemIdentifier: .newPage)
    }()

    var newCanvasItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .newCanvas)
        item.image = NSImage.symbol(withName: "AddBoard")
        return item
    }()

    var linkToPageItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .linkToPage)
        item.image = NSImage.symbol(withName: "LinkPage")
        return item
    }()

    var toggleInspectorsItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .toggleInspectors)
        item.image = NSImage.symbol(withName: "ToggleInspector")
        return item
    }()

    var searchItem: NSToolbarItem = {
        if #available(OSX 10.16, *) {
            return NSSearchToolbarItem(itemIdentifier: .search)
        }
        return NSToolbarItem(itemIdentifier: .search)
    }()
}


extension MainToolbarDelegate: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .newPage,
            .newCanvas,
            .linkToPage,
            .toggleSidebar,
            .toggleInspectors,
            .search,
            .space,
            .flexibleSpace
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .toggleSidebar,
            .space,
            .newPage,
            .newCanvas,
            .space,
            .linkToPage,
            .flexibleSpace,
            .search,
            .space,
            .toggleInspectors
        ]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .newPage:              return self.newPageItem
        case .newCanvas:            return self.newCanvasItem
        case .linkToPage:           return self.linkToPageItem
        case .toggleInspectors:     return self.toggleInspectorsItem
        case .search:               return self.searchItem
        default:                    return NSToolbarItem(itemIdentifier: itemIdentifier)
        }
    }
}


