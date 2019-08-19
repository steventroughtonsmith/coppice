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

    @IBOutlet weak var panelContainer: NSView!
    private var currentPanel: NSViewController?

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


    @IBAction func jumpToPage(_ sender: Any?) {
        guard let document = self.document as? Document else {
            return
        }

        let viewModel = PageSelectorViewModel(title: "Jump to page…", modelController: document.modelController) { page in
            print("page")
        }
        let pageSelector = PageSelectorViewController(viewModel: viewModel)
        self.present(pageSelector)
    }

    func present(_ pageSelector: PageSelectorViewController) {
        let view = pageSelector.view
        self.panelContainer.addSubview(view, withInsets: NSEdgeInsetsZero)
        self.panelContainer.isHidden = false
        self.currentPanel = pageSelector
    }
}

extension DocumentWindowController: SidebarViewModelDelegate {
    func selectedObjectDidChange(in viewModel: SidebarViewModel) {
        self.editorContainerViewController?.viewModel.currentObjectID = viewModel.selectedObjectID
    }
}
