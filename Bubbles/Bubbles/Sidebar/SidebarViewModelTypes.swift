//
//  SidebarViewModelTypes.swift
//  Bubbles
//
//  Created by Martin Pilkington on 31/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol SidebarItem: class {
    var id: ModelID { get }
    var title: String { get }
}

class CanvasSidebarItem: NSObject, SidebarItem {
    let canvas: Canvas
    init(canvas: Canvas) {
        self.canvas = canvas
    }

    var id: ModelID { self.canvas.id }
    @objc dynamic var title: String { self.canvas.title }
}

class PageSidebarItem: NSObject, SidebarItem {
    let page: Page
    init(page: Page) {
        self.page = page
    }

    var id: ModelID { self.page.id }
    @objc dynamic var title: String { self.page.title }
}
