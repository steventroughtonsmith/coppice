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
        self.subscribers[.isProEnabled] = self.viewModel.publisher(for: \.isProEnabled).sink { isProEnabled in
            self.upsellView.proFeature = isProEnabled ? nil : .textAutoLinking
        }
    }

    //MARK: - Subscribers
    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    private enum SubscriberKey {
        case isProEnabled
    }
}


