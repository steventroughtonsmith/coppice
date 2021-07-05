//
//  PageSelectorWindowController.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class PageSelectorWindowController: NSWindowController {
    let viewController: PageSelectorViewController
    let viewModel: PageSelectorViewModel
    init(viewModel: PageSelectorViewModel) {
        self.viewModel = viewModel
        self.viewController = PageSelectorViewController(viewModel: viewModel)
        let window = PageSelectorWindow(contentViewController: self.viewController)

        super.init(window: window)

        window.delegate = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    func windowDidResignMain(_ notification: Notification) {
        guard self.viewController.displayMode == .fromWindow else {
            return
        }
        self.close()
    }

    func show(over window: NSWindow?) {
        self.viewController.displayMode = .fromWindow
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

    func show(from view: NSView, preferredEdge: NSRectEdge) {
        guard
            let parentWindow = view.window,
            let window = self.window
        else {
            return
        }
        self.viewController.displayMode = .fromView
        let frameInWindow = view.convert(view.frame, to: nil)
        let frameInScreen = parentWindow.convertToScreen(frameInWindow)

        let width = max(view.frame.width, 250)
        let height = width / 2 * 3
        let x = frameInScreen.minX - 8
        let y = frameInScreen.minY - height - 4

        self.window?.setFrame(CGRect(x: x, y: y, width: width, height: height), display: false)

        parentWindow.addChildWindow(window, ordered: .above)
        window.orderFront(self)
    }
}

extension PageSelectorWindowController: NSWindowDelegate {}
