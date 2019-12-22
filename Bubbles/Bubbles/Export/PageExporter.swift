//
//  PageExporter.swift
//  Bubbles
//
//  Created by Martin Pilkington on 22/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

class PageExporter {
    private static func exportablePages(from pages: [Page]) -> [Page] {
        return pages.filter { $0.content.contentType != .empty }
    }

    private static func menuItemTitle(forExporting pages: [Page]) -> String {
        if pages.count == 1 {
            return NSLocalizedString("Export Selected Page…", comment: "Export single page menu item title")
        }
        return NSLocalizedString("Export Selected Pages…", comment: "Export multiple pages menu item title")
    }

    static func validate(_ menuItem: NSMenuItem, forExporting pages: [Page]) -> Bool {
        guard menuItem.action == NSSelectorFromString("exportPages:") else {
            return false
        }

        let selectedPages = self.exportablePages(from: pages)
        menuItem.title = self.menuItemTitle(forExporting: selectedPages)
        return selectedPages.count > 0
    }

    static func export(_ pages: [Page], displayingOn window: NSWindow) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true

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
