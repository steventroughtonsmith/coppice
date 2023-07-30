//
//  PageLinkController.swift
//  Coppice
//
//  Created by Martin Pilkington on 30/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore
import M3Data
import M3Subscriptions

class PageLinkController {
    let modelController: ModelController

    init(modelController: ModelController) {
        self.modelController = modelController
        self.setupObservation()
    }

    var activationObservation: AnyCancellable?
    private func setupObservation() {
        self.activationObservation = CoppiceSubscriptionManager.shared.$state.sink { [weak self] (state) in
            self?.updateManagers(with: state)
        }
    }

    private func updateManagers(with state: CoppiceSubscriptionManager.State) {
        self.pageLinkManagers.values.forEach {
            $0.isProEnabled = (state == .enabled)
        }
    }

    private var pageLinkManagers = [ModelID: PageLinkManager]()
    func pageLinkManager(for page: Page) -> PageLinkManager {
        if let manager = self.pageLinkManagers[page.id] {
            return manager
        }

        let newManager: PageLinkManager
        switch page.content.contentType {
        case .text:
            newManager = TextPageLinkManager(pageID: page.id, modelController: self.modelController)
        case .image:
            newManager = ImagePageLinkManager(pageID: page.id, modelController: self.modelController)
        }
        newManager.isProEnabled = CoppiceSubscriptionManager.shared.state == .enabled
        self.pageLinkManagers[page.id] = newManager
        return newManager
    }
}
