//
//  WelcomeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore
import M3Data

class WelcomeWindowController: NSWindowController {
    @IBOutlet weak var versionLabel: NSTextField! {
        didSet {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

            let localizedVersion = NSLocalizedString("Version %@ (%@)", comment: "Version string")
            let versionString = String(format: localizedVersion, version ?? "Unknown", build ?? "Unknown")
            self.versionLabel.stringValue = versionString
        }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        self.recentDocumentsCollectionView.reloadData()
    }

    @IBOutlet weak var recentDocumentsCollectionView: NSCollectionView! {
        didSet {
            guard let flowLayout = self.recentDocumentsCollectionView.collectionViewLayout as? NSCollectionViewFlowLayout else {
                return
            }

            flowLayout.estimatedItemSize = NSSize(width: 210, height: 160)
        }
    }

    @IBOutlet weak var backgroundView: CoppiceGreenView!

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.isMovableByWindowBackground = true
        self.window?.isExcludedFromWindowsMenu = true

        self.recentDocumentsCollectionView.setDraggingSourceOperationMask(.copy, forLocal: false)
        self.recentDocumentsCollectionView.register(WelcomeDocumentCollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DocumentItem"))

        self.subscribers[.windowAppearance] = self.window?.publisher(for: \.effectiveAppearance).sink { [weak self] appearance in
            self?.updateBackgroundView(with: appearance)
        }

        self.subscribers[.recentDocuments] = self.recentDocumentController.$recentDocuments.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.recentDocumentsCollectionView.reloadData()
        }
        self.recentDocumentController.reload(scaleFactor: self.window?.backingScaleFactor ?? 1)
    }

    private func updateBackgroundView(with appearance: NSAppearance) {
        guard let window = self.window else {
            return
        }

        self.backgroundView.shape = appearance.isDarkMode ? .curveTop : .curveBottom

        var insets: NSEdgeInsets = .zero
        if appearance.isDarkMode {
            insets.top = 148
        } else {
            insets.bottom = window.frame.height - 190
        }
        self.backgroundView.backgroundInsets = insets
    }

    override var windowNibName: NSNib.Name? {
        return "WelcomeWindow"
    }

    @IBAction func newDocument(_ sender: Any) {
        CoppiceDocumentController.shared.newDocument(sender)
        self.window?.close()
    }

    @IBAction func openDocument(_ sender: Any) {
        CoppiceDocumentController.shared.openDocument(sender)
        self.window?.close()
    }

    @IBAction func takeTour(_ sender: Any?) {}


    //MARK: - Recent documents
    private let recentDocumentController = RecentDocumentController()

    private func openRecentDocument(_ recentDocument: RecentDocument) {
        CoppiceDocumentController.shared.openDocument(withContentsOf: recentDocument.url, display: true) { (document, _, error) in
            if let error = error {
                NSApp.presentError(error)
                return
            }
            if (document as? Document)?.migrationCancelled == true {
                return
            }
            self.window?.close()
        }
    }


    //MARK: - Subscribers
    private enum SubscriberKey {
        case windowAppearance
        case recentDocuments
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]
}

extension WelcomeWindowController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.recentDocumentController.recentDocuments.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("DocumentItem"), for: indexPath)
        item.representedObject = self.recentDocumentController.recentDocuments[indexPath.item]
        (item as? WelcomeDocumentCollectionViewItem)?.delegate = self
        return item
    }
}

extension WelcomeWindowController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        let provider = NSFilePromiseProvider(fileType: "com.mcubedsw.Coppice.document", delegate: self)
        provider.userInfo = self.recentDocumentController.recentDocuments[indexPath.item].url
        return provider
    }
}

extension WelcomeWindowController: NSFilePromiseProviderDelegate {
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        guard let url = filePromiseProvider.userInfo as? URL else {
            return ""
        }
        return url.lastPathComponent
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        guard let existingURL = filePromiseProvider.userInfo as? URL else {
            completionHandler(nil)
            return
        }
        do {
            try FileManager.default.copyItem(at: existingURL, to: url)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
}

extension WelcomeWindowController: WelcomeDocumentCollectionViewItemDelegate {
    func didDoubleClick(on collectionViewItem: WelcomeDocumentCollectionViewItem) {
        if let document = collectionViewItem.recentDocument {
            self.openRecentDocument(document)
        }
    }
}
