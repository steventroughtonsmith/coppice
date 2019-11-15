//
//  InspectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol InspectorView: class {

}


class InspectorViewModel: NSObject {
    weak var view: InspectorView?

    let inspector: Inspector
    init(inspector: Inspector) {
        self.inspector = inspector
        super.init()
    }


   @objc dynamic var title: String? {
        return self.inspector.title
    }

    @objc dynamic var collapsed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: self.inspector.collapseIdentifier)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: self.inspector.collapseIdentifier)
        }
    }

    
}
