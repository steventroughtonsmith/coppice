//
//  ProUpsellViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 04/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa


class ProUpsellViewController: NSViewController {
    @IBOutlet var proIcon: NSImageView!
    @IBOutlet var titleField: NSTextField!
    @IBOutlet var bodyField: NSTextField!
    @IBOutlet var findOutMoreButton: NSButton!

    var currentFeature: ProFeature? {
        didSet {
            self.reloadData()
        }
    }

    var showFindOutMore: Bool = true {
        didSet {
            self.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.proIcon.image = CoppiceProUpsell.shared.proImage
        self.reloadData()
    }

    private func reloadData() {
        guard self.isViewLoaded, let feature = self.currentFeature else {
            return
        }

        self.titleField.stringValue = feature.title
        self.bodyField.stringValue = feature.body
        self.findOutMoreButton.isHidden = !self.showFindOutMore
    }

    @IBAction func findOutMore(_ sender: Any) {
        CoppiceProUpsell.shared.openProPage()
    }
}
