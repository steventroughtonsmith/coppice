//
//  ZoomMenuDelegate.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

class ZoomMenuDelegate: NSObject, NSMenuDelegate {
    var zoomLevels = [Int]()
    var selectedLevel: Int?

    func numberOfItems(in menu: NSMenu) -> Int {
        return zoomLevels.count
    }

    func menu(_ menu: NSMenu, update item: NSMenuItem, at index: Int, shouldCancel: Bool) -> Bool {
        item.title = "\(zoomLevels[index])%"
        item.action = #selector(zoomControlChanged(_:))
        item.target = nil
        if let level = selectedLevel {
            item.state = (index == level) ? .on : .off
        }
        return true
    }

    @objc func zoomControlChanged(_ sender: NSMenuItem?) {}
}
