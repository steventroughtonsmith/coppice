//
//  LicenceCoppiceProContentViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa

class LicenceCoppiceProContentViewController: NSViewController {
    let viewModel: CoppiceProViewModel
    init(viewModel: CoppiceProViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "LicenceCoppiceProContentViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    private func activate(with url: URL) {
        Task {
            do {
                try await self.viewModel.activate(withLicenceAtURL: url)
            } catch {
                //TODO: Handle errors
            }
        }
    }
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

        guard urls.count == 1 else {
            return false
        }

        self.activate(with: urls[0])
        return true
    }
}

extension LicenceCoppiceProContentViewController: CoppiceProContentView {
    var leftActionTitle: String {
        return "Use M Cubed Account"
    }

    var leftActionIcon: NSImage {
        return NSImage(named: "M-Cubed-Logo")!
    }

    func performLeftAction(in viewController: CoppiceProViewController) {
        self.viewModel.switchToLogin()
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
