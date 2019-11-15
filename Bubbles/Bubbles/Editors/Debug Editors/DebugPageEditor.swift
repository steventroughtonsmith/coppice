//
//  DebugPageEditor.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class DebugPageEditor: NSViewController {
    let viewModel: DebugPageEditorViewModel
    init(viewModel: DebugPageEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "DebugPageEditor", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DebugPageEditor: Editor {
    var inspectors: [Inspector] {
        return []
    }
}
