//
//  ContentSelectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class ContentSelectorViewController: NSViewController {
    @IBOutlet weak var stackView: NSStackView!

    let viewModel: ContentSelectorViewModel
    init(viewModel: ContentSelectorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ContentSelectorViewController", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        for type in self.viewModel.contentTypes {
            self.addButton(for: type)
        }
    }

    @objc func typeSelected(_ sender: NSButton?) {
        guard let tag = sender?.tag else {
            return
        }

        self.viewModel.selectType(self.viewModel.contentTypes[tag])
    }

    private func addButton(for type: ContentTypeModel) {
        guard let icon = NSImage(named: type.iconName) else {
			fatalError("Could not find type icon with name '\(type.iconName)'")
        }
        let button = NSButton(title: type.localizedName, image: icon, target: self, action: #selector(typeSelected(_:)))
        button.tag = self.stackView.arrangedSubviews.count
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imagePosition = .imageAbove
        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        button.heightAnchor.constraint(equalToConstant: 120).isActive = true
        button.isBordered = false
        button.imageScaling = .scaleProportionallyUpOrDown
        self.stackView.addArrangedSubview(button)
    }

}

extension ContentSelectorViewController: ContentSelectorView {

}
