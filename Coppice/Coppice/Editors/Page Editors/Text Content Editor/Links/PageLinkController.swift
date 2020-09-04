//
//  PageLinkController.swift
//  Coppice
//
//  Created by Martin Pilkington on 30/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore
import Combine
import M3Subscriptions

class PageLinkController {
    let modelController: ModelController

    init(modelController: ModelController) {
        self.modelController = modelController
        self.setupObservation()
    }

    var activationObservation: AnyCancellable?
    private func setupObservation() {
        self.activationObservation = CoppiceSubscriptionManager.shared.$activationResponse.sink { [weak self] (response) in
            self?.updateManagers(with: response)
        }
    }

    private func updateManagers(with activationResponse: ActivationResponse?) {
        self.pageLinkManagers.values.forEach {
            $0.isProEnabled = (activationResponse?.isActive ?? false)
        }
    }

    private var pageLinkManagers = [ModelID: PageLinkManager]()
    func pageLinkManager(for page: Page) -> PageLinkManager {
        if let manager = self.pageLinkManagers[page.id] {
            return manager
        }

        let newManager = PageLinkManager(pageID: page.id, modelController: self.modelController)
        newManager.isProEnabled = CoppiceSubscriptionManager.shared.activationResponse?.isActive ?? false
        self.pageLinkManagers[page.id] = newManager
        return newManager
    }
}
