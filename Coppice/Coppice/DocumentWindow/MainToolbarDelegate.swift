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
                self.searchField?.widthAnchor.constraint(lessThanOrEqualToConstant: 250).isActive = true
            }
        }
    }

    @IBOutlet var newPageSegmentedControl: NSSegmentedControl? {
        didSet {
            self.newPageItem.view = self.newPageSegmentedControl
        }
    }

    var newPageItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .newPage)
        item.label = NSLocalizedString("New Page", comment: "New Page toolbar item label")
        item.paletteLabel = item.label
        return item
    }()

    var newCanvasItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .newCanvas)
        item.image = NSImage.symbol(withName: Symbols.Toolbars.newCanvas)
        item.label = NSLocalizedString("New Canvas", comment: "New Canvas toolbar item label")
        item.paletteLabel = item.label
        item.isBordered = true
        item.action = #selector(DocumentWindowController.newCanvas(_:))
        return item
    }()

    var linkToPageItem: NSToolbarItem = {
        let item = ResponderChainValidatingToolbarItem(itemIdentifier: .linkToPage)
        item.image = NSImage.symbol(withName: Symbols.Toolbars.link)
        item.label = NSLocalizedString("Link to Page", comment: "Link to Page toolbar item label")
        item.paletteLabel = item.label
        item.isBordered = true
        item.action = #selector(TextEditorViewController.linkToPage(_:))
        return item
    }()

    var toggleSidebarItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .toggleSidebar)
        item.image = NSImage.symbol(withName: Symbols.Toolbars.leftSidebar)
        return item
    }()

    var toggleInspectorsItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .toggleInspectors)
        item.image = NSImage.symbol(withName: Symbols.Toolbars.rightSidebar)
        item.label = NSLocalizedString("Inspectors", comment: "Toggle Inspectors toolbar item label")
        item.isBordered = true
        item.paletteLabel = item.label
        item.action = #selector(RootSplitViewController.toggleInspectors(_:))
        return item
    }()

    var searchItem: NSToolbarItem = {
        if #available(OSX 10.16, *) {
            return NSSearchToolbarItem(itemIdentifier: .search)
        }
        let item = NSToolbarItem(itemIdentifier: .search)
        item.label = NSLocalizedString("Search", comment: "Search toolbar item label")
        item.paletteLabel = item.label
        return item
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
        case .toggleSidebar:        return self.toggleSidebarItem
        default:                    return NSToolbarItem(itemIdentifier: itemIdentifier)
        }
    }
}


