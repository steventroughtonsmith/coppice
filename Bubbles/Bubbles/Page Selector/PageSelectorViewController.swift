//
//  PageSelectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class PageSelectorViewController: NSViewController {

    @IBOutlet weak var searchField: NSTextField!
    @objc dynamic let viewModel: PageSelectorViewModel
    init(viewModel: PageSelectorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "PageSelectorViewController", bundle: nil)
        viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchField.placeholderString = self.viewModel.title
    }
}

extension PageSelectorViewController: PageSelectorView {

}
