//
//  SimpleLabelPopoverViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SimpleLabelPopoverViewController: NSViewController {
    @objc dynamic let label: String
    init(label: String) {
        self.label = label
        super.init(nibName: "SimpleLabelPopoverViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
