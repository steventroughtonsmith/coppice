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

    private var pageSelectorWindowController: PageSelectorWindowController?

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
        self.showPageSelector(title: "Jump to page…") { [weak self] page in
            self?.editorContainerViewController?.viewModel.currentObjectID = page.id
            self?.sidebarViewController?.viewModel.selectedObjectID = page.id
        }
    }

    func showPageSelector(title: String, callback: @escaping PageSelectorViewModel.SelectionBlock) {
        guard let document = self.document as? Document else {
            return
        }

        let viewModel = PageSelectorViewModel(title: title, modelController: document.modelController) { [weak self] page in
            callback(page)
            self?.pageSelectorWindowController = nil
        }
        self.pageSelectorWindowController = PageSelectorWindowController(viewModel: viewModel)
        self.pageSelectorWindowController?.show(over: self.window)
    }


    //MARK: - Responder Chain
    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        if let editor = self.editorContainerViewController?.currentEditor,
            editor.responds(to: action) {
            return editor
        }
        return super.supplementalTarget(forAction: action, sender: sender)
    }


    //MARK: - Debugging
    @IBAction func logResponderChain(_ sender: Any?) {
        var responder = self.window?.firstResponder
        var prefix = "|--"
        while responder != nil {
            print("\(prefix)\(responder!)")
            prefix = "   \(prefix)"
            responder = responder?.nextResponder
        }
    }
}

extension DocumentWindowController: SidebarViewModelDelegate {
    func selectedObjectDidChange(in viewModel: SidebarViewModel) {
        self.editorContainerViewController?.viewModel.currentObjectID = viewModel.selectedObjectID
    }
}
