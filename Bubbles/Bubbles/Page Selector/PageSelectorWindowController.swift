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
        preconditionFailure("init(coder:) has not been implemented")
    }

    func windowDidResignMain(_ notification: Notification) {
        self.close()
    }

    func show(over window: NSWindow?) {
        if let parentWindow = window, let selectorWindow = self.window {
            let parentFrame = parentWindow.frame
            var selectorFrame = selectorWindow.frame

            let deltaWidth = (parentFrame.width - selectorFrame.width) / 2
            selectorFrame.origin.x = parentFrame.minX + deltaWidth

            selectorFrame.origin.y = parentFrame.maxY - selectorFrame.height - 100

            selectorWindow.setFrameOrigin(selectorFrame.origin)
        }
        self.showWindow(self)
    }
}

extension PageSelectorWindowController: NSWindowDelegate {
    
}
