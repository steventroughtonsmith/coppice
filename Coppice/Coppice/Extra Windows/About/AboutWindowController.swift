//
//  AboutWindowController.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class AboutWindowController: NSWindowController {
    override var windowNibName: NSNib.Name? {
        return "AboutWindow"
    }

    @IBAction func showPrivacyPolicy(_ sender: Any) {
        NSWorkspace.shared.open(.privacyPolicy)
    }

    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var copyrightLabel: NSTextField!

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.window?.standardWindowButton(.zoomButton)?.isHidden = true

        guard
            let copyright = Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String,
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        else {
            return
        }

        self.copyrightLabel.stringValue = copyright

        let localizedVersion = NSLocalizedString("Version %@ (%@)", comment: "Version string")
        let versionString = String(format: localizedVersion, version, build)
        self.versionLabel.stringValue = versionString


        guard
            let acknowledgementsURL = Bundle.main.url(forResource: "Acknowledgements", withExtension: "rtf"),
            let text = try? NSAttributedString(url: acknowledgementsURL, options: [:], documentAttributes: nil)
        else {
            return
        }
        self.acknowledgementsTextView.textStorage?.setAttributedString(text)
    }


    //MARK: - Acknowledgements
    @IBOutlet var acknowledgementsTextView: NSTextView!
}
