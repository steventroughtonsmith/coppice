//
//  MainToolbarDelegate.swift
//  Coppice
//
//  Created by Martin Pilkington on 29/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

extension NSToolbarItem.Identifier {
    static let newPage = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.NewPage")
    static let newCanvas = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.NewCanvas")
    static let linkToPage = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.LinkToPage")
    static let toggleInspectors = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.ToggleInspectors")
    static let search = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.searchItem")
    //Because Big Sur doesn't let us supply our own
    static let customToggleSidebar = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.ToggleSidebar")
}

class MainToolbarDelegate: NSObject {
    let searchField: NSSearchField
    let newPageControl: NSView
    let splitView: NSSplitView

    let menuDelegate = NewPageMenuDelegate()

    init(searchField: NSSearchField, newPageControl: NSView, splitView: NSSplitView) {
        self.searchField = searchField
        self.newPageControl = newPageControl
        self.splitView = splitView
        super.init()
    }


    lazy var newPageItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .newPage)
        item.label = NSLocalizedString("New Page", comment: "New Page toolbar item label")
        item.paletteLabel = item.label
        item.view = self.newPageControl
        item.toolTip = NSLocalizedString("Create new Page. Click and hold to select Page type.", comment: "New Page toolbar item tooltip")
        return item
    }()

    lazy var newCanvasItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .newCanvas)

        item.image = NSImage.symbol(withName: Symbols.Toolbars.newCanvas)
        item.label = NSLocalizedString("New Canvas", comment: "New Canvas toolbar item label")
        item.paletteLabel = item.label
        item.toolTip = item.label
        let button = NSButton(image: NSImage.symbol(withName: Symbols.Toolbars.newCanvas)!,
                              target: nil,
                              action: #selector(DocumentWindowController.newCanvas(_:)))
        button.bezelStyle = .texturedRounded
        item.view = button
        return item
    }()

    var linkToPageItem: NSToolbarItem = {
        let item = ButtonToolbarItem(itemIdentifier: .linkToPage,
                                     image: NSImage.symbol(withName: Symbols.Toolbars.link)!,
                                     action: #selector(TextEditorViewController.linkToPage(_:)))
        item.label = NSLocalizedString("Link to Page", comment: "Link to Page toolbar item label")
        item.paletteLabel = item.label
        item.toolTip = item.label
        item.autovalidates = true
        return item
    }()

    var toggleSidebarItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .customToggleSidebar)
        item.image = NSImage.symbol(withName: Symbols.Toolbars.leftSidebar)
        if #available(macOS 10.16, *) {
            item.isNavigational = true
        }
        item.label = NSLocalizedString("Sidebar", comment: "Toggle Sidebar toolbar item label")
        item.paletteLabel = item.label
        item.isBordered = true
        item.action = #selector(RootSplitViewController.toggleSidebar(_:))
        return item
    }()

    var toggleInspectorsItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .toggleInspectors)
        item.image = NSImage.symbol(withName: Symbols.Toolbars.rightSidebar)
        item.label = NSLocalizedString("Inspectors", comment: "Toggle Inspectors toolbar item label")
        item.paletteLabel = item.label
        item.toolTip = NSLocalizedString("Toggle Inspectors", comment: "Toggle Inspectors toolbar item tooltip")
        item.isBordered = true
        item.action = #selector(RootSplitViewController.toggleInspectors(_:))
        return item
    }()

    lazy var searchItem: NSToolbarItem = {
        if #available(OSX 10.16, *) {
            let item = NSSearchToolbarItem(itemIdentifier: .search)
            item.searchField = self.searchField
            return item
        }
        let item = NSToolbarItem(itemIdentifier: .search)
        item.label = NSLocalizedString("Search", comment: "Search toolbar item label")
        item.paletteLabel = item.label
        item.view = self.searchField
        return item
    }()
}


extension MainToolbarDelegate: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        var identifiers: [NSToolbarItem.Identifier] = [
            .newPage,
            .newCanvas,
            .linkToPage,
            .customToggleSidebar,
            .toggleInspectors,
            .search,
            .space,
            .flexibleSpace,
        ]
        if #available(OSX 10.16, *) {
            identifiers.append(.sidebarTrackingSeparator)
        }
        return identifiers
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        var identifiers: [NSToolbarItem.Identifier] = [
            .customToggleSidebar,
            .space,
            .newPage,
            .newCanvas,
            .space,
            .linkToPage,
            .flexibleSpace,
            .search,
            .toggleInspectors,
        ]

        if #available(OSX 10.16, *) {
            identifiers[1] = .flexibleSpace
            identifiers.remove(at: 4)
            identifiers.insert(.sidebarTrackingSeparator, at: 3)
        }

        return identifiers
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .newPage:
            return self.newPageItem
        case .newCanvas:
            return self.newCanvasItem
        case .linkToPage:
            return self.linkToPageItem
        case .toggleInspectors:
            return self.toggleInspectorsItem
        case .search:
            return self.searchItem
        case .customToggleSidebar:
            return self.toggleSidebarItem
        default:
            if #available(OSX 10.16, *), itemIdentifier == .sidebarTrackingSeparator {
                return NSTrackingSeparatorToolbarItem(identifier: .sidebarTrackingSeparator, splitView: self.splitView, dividerIndex: 1)
            }
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            return item
        }
    }
}

class ToolbarSearchField: NSSearchField {
    override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        size.width = 200
        return size
    }
}
