//
//  NestableSplitView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 06/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

@objc protocol NestableSplitViewDelegate: NSSplitViewDelegate {
    func willStartDrag(in splitView: NestableSplitView)
    func didFinishDrag(in splitView: NestableSplitView)
}


class NestableSplitView: NSSplitView {
    @IBOutlet weak var nestableDelegate: NestableSplitViewDelegate?

    override func mouseDown(with event: NSEvent) {
        self.nestableDelegate?.willStartDrag(in: self)
        super.mouseDown(with: event)
        self.nestableDelegate?.didFinishDrag(in: self)
    }
}
