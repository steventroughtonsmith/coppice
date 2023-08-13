//
//  CoppiceProTrialViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 08/08/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa

class CoppiceProTrialViewController: NSViewController {
    let viewModel: CoppiceProViewModel
    init(viewModel: CoppiceProViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CoppiceProTrialViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var privacyPolicyCheckbox: NSButton!

    @IBOutlet weak var startTrialButton: RoundButton! {
        didSet {
            self.startTrialButton.imageInsets = NSEdgeInsets(top: -1, left: 5, bottom: -1, right: -5)
            self.startTrialButton.titleInsets = NSEdgeInsets(top: 3, left: 2, bottom: -3, right: -2)
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.initialFirstResponder = self.privacyPolicyCheckbox
    }

    override func cancelOperation(_ sender: Any?) {
        self.close(nil)
    }

    @IBAction func close(_ sender: Any?) {
        self.presentingViewController?.dismiss(self)
    }

    @objc dynamic var privacyPolicySelected: Bool = false
    @IBAction func showPrivacyPolicy(_ sender: Any) {
        NSWorkspace.shared.open(.privacyPolicy)
    }

    @objc dynamic var termsSelected: Bool = false
    @IBAction func showTermsAndConditions(_ sender: Any) {
        NSWorkspace.shared.open(.termsAndConditions)
    }

    @IBAction func startTrial(_ sender: Any) {
        Task {
            await self.viewModel.startTrial()
            Task { @MainActor in
                self.close(nil)
            }
        }
    }
}
