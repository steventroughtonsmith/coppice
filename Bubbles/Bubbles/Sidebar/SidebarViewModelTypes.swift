//
//  SidebarViewModelTypes.swift
//  Bubbles
//
//  Created by Martin Pilkington on 31/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

class SidebarItem {
    enum CellType {
        case bigCell
        case smallCell
        case groupCell
    }
    let title: String
    let image: NSImage?
    let cellType: CellType

    init(title: String, image: NSImage?, cellType: CellType = .smallCell) {
        self.title = title
        self.image = image
        self.cellType = cellType
    }

    weak var parent: SidebarItem?
    private(set) var children = [SidebarItem]()
    func addChild(_ child: SidebarItem) {
        child.parent = self
        self.children.append(child)
    }
}
