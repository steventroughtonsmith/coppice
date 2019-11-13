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

    let documentWindowState = DocumentWindowState()

    override func windowDidLoad(){
        super.windowDidLoad()

        self.setupViewControllers()
    }

    private func setupViewControllers() {
        guard let document = self.document as? Document else {
            return
        }

        let sidebarVM = SidebarViewModel(modelController: document.modelController, documentWindowState: self.documentWindowState)
        self.sidebarViewController = SidebarViewController(viewModel: sidebarVM)

        self.editorContainerViewController = EditorContainerViewController(viewModel: EditorContainerViewModel(modelController: document.modelController, documentWindowState: self.documentWindowState))
    }


    @IBAction func jumpToPage(_ sender: Any?) {
        self.showPageSelector(title: "Jump to page…") { [weak self] page in
            self?.openPage(at: page.linkToPage())
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


    //MARK: - Displaying Page
    @discardableResult func openPage(at pageLink: PageLink) -> Bool {
        guard let document = self.document as? Document,
            (document.modelController.object(with: pageLink.destination) != nil) else {
            return false
        }

        let selectedObjectID = self.sidebarViewController?.viewModel.selectedObjectID
        guard (selectedObjectID?.modelType != Canvas.modelType) else {
            //In theory canvasEditor should always be set if the selected object is a Canvas but we want to exit early regardless as it's a bit more predicatable
            guard let canvasEditor = self.editorContainerViewController?.mainEditor as? CanvasEditorViewController else {
                return false
            }
            canvasEditor.viewModel.addPage(at: pageLink)
            return true
        }

        self.selectObject(with: pageLink.destination)
        return true
    }

    func selectObject(with id: ModelID) {
        self.documentWindowState.selectedSidebarObjectIDString = id.stringRepresentation
    }


    //MARK: - Responder Chain
    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        if let editor = self.editorContainerViewController?.mainEditor,
            editor.responds(to: action) {
            return editor
        }
        return super.supplementalTarget(forAction: action, sender: sender)
    }


    //MARK: - Actions
    @IBAction func newPage(_ sender: Any?) {
        guard let document = self.document as? Document,
            let sidebarVM = self.sidebarViewController?.viewModel else {
            return
        }
        let page = document.modelController.collection(for: Page.self).newObject()
        guard let selectedObjectID = sidebarVM.selectedObjectID, (selectedObjectID.modelType == Canvas.modelType) else {
            sidebarVM.selectedObjectID = page.id
            return
        }

        if let canvas = document.modelController.collection(for: Canvas.self).objectWithID(selectedObjectID) {
            canvas.add(page)
        }
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
