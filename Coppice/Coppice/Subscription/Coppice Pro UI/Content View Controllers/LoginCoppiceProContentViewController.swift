//
//  LoginCoppiceProContentViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa
import OSLog

class LoginCoppiceProContentViewController: NSViewController {
    let viewModel: CoppiceProViewModel
    init(viewModel: CoppiceProViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "LoginCoppiceProContentViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    //MARK: - Properties
    @objc dynamic var email: String = ""
    @objc dynamic var password: String = ""

    @objc class func keyPathsForValuesAffectingActivateEnabled() -> Set<String> {
        return [#keyPath(email), #keyPath(password)]
    }

    @objc dynamic var activateEnabled: Bool {
        return !self.email.isEmpty && !self.password.isEmpty
    }

    //MARK: - Actions
    @IBAction func activate(_ sender: NSButton) {
        Task {
            await self.viewModel.activateWithLogin(email: self.email, password: self.password)
        }
    }
}

extension LoginCoppiceProContentViewController: CoppiceProContentView {
    var leftActionTitle: String {
        return "Use Licence"
    }

    var leftActionIcon: NSImage {
        return NSImage(systemSymbolName: "doc", accessibilityDescription: nil)!
    }

    func performLeftAction(in viewController: CoppiceProViewController) {
        self.viewModel.switchToLicence()
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
