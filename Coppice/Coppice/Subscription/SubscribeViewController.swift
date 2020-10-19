//
//  SubscribeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SubscribeViewController: NSViewController, DeactivatedSubscriptionMode {
    let header = NSLocalizedString("Upgrade to Pro", comment: "")
    let subheader = NSLocalizedString("Unlock all of Coppice's features for just $19.99 a year", comment: "")
    let actionName = NSLocalizedString("Upgrade now for $19.99/year", comment: "")
    let toggleName = NSLocalizedString("Already subscribed? Sign In", comment: "")

    func performAction(_ sender: NSButton) {
        self.subscriptionManager.openProPage()
    }

    let subscriptionManager: CoppiceSubscriptionManager
    init(subscriptionManager: CoppiceSubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        super.init(nibName: "SubscribeViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var featureStackView: NSStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupFeatureGrid()
    }

    private let numberOfColumns = 2

    private func setupFeatureGrid() {
        guard
            let featuresURL = Bundle.main.url(forResource: "ProFeatures", withExtension: "plist"),
            let data = try? Data(contentsOf: featuresURL),
            let featureList = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [[String: String]]
        else {
            return
        }

        let cells = featureList.compactMap { cell(forFeature: $0) }

        var row = [ProFeatureCell]()
        for cell in cells {
            row.append(cell)

            if row.count == self.numberOfColumns {
                self.addFeatureRow(with: row)
                row.removeAll()
            }
        }

        if row.count > 0 {
            self.addFeatureRow(with: row)
        }
    }

    private func cell(forFeature feature: [String: String]) -> ProFeatureCell? {
        guard
            let title = feature["title"],
            let body = feature["body"]
        else {
            return nil
        }
        let cell = ProFeatureCell.createFromNIB()
        cell.titleField.stringValue = title
        cell.bodyField.stringValue = body
        return cell
    }

    private func addFeatureRow(with cells: [ProFeatureCell]) {
        var views = cells as [NSView]
        while views.count < self.numberOfColumns {
            let view = NSView()
            view.translatesAutoresizingMaskIntoConstraints = false
            views.append(view)
        }

        let stackView = NSStackView(views: views)
        stackView.orientation = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        self.featureStackView.addArrangedSubview(stackView)
        stackView.trailingAnchor.constraint(equalTo: self.featureStackView.trailingAnchor).isActive = true
    }

}
