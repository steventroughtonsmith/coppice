//
//  NoEditorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class NoEditorViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    var enabled: Bool = true
}


extension NoEditorViewController: Editor {
    var inspectors: [Inspector] {
        return []
    }
}
