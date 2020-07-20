//
//  PageLinkController.swift
//  Coppice
//
//  Created by Martin Pilkington on 30/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class PageLinkController {
    let modelController: ModelController
    init(modelController: ModelController) {
        self.modelController = modelController
    }

    private var pageLinkManagers = [ModelID: PageLinkManager]()
    func pageLinkManager(for page: Page) -> PageLinkManager {
        if let manager = self.pageLinkManagers[page.id] {
            return manager
        }

        let newManager = PageLinkManager(pageID: page.id, modelController: self.modelController)
        self.pageLinkManagers[page.id] = newManager
        return newManager
    }
}
