//
//  PreviewGenerationDebugWindow.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/05/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class PreviewGenerationDebugWindow: NSWindowController {

    @IBOutlet weak var largeImageView: NSImageView!
    @IBOutlet weak var mediumImageView: NSImageView!
    @IBOutlet weak var smallImageView: NSImageView!

    @IBOutlet weak var thumbnailImageView: NSImageView!
    @IBOutlet weak var fullImageView: NSImageView!
    @IBOutlet weak var scrollView: NSScrollView!

    @IBOutlet weak var canvasesPopUp: NSPopUpButton!
    @IBOutlet weak var themePopUp: NSPopUpButton!

    let documentViewModel: DocumentWindowViewModel
    init(documentViewModel: DocumentWindowViewModel) {
        self.documentViewModel = documentViewModel
        super.init(window: nil)
    }

    override var windowNibName: NSNib.Name? {
        return "PreviewGenerationDebugWindow"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func windowDidLoad() {
        super.windowDidLoad()

        self.setupCanvases()
        self.setupThemes()
    }


    //MARK: - Setup UI
    private func setupCanvases() {
        self.canvasesPopUp.removeAllItems()
        for canvas in self.documentViewModel.modelController.canvasCollection.all {
            let item = NSMenuItem(title: canvas.title, action: nil, keyEquivalent: "")
            item.representedObject = canvas
            self.canvasesPopUp.menu?.addItem(item)
        }
    }

    private func setupThemes() {
        self.themePopUp.removeAllItems()
        for theme in Canvas.Theme.allCases {
            let item = NSMenuItem(title: theme.localizedName, action: nil, keyEquivalent: "")
            item.representedObject = theme.rawValue
            self.themePopUp.menu?.addItem(item)
        }
    }

    @IBAction func clearImages(_ sender: Any) {
        self.fullImageView.image = nil
        self.largeImageView.image = nil
        self.mediumImageView.image = nil
        self.smallImageView.image = nil
    }

    @IBAction func generateImages(_ sender: Any) {
        guard
            let rawTheme = self.themePopUp.selectedItem?.representedObject as? String,
            let theme = Canvas.Theme.init(rawValue: rawTheme) else {
                return
        }

        guard let canvas = self.canvasesPopUp.selectedItem?.representedObject as? Canvas else {
            return
        }

        let thumbnailGenerator = CanvasThumbnailGenerator(canvas: canvas)
        if let thumbnail = canvas.thumbnail {
            self.thumbnailImageView.image = thumbnail
            self.scrollView.documentView?.frame = CGRect(origin: .zero, size: thumbnail.size)
            self.fullImageView.image = thumbnailGenerator.generateThumbnail(of: thumbnail.size, theme: theme)
        }

        self.largeImageView.image = thumbnailGenerator.generateThumbnail(of: self.largeImageView.frame.size, theme: theme)
        self.mediumImageView.image = thumbnailGenerator.generateThumbnail(of: self.mediumImageView.frame.size, theme: theme)
        self.smallImageView.image = thumbnailGenerator.generateThumbnail(of: self.smallImageView.frame.size, theme: theme)
    }
}
