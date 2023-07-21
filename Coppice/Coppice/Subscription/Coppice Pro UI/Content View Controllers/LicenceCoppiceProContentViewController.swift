//
//  LicenceCoppiceProContentViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa

class LicenceCoppiceProContentViewController: NSViewController {
    @IBOutlet weak var placeholderView: DropablePlaceholderView! {
        didSet {
            self.placeholderView.delegate = self
            self.placeholderView.acceptedTypes = [.fileURL]
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    //TODO
    //- On drop, check licence
    //- Send to server to activate
    //- On Success
        //Activate
    //- On network or server failure
        //Use licence
    //- On too many devices
        //fetch device list
        //on cancel don't activate
        //on select
            //deactivate selected device
            //activate
}

extension LicenceCoppiceProContentViewController: DropablePlaceholderViewDelegate {
    func placeholderView(shouldAcceptDropOf pasteboardItems: [NSPasteboardItem]) -> Bool {
        let urls = pasteboardItems
            .compactMap { $0.data(forType: .fileURL) }
            .compactMap { URL(dataRepresentation: $0, relativeTo: nil) }
            .filter { $0.pathExtension == "coppicelicence" }

        return urls.count == 1
    }

    func placeholderView(didAcceptDropOf pasteboardItems: [NSPasteboardItem]) -> Bool {
        let urls = pasteboardItems
            .compactMap { $0.data(forType: .fileURL) }
            .compactMap { URL(dataRepresentation: $0, relativeTo: nil) }
            .filter { $0.pathExtension == "coppicelicence" }

        print("URL: \(urls.first)")
        return true
    }
}

extension LicenceCoppiceProContentViewController: CoppiceProContentView {
    var leftActionTitle: String {
        return "Deactivate Device"
    }

    var leftActionIcon: NSImage {
        return NSImage(named: "M-Cubed-Logo")!
    }

    func performLeftAction(in viewController: CoppiceProViewController) {
        viewController.currentContentView = .login
    }

    var rightActionTitle: String {
        return "Learn About Pro…"
    }

    var rightActionIcon: NSImage {
        return NSImage(named: "Pro-Tree-Icon")!
    }

    func performRightAction(in viewController: CoppiceProViewController) {
        NSWorkspace.shared.open(.coppicePro)
    }
}
