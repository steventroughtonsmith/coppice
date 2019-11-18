//
//  Inspector.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa


protocol Inspector {
    var title: String? { get }
    var collapseIdentifier: String { get }
}


extension Inspector where Self: NSViewController {
    var collapseIdentifier: String {
        return self.identifier?.rawValue ?? "inspector"
    }
}
