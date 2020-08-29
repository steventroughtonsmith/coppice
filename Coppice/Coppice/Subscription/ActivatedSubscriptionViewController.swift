//
//  ActivatedSubscriptionViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ActivatedSubscriptionViewController: NSViewController {

    let subscriptionManager: CoppiceSubscriptionManager
    init(subscriptionManager: CoppiceSubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        super.init(nibName: "ActivatedSubscriptionViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
