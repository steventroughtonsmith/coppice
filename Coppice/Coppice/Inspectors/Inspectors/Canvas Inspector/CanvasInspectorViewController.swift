//
//  CanvasInspectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class CanvasInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "CanvasInspectorContentView"
    }

    override var ranking: InspectorRanking { return .canvas }

    @IBOutlet var upsellView: InspectorUpsellView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.subscribers[.isProEnabled] = self.viewModel.publisher(for: \.isProEnabled).sink { [weak self] isProEnabled in
            self?.upsellView.proFeature = isProEnabled ? nil : .canvasAppearance
        }
    }

    //MARK: - Subscribers
    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    private enum SubscriberKey {
        case isProEnabled
    }
}
