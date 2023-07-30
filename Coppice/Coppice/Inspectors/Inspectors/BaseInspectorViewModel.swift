//
//  BaseInspectorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
import Foundation

class BaseInspectorViewModel: NSObject {
    override init() {
        super.init()
        self.setupProObservation()
    }

    @objc dynamic var title: String? {
        return nil
    }

    @objc dynamic var collapsed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: self.collapseIdentifier)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: self.collapseIdentifier)
        }
    }

    var collapseIdentifier: String {
        return "inspector"
    }

    //MARK: - Pro
    @objc dynamic var isProEnabled = false

    var activationObserver: AnyCancellable?
    private func setupProObservation() {
        self.activationObserver = CoppiceSubscriptionManager.shared.$state
            .sink { [weak self] newValue in
                self?.isProEnabled = (newValue == .enabled)
            }
    }
}
