//
//  SubscribeViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SubscribeViewController: NSViewController {

    func createTabItem() -> NSTabViewItem {
        let item = NSTabViewItem(viewController: self)
        item.label = NSLocalizedString("Coppice Pro", comment: "Pro Preferences Title")
        item.image = NSImage(named: "NSNetwork")
        return item
    }

    @IBOutlet weak var featureContainer: NSView!
    @IBOutlet weak var featureStackView: NSStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.featureContainer.wantsLayer = true
        self.featureContainer.layer?.backgroundColor = NSColor(white: 0.32, alpha: 1).cgColor

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
            let iconName = feature["icon"],
            let body = feature["body"]
        else {
            return nil
        }
        let cell = ProFeatureCell.createFromNIB()
        cell.titleField.stringValue = title
        cell.iconView.image = NSImage(named: iconName)
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
