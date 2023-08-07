//
//  ActivatedCoppiceProContentViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class ActivatedCoppiceProContentViewController: NSViewController {
    let viewModel: CoppiceProViewModel
    init(viewModel: CoppiceProViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ActivatedCoppiceProContentViewController", bundle: nil)

        self.subscribers[.activation] = self.viewModel.$activation.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.reloadData()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var planLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var statusDetailsLabel: NSTextField!
    @IBOutlet weak var deviceLabel: NSTextField!
    @IBOutlet weak var deviceRow: NSGridRow!
    @IBOutlet weak var renameButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadData()
    }

    private func reloadData() {
        guard self.isViewLoaded, let activation = self.viewModel.activation else {
            return
        }
        self.planLabel.stringValue = activation.planName
        self.statusLabel.stringValue = CoppiceProViewModel.localizedStatus(expirationTimestamp: activation.expirationTimestamp,
                                                                           renewalStatus: activation.renewalStatus)
        self.statusDetailsLabel.stringValue = CoppiceProViewModel.localizedStatusDetails(expirationTimestamp: activation.expirationTimestamp,
                                                                                         renewalStatus: activation.renewalStatus)
        if let deviceName = activation.deviceName {
            self.deviceLabel.stringValue = deviceName
            self.deviceRow.isHidden = false
        } else {
            self.deviceRow.isHidden = true
        }
        self.renameButton.isHidden = (self.viewModel.canRename == false)
    }

    private func deactivate() {
        Task {
            try await self.viewModel.deactivate()
        }
    }

    //MARK: - Rename
    @IBAction func renameDevice(_ sender: Any) {
        self.deviceLabel.isEditable = true
        self.deviceLabel.isSelectable = true
        self.view.window?.makeFirstResponder(self.deviceLabel)
        self.renameButton.action = #selector(self.finishRenaming(_:))
    }

    @IBAction func finishRenaming(_ sender: Any) {
        guard self.deviceLabel.stringValue.count > 0 else {
            NSSound.beep()
            return
        }

        self.deviceLabel.isEditable = false
        self.deviceLabel.isSelectable = false
        self.deviceLabel.resignFirstResponder()
        self.renameButton.action = #selector(self.renameDevice(_:))

        Task {
            try await self.viewModel.rename(to: self.deviceLabel.stringValue)
        }
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case activation
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]
}

extension ActivatedCoppiceProContentViewController: CoppiceProContentView {
    var leftActionTitle: String {
        return "Deactivate Device"
    }

    var leftActionIcon: NSImage {
        return NSImage(systemSymbolName: "display", accessibilityDescription: nil)!
    }

    func performLeftAction(in viewController: CoppiceProViewController) {
        self.deactivate()
    }

    var rightActionTitle: String {
        return "View Account…"
    }

    var rightActionIcon: NSImage {
        return NSImage(systemSymbolName: "person.fill", accessibilityDescription: nil)!
    }

    func performRightAction(in viewController: CoppiceProViewController) {
        NSWorkspace.shared.open(.mcubedAccount)
    }
}
