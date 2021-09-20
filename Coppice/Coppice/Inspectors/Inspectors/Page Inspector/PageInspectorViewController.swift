//
//  PageInspectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class PageInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "PageInspectorContentView"
    }

    override var ranking: InspectorRanking { return .page }

    @IBAction func showProUpsell(_ sender: Any) {
        guard let control = sender as? NSView else {
            return
        }
        CoppiceSubscriptionManager.shared.showProPopover(for: .textAutoLinking, from: control, preferredEdge: .maxY)
    }
}


