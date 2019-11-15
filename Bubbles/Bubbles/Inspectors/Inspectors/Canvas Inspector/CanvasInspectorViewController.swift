//
//  CanvasInspectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasInspectorViewController: NSViewController, Inspector {

    let viewModel: CanvasInspectorViewModel
    init(viewModel: CanvasInspectorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CanvasInspectorViewController", bundle: nil)
        self.viewModel.view = self
        self.title = NSLocalizedString("Canvas", comment: "Canvas inspector title")
        self.identifier = NSUserInterfaceItemIdentifier(rawValue: "inspector.canvas")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension CanvasInspectorViewController: CanvasInspectorView {

}
