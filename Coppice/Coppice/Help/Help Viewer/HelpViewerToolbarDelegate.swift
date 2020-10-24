//
//  HelpViewerToolbarDelegate.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

extension NSToolbarItem.Identifier {
    static let helpNavigation = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.help.Navigation")
    static let helpNavigationBack = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.help.Back")
    static let helpNavigationForward = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.help.Forward")
    static let helpToggleSidebar = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.help.ToggleSidebar")
    static let helpFavourite = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.help.Favourite")
    static let helpSearch = NSToolbarItem.Identifier(rawValue: "com.mcubedsw.coppice.help.Search")
}

class HelpViewerToolbarDelegate: NSObject {
    let searchField: NSSearchField
    let splitView: NSSplitView


    init(searchField: NSSearchField, splitView: NSSplitView) {
        self.searchField = searchField
        self.splitView = splitView
        super.init()
    }

    var navigationButtons: NSToolbarItemGroup = {
        let item = NSToolbarItemGroup(itemIdentifier: .helpNavigation)
        item.label = NSLocalizedString("Navigation", comment: "Help Navigation toolbar item label")
        item.paletteLabel = item.label
        item.toolTip = item.label
        item.selectionMode = .momentary
        if #available(macOS 10.16, *) {
            item.isNavigational = true
        }

        let backItem = ButtonToolbarItem(itemIdentifier: .helpNavigationBack,
                                         image: NSImage(named: "HelpBack")!,
                                         action: #selector(NavigationStack.back(_:)))
        backItem.label = NSLocalizedString("Back", comment: "Help Back toolbar item label")
        backItem.view?.widthAnchor.constraint(equalToConstant: 30).isActive = true
        backItem.paletteLabel = backItem.label
        backItem.toolTip = backItem.label
        backItem.autovalidates = true


        let forwardItem = ButtonToolbarItem(itemIdentifier: .helpNavigationForward,
                                            image: NSImage(named: "HelpForward")!,
                                            action: #selector(NavigationStack.forward(_:)))
        forwardItem.view?.widthAnchor.constraint(equalToConstant: 30).isActive = true
        forwardItem.label = NSLocalizedString("Forward", comment: "Help Forward toolbar item label")
        forwardItem.paletteLabel = forwardItem.label
        forwardItem.toolTip = forwardItem.label
        forwardItem.autovalidates = true

        item.subitems = [backItem, forwardItem]

        return item
    }()

    var favouriteItem: NSToolbarItem = {
        let item = ButtonToolbarItem(itemIdentifier: .helpFavourite,
                                     image: NSImage.symbol(withName: Symbols.Toolbars.link)!,
                                     action: #selector(HelpTopicViewController.toggleFavourite(_:)))
        item.label = NSLocalizedString("Favourite", comment: "Favourite topic toolbar item label")
        item.paletteLabel = item.label
        item.toolTip = item.label
        item.autovalidates = true
        return item
    }()

    var toggleSidebarItem: NSToolbarItem = {
        let item = NSToolbarItem(itemIdentifier: .helpToggleSidebar)
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

    lazy var searchItem: NSToolbarItem = {
        if #available(OSX 10.16, *) {
            let item = NSSearchToolbarItem(itemIdentifier: .helpSearch)
            item.searchField = self.searchField
            return item
        }
        let item = NSToolbarItem(itemIdentifier: .helpSearch)
        item.label = NSLocalizedString("Search", comment: "Search toolbar item label")
        item.paletteLabel = item.label
        item.view = self.searchField
        return item
    }()
}


extension HelpViewerToolbarDelegate: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .helpNavigation,
            .helpFavourite,
            .helpToggleSidebar,
            .helpSearch,
            .space,
            .flexibleSpace
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .helpNavigation,
            .helpToggleSidebar,
            .flexibleSpace,
//            .helpFavourite,
            .helpSearch,
        ]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .helpNavigation:
            return self.navigationButtons
        case .helpSearch:
            return self.searchItem
        case .helpFavourite:
            return self.favouriteItem
        case .helpToggleSidebar:
            return self.toggleSidebarItem
        default:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            return item
        }
    }
}
