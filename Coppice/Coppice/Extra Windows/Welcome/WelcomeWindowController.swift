//
//  WelcomeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class WelcomeWindowController: NSWindowController {
    @IBOutlet weak var buttonStackView: NSStackView!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var recentTable: NSTableView!

    override func windowDidLoad() {
        super.windowDidLoad()

        if let newView = self.buttonStackView.arrangedSubviews.first {
            self.buttonStackView.setCustomSpacing(30, after: newView)
        }

        self.window?.isMovableByWindowBackground = true
        self.window?.isExcludedFromWindowsMenu = true

        self.setupVersionLabel()
    }

    private func setupVersionLabel() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        let localizedVersion = NSLocalizedString("Version %@ (%@)", comment: "Version string");
        let versionString = String(format: localizedVersion, version ?? "Unknown", build ?? "Unknown")
        self.versionLabel.stringValue = versionString
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

    @IBAction func takeTour(_ sender: Any?) {
    }

    @IBAction func openRecentDocument(_ sender: Any?) {
        let row = self.recentTable.clickedRow
        let urls = CoppiceDocumentController.shared.recentDocumentURLs
        guard (row > -1) && (row < urls.count) else {
            return
        }

        let url = urls[row]
        CoppiceDocumentController.shared.openDocument(withContentsOf: url, display: true) { (_, _, error) in
            if let error = error {
                NSApp.presentError(error)
                return
            }
            self.window?.close()
        }
    }

    @IBAction func revealInFinder(_ sender: Any) {
        let row = self.recentTable.clickedRow
        guard row > -1 else {
            return
        }

        let documentURL = CoppiceDocumentController.shared.recentDocumentURLs[row]
        NSWorkspace.shared.selectFile(documentURL.path, inFileViewerRootedAtPath: "")
    }
}

extension WelcomeWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return CoppiceDocumentController.shared.recentDocumentURLs.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return CoppiceDocumentController.shared.recentDocumentURLs[row]
    }
}
