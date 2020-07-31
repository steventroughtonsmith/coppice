//
//  DebugPageEditor.swift
//  Coppice
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
        preconditionFailure("init(coder:) has not been implemented")
    }

    var enabled: Bool = true
}

extension DebugPageEditor: Editor {
    var inspectors: [Inspector] {
        return []
    }
}
