//
//  CanvasEditorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasEditorViewController: NSViewController {

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var canvasView: NSView!
    @objc dynamic let viewModel: CanvasEditorViewModel
    init(viewModel: CanvasEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CanvasEditorViewController", bundle: nil)
        self.viewModel.view = self
        self.viewModel.layoutEngine.canvasView = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func addTestPage(_ sender: Any?) {
        self.viewModel.createTestPage()
    }

}

extension CanvasEditorViewController: CanvasEditorView {

}

extension CanvasEditorViewController: CanvasView {
    func add(_ pageView: PageLayoutModel) {

    }

    func remove(_ pageView: PageLayoutModel) {

    }

    func update(_ pageViews: [PageLayoutModel]) {

    }
}

