//
//  PageInspectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class PageInspectorViewController: NSViewController, Inspector {

    let viewModel: PageInspectorViewModel
    init(viewModel: PageInspectorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "PageInspectorViewController", bundle: nil)
        self.viewModel.view = self
        self.title = NSLocalizedString("Page", comment: "Page inspector title")
        self.identifier = NSUserInterfaceItemIdentifier(rawValue: "inspector.page")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension PageInspectorViewController: PageInspectorView {

}
