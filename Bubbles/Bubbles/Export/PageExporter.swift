//
//  PageExporter.swift
//  Bubbles
//
//  Created by Martin Pilkington on 22/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

class PageExporter {
    //MARK: - Validation
    static func validate(_ menuItem: NSMenuItem, forExporting nodeCollection: SidebarNodeCollection) -> Bool {
        let pages = self.pagesToExport(from: nodeCollection)
        if pages.count == 1 {
            let localizedFormat = NSLocalizedString("Export \"%@\"…", comment: "Export single page menu title")
            menuItem.title = String(format: localizedFormat, pages[0].title)
            return true
        } else if pages.count > 1 {
            let localizedFormat = NSLocalizedString("Export %d Pages…", comment: "Export multiple pages menu title")
            menuItem.title = String(format: localizedFormat, pages.count)
            return true
        }

        menuItem.title = NSLocalizedString("Export Pages…", comment: "Default export pages menu title")
        return false
    }

    private static func pagesToExport(from nodeCollection: SidebarNodeCollection) -> [Page] {
        guard (nodeCollection.containsCanvases == false) && (nodeCollection.containsFolders == false) else {
            return []
        }

        return nodeCollection.nodes.compactMap { ($0 as? PageSidebarNode)?.page }
    }


    //MARK: - Export
    static func export(_ nodeCollection: SidebarNodeCollection, displayingOn window: NSWindow) {
        let pages = self.pagesToExport(from: nodeCollection)
        guard pages.count > 0 else {
            return
        }

        let panel = NSOpenPanel()
        panel.message = NSLocalizedString("Select a location to export to:", comment: "Export pages sheet message")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        if (pages.count == 1) {
            panel.prompt = NSLocalizedString("Export Page", comment: "Export single page button title")
        } else {
            panel.prompt = NSLocalizedString("Export Pages", comment: "Export multiple pages button title")
        }
        panel.beginSheetModal(for: window) { (response) in
            guard response == .OK, let destinationURL = panel.url else {
                return
            }
            for page in pages {
                self.export(page, to: destinationURL)
            }
        }
    }

    private static func export(_ page: Page, to url: URL) {
        let modelFile = page.content.modelFile
        guard let data = modelFile.data, let fileExtension = (modelFile.filename as NSString?)?.pathExtension else {
            return
        }

        var attempt = 0
        var targetURL = url.appendingPathComponent(page.title).appendingPathExtension(fileExtension)
        while (try? targetURL.checkResourceIsReachable()) ?? false {
            attempt += 1
            targetURL = url.appendingPathComponent("\(page.title) \(attempt)").appendingPathExtension(fileExtension)
        }

        try? data.write(to: targetURL)
    }
}
