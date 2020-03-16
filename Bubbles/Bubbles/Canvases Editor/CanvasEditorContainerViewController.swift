//
//  CanvasesViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasesViewController: NSSplitViewController {
    let viewModel: CanvasesViewModel
    init(viewModel: CanvasesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CanvasEditorContainerView", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var canvasListViewController: CanvasListViewController = {
        let viewModel = CanvasListViewModel(documentWindowViewModel: self.viewModel.documentWindowViewModel)
        return CanvasListViewController(viewModel: viewModel)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.splitViewItems = [
            self.canvasListViewController.splitViewItem
        ]
    }


}


extension CanvasesViewController: Editor {
    var inspector: [Inspector] {
        return []
    }
}

