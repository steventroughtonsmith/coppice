//
//  DocumentWindowController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 09/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class DocumentWindowController: NSWindowController {
    @IBOutlet weak var splitView: NSSplitView!

    @IBOutlet weak var sidebarContainer: NSView!
    @IBOutlet weak var editorContainer: NSView!
    @IBOutlet weak var inspectorContainer: NSView!

    var sidebarViewController: SidebarViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let newVC = self.sidebarViewController {
                sidebarContainer.addSubview(newVC.view, withInsets: NSEdgeInsetsZero)
            }
        }
    }

    var editorContainerViewController: EditorContainerViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let newVC = self.editorContainerViewController {
                editorContainer.addSubview(newVC.view, withInsets: NSEdgeInsetsZero)
            }
        }
    }

    override func windowDidLoad(){
        super.windowDidLoad()

        self.setupViewControllers()
    }

    private func setupViewControllers() {
        guard let document = self.document as? Document else {
            return
        }

        let sidebarVM = SidebarViewModel(modelController: document.modelController)
        sidebarVM.delegate = self
        self.sidebarViewController = SidebarViewController(viewModel: sidebarVM)

        self.editorContainerViewController = EditorContainerViewController(viewModel: EditorContainerViewModel(modelController: document.modelController))
    }
    
}

extension DocumentWindowController: SidebarViewModelDelegate {
    func selectedObjectDidChange(in viewModel: SidebarViewModel) {
        self.editorContainerViewController?.viewModel.currentObject = viewModel.selectedObject
    }
}
