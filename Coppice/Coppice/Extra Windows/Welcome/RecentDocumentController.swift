//
//  RecentDocumentController.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import AppKit
import QuickLookThumbnailing

class RecentDocumentController {
    @Published private(set) var recentDocuments: [RecentDocument] = []

    func reload(scaleFactor: CGFloat = 1) {
        Task {
            var newDocuments = [RecentDocument]()
            for url in await CoppiceDocumentController.shared.recentDocumentURLs {
                do {
                    let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: 300, height: 300), scale: scaleFactor, representationTypes: .all)
                    let representation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
                    newDocuments.append(RecentDocument(url: url, name: url.deletingPathExtension().lastPathComponent, preview: representation.nsImage))
                } catch {
                    continue
                }
            }
            self.recentDocuments = newDocuments
        }
    }
}

struct RecentDocument {
    let url: URL
    let name: String
    let preview: NSImage
}

