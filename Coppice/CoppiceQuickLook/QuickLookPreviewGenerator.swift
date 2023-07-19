//
//  QuickLookPreviewGenerator.swift
//  CoppiceQuickLook
//
//  Created by Martin Pilkington on 19/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore
import M3Data

class QuickLookPreviewGenerator {
    private let modelController = CoppiceModelController(undoManager: UndoManager())
    private let layoutEngine = CanvasLayoutEngine(configuration: .init(page: .mac, contentBorder: 100, arrow: .standard))

    func previewImage(for url: URL) throws -> NSImage? {
        let modelReader = ModelReader(modelController: self.modelController, plists: Plist.allPlists)
        do {
            let fileWrapper = try FileWrapper(url: url, options: [])
            guard
                let plistWrapper = fileWrapper.fileWrappers?[GlobalConstants.DocumentContents.dataPlist],
                let contentWrapper = fileWrapper.fileWrappers?[GlobalConstants.DocumentContents.contentFolder]
            else {
                throw NSError.Coppice.Document.readingFailed()
            }
            try modelReader.read(plistWrapper: plistWrapper, contentWrapper: contentWrapper, shouldMigrate: {
                return false
            })
        } catch let e {
            throw e
        }

        guard let canvas = self.modelController.canvasCollection.all.sorted(by: { $0.sortIndex < $1.sortIndex }).first else {
            return nil
        }

        let generator = CanvasImageGenerator(canvas: canvas, contentBorder: 100)
        return generator.generateImage()
    }
}
