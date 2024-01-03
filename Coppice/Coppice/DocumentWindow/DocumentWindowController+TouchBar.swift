//
//  DocumentWindowController+TouchBar.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

extension NSTouchBarItem.Identifier {
    static let newPage = NSTouchBarItem.Identifier("com.mcubedsw.Coppice.TouchBar.newPage")
    static let newCanvas = NSTouchBarItem.Identifier("com.mcubedsw.Coppice.TouchBar.newCanvas")
    static let linkToPage = NSTouchBarItem.Identifier("com.mcubedsw.Coppice.TouchBar.linkToPage")
}

extension DocumentWindowController: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.newPage, .newCanvas, .linkToPage, .otherItemsProxy]
        return touchBar
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case .newPage:
            let pageItem = NSPopoverTouchBarItem(identifier: identifier)
            pageItem.collapsedRepresentationImage = self.viewModel.lastCreatePageType.addIcon

            let pageTouchBar = NSTouchBar()
            pageTouchBar.delegate = self.newPageMenuDelegate
            pageTouchBar.defaultItemIdentifiers = Page.ContentType.allCases.map(\.rawValue).map { NSTouchBarItem.Identifier($0) }

            pageItem.pressAndHoldTouchBar = pageTouchBar
            pageItem.popoverTouchBar = pageTouchBar

            pageItem.customizationLabel = NSLocalizedString("New Page", comment: "New Page toolbar item title")
            return pageItem
        case .newCanvas:
            let canvas = NSButtonTouchBarItem(identifier: .newCanvas,
                                              image: NSImage(named: Symbols.Toolbars.newCanvas)!,
                                              target: nil,
                                              action: #selector(newCanvas(_:)))
            canvas.isEnabled = self.viewModel.proEnabled
            canvas.customizationLabel = NSLocalizedString("New Canvas", comment: "New Canvas toolbar item title")
            return canvas
        case .linkToPage:
            let linkToPage = NSButtonTouchBarItem(identifier: .linkToPage,
                                                  image: NSImage(named: Symbols.Toolbars.link)!,
                                                  target: nil,
                                                  action: #selector(TextEditorViewController.editLink(_:)))
            linkToPage.visibilityPriority = .high
            linkToPage.customizationLabel = NSLocalizedString("Link to Page", comment: "Link to Page toolbar item title")
            return linkToPage
        default:
            return nil
        }
    }

    var newPageTouchBarItem: NSPopoverTouchBarItem? {
        return self.touchBar?.item(forIdentifier: .newPage) as? NSPopoverTouchBarItem
    }
}
