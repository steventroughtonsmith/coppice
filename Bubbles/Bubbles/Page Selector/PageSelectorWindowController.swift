//
//  PageSelectorWindowController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 19/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class PageSelectorWindowController: NSWindowController {

    init(viewModel: PageSelectorViewModel) {
        let viewController = PageSelectorViewController(viewModel: viewModel)
        let window = PageSelectorWindow(contentViewController: viewController)

        super.init(window: window)

        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowDidResignMain(_ notification: Notification) {
        self.close()
    }
}

extension PageSelectorWindowController: NSWindowDelegate {
    
}
