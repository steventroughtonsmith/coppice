//
//  InfoAlertViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/11/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

struct InfoAlert {
    enum Level {
        case info
        case warning
        case error
    }

    var id: String
    var level: Level
    var title: String
    var message: String? = nil
    var icon: NSImage? = nil
    var autodismiss: Bool = true
}

class InfoAlertViewController: NSViewController {
    let alert: InfoAlert
    init(alert: InfoAlert) {
        self.alert = alert
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    @IBOutlet var titleTextField: NSTextField!
    @IBOutlet var messageTextField: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundColor: NSColor
        let appearance: NSAppearance.Name
        switch self.alert.level {
        case .info:
            backgroundColor = NSColor(named: "CoppiceGreen")!
            appearance = .darkAqua
        case .warning:
            backgroundColor = NSColor(named: "AlertWarning")!
            appearance = .aqua
        case .error:
            backgroundColor = NSColor(named: "AlertError")!
            appearance = .darkAqua
        }

        self.view.appearance = NSAppearance(named: appearance)
        self.view.wantsLayer = true

        self.view.layer?.backgroundColor = backgroundColor.withAlphaComponent(0.9).cgColor
        self.view.layer?.cornerRadius = 5
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = CGSize(width: 0, height: -2)
        self.view.shadow = shadow

        self.titleTextField.stringValue = self.alert.title

        if let message = self.alert.message {
            self.messageTextField.stringValue = message
            self.messageTextField.isHidden = false
        } else {
            self.messageTextField.isHidden = true
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if self.alert.autodismiss {
            self.perform(#selector(self.dismissAlert(_:)), with: nil, afterDelay: 15)
        }
    }

    @IBAction func dismissAlert(_ sender: Any?) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.dismissAlert(_:)), object: nil)
        self.didDismissBlock?()
    }

    var didDismissBlock: (() -> Void)?
}
