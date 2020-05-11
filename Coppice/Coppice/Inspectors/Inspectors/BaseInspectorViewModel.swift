//
//  BaseInspectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

class BaseInspectorViewModel: NSObject {
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
}
