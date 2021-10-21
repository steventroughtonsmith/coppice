//
//  PageInspectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class PageInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "PageInspectorContentView"
    }

    override var ranking: InspectorRanking { return .page }

    @IBOutlet var upsellView: InspectorUpsellView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.subscribers[.isProEnabled] = self.viewModel.publisher(for: \.isProEnabled).sink { [weak self] isProEnabled in
            self?.upsellView.proFeature = isProEnabled ? nil : .textAutoLinking
            self?.updateProControlsTooltips(isProEnabled: isProEnabled)
        }
    }

    @IBOutlet var allowsAutoLinkingCheckbox: NSButton!

    private func updateProControlsTooltips(isProEnabled: Bool) {
        if isProEnabled {
            self.allowsAutoLinkingCheckbox.toolTip = NSLocalizedString("Allow auto-linking to this page from other pages. Disabling this will prevent the auto-linker from considering this page.", comment: "Page Inspector: Allows Auto-Linking Tooltip")
        } else {
            self.allowsAutoLinkingCheckbox.toolTip = nil
        }
    }

    //MARK: - Subscribers
    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    private enum SubscriberKey {
        case isProEnabled
    }
}


