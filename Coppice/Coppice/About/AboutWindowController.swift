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
        NSWorkspace.shared.open(URL(string: "https://coppiceapp.com/privacy")!)
    }


    //MARK: - Acknowledgements
    @IBOutlet var acknowledgementsWindow: NSWindow!
    @IBOutlet var acknowledgementsTextView: NSTextView!
    @IBAction func showAcknowledgements(_ sender: Any) {
        guard
            let acknowledgementsURL = Bundle.main.url(forResource: "Acknowledgements", withExtension: "rtf"),
            let text = try? NSAttributedString(url: acknowledgementsURL, options: [:], documentAttributes: nil)
        else {
            return
        }
        self.acknowledgementsTextView.textStorage?.setAttributedString(text)

        self.window?.beginSheet(self.acknowledgementsWindow, completionHandler: nil)
    }
    @IBAction func closeAcknowledgements(_ sender: Any) {
        self.window?.endSheet(self.acknowledgementsWindow);
    }
}
