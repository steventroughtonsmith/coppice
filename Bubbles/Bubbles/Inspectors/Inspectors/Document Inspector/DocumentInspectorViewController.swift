//
//  DocumentInspectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class DocumentInspectorViewController: NSViewController, Inspector {

    let viewModel: DocumentInspectorViewModel
    init(viewModel: DocumentInspectorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "DocumentInspectorViewController", bundle: nil)
        self.viewModel.view = self
        self.title = NSLocalizedString("Document", comment: "Document inspector title")
        self.identifier = NSUserInterfaceItemIdentifier(rawValue: "inspector.document")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DocumentInspectorViewController: DocumentInspectorView {

}
