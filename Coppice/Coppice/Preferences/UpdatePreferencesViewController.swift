//
//  UpdatePreferencesViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Sparkle

class UpdatePreferencesViewController: NSViewController {
    @objc dynamic let updaterController: SPUStandardUpdaterController?
    init(updaterController: SPUStandardUpdaterController) {
        self.updaterController = updaterController
        super.init(nibName: "UpdatePreferencesViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createTabItem() -> NSTabViewItem {
        let item = NSTabViewItem(viewController: self)
        item.label = NSLocalizedString("Updates", comment: "Updates Preferences Title")
        item.image = NSImage(named: "PrefsUpdates")
        return item
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    @IBAction func showSystemProfileInfo(_ sender: Any) {
        guard let updater = updaterController?.updater else {
            return
        }
        guard let additionalInfo = updaterController?.updaterDelegate?.feedParameters?(for: updater, sendingSystemProfile: true) else {
            return
        }
        let combined = updater.systemProfileArray + additionalInfo
        let systemProfileInfo = SystemProfileInfoViewController(systemInfo: combined)
        self.presentAsSheet(systemProfileInfo)
    }

    @IBAction func checkNow(_ sender: Any) {
        self.updaterController?.checkForUpdates(sender)
    }
}

