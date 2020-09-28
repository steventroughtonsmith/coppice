//
//  NestableSplitView.swift
//  Coppice
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
        NotificationCenter.default.post(name: .nestableSplitViewWillStartDrag, object: self)
        super.mouseDown(with: event)
        NotificationCenter.default.post(name: .nestableSplitViewDidEndDrag, object: self)
        self.nestableDelegate?.didFinishDrag(in: self)
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        //Big Sur for some reason adds support for toggling sidebars to NSSplitView which we don't want
        if aSelector == #selector(NSSplitViewController.toggleSidebar(_:)) {
            return false
        }
        return super.responds(to: aSelector)
    }
}

extension Notification.Name {
    static let nestableSplitViewWillStartDrag = Notification.Name(rawValue: "SplitViewWillStartDrag")
    static let nestableSplitViewDidEndDrag = Notification.Name(rawValue: "SplitViewDidEndDrag")
}
