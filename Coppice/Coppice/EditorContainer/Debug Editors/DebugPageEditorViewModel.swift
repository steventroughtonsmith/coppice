//
//  DebugPageEditorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class DebugPageEditorViewModel: NSObject {
    let page: Page
    init(page: Page) {
        self.page = page
        super.init()
    }
}
