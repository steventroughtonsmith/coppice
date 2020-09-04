//
//  ErrorPopoverViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ErrorPopoverViewController: NSViewController {
    static func show(_ error: NSError, relativeTo rect: NSRect, of view: NSView, preferredEdge: NSRectEdge) {
        let vc = ErrorPopoverViewController(error: error)
        let popover = NSPopover()
        popover.contentViewController = vc
        popover.behavior = .transient
        popover.show(relativeTo: rect, of: view, preferredEdge: preferredEdge)
    }

    let error: NSError
    init(error: NSError) {
        self.error = error
        super.init(nibName: "ErrorPopoverViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var bodyLabel: NSTextField!


    override func viewDidLoad() {
        super.viewDidLoad()

        self.titleLabel.stringValue = self.error.localizedDescription
        self.bodyLabel.stringValue = self.error.localizedFailureReason ?? self.error.localizedRecoverySuggestion ?? ""
        self.bodyLabel.isHidden = self.bodyLabel.stringValue.count == 0
    }
    
}
