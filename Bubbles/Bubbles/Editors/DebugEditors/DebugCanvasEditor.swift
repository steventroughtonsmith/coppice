//
//  DebugCanvasEditor.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class DebugCanvasEditor: NSViewController, Editor {
    let viewModel: DebugCanvasEditorViewModel
    init(viewModel: DebugCanvasEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "DebugCanvasEditor", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
