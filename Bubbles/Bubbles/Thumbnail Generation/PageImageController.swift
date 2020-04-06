//
//  PageImageController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 28/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class PageImageController: NSObject {
    let modelController: ModelController
    weak var documentViewModel: DocumentWindowViewModel?

    private let cache = NSCache<NSUUID, NSImage>()

    init(modelController: ModelController) {
        self.modelController = modelController

        super.init()

        self.startObservation()
    }


    //MARK: - Observation
    private var observation: ModelCollection<Page>.Observation?
    private func startObservation() {
        self.observation = self.modelController.collection(for: Page.self).addObserver { [weak self] (page, changeType) in
            if changeType == .update || changeType == .delete {
                self?.cache.removeObject(forKey: (page.id.uuid as NSUUID))
            }
        }
    }

    private func endObservation() {
        if let observer = self.observation {
            self.modelController.collection(for: Page.self).removeObserver(observer)
        }
    }


    //MARK: - Image Generation
    func imageForPage(with id: ModelID) -> NSImage? {
        if let cachedImage = self.cache.object(forKey: (id.uuid as NSUUID)) {
            return cachedImage
        }
        
        guard let newImage = self.generateImage(forPageWithID: id) else {
            return nil
        }
        self.cache.setObject(newImage, forKey: (id.uuid as NSUUID))
        return newImage
    }

    private func generateImage(forPageWithID id: ModelID) -> NSImage? {
        guard let documentViewModel = self.documentViewModel else {
            return nil
        }

        guard let page = self.modelController.collection(for: Page.self).objectWithID(id) else {
            return nil
        }

        print("generate image for page: \(page.title)")

        let editorVM = PageEditorViewModel(page: page, documentWindowViewModel: documentViewModel)
        let contentEditor = editorVM.contentEditor
        let editorView = contentEditor.view
        editorView.wantsLayer = true
        editorView.layer?.cornerRadius = 5
        editorView.layer?.masksToBounds = true
        editorView.frame = CGRect(origin: .zero, size: page.contentSize)

        guard let bitmapRep = editorView.bitmapImageRepForCachingDisplay(in: editorView.bounds) else {
            return nil
        }

        editorView.cacheDisplay(in: editorView.bounds, to: bitmapRep)

        let image = NSImage(size: editorView.bounds.size)
        image.addRepresentation(bitmapRep)
        return image
    }
}
