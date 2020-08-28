//
//  UpdatePreferencesViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Sparkle

class UpdatePreferencesViewController: PreferencesViewController {
    @objc dynamic let updaterController: SPUStandardUpdaterController?
    init(updaterController: SPUStandardUpdaterController) {
        self.updaterController = updaterController
        super.init(nibName: "UpdatePreferencesViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var tabLabel: String {
        return NSLocalizedString("Updates", comment: "Updates Preferences Title")
    }

    override var tabImage: NSImage? {
        return NSImage(named: "PrefsUpdates")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    @IBAction func showSystemProfileInfo(_ sender: Any) {
        guard let updateController = updaterController else {
            return
        }
        let infoItems = SystemProfileInfoItemCreator.infoItems(from: updateController)
        let systemProfileInfo = SystemProfileInfoViewController(systemInfo: infoItems)
        self.presentAsSheet(systemProfileInfo)
    }

    @IBAction func checkNow(_ sender: Any) {
        self.updaterController?.checkForUpdates(sender)
    }
}

