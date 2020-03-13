//
//  DocumentWindowController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 09/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class DocumentWindowController: NSWindowController {
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var splitViewControl: NSSegmentedControl!

    let splitViewController: RootSplitViewController

    @IBOutlet weak var searchField: NSSearchField!

    private var pageSelectorWindowController: PageSelectorWindowController?



    @objc dynamic let viewModel: DocumentWindowViewModel
    init(viewModel: DocumentWindowViewModel) {
        self.viewModel = viewModel

        self.splitViewController = RootSplitViewController(sidebarViewController: SidebarViewController(viewModel: .init(documentWindowViewModel: viewModel)),
                                                           canvasListViewController: CanvasListViewController(viewModel: .init(documentWindowViewModel: viewModel)),
                                                           editorContainerViewController: EditorContainerViewController(viewModel: .init(documentWindowViewModel: viewModel)),
                                                           inspectorContainerViewController: InspectorContainerViewController(viewModel: .init(documentWindowViewModel: viewModel)))
        super.init(window: nil)

        self.contentViewController = self.splitViewController
        viewModel.window = self
    }

    override var windowNibName: NSNib.Name? {
        return "DocumentWindow"
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    override func windowDidLoad(){
        super.windowDidLoad()

        self.contentViewController = self.splitViewController

//        self.sidebarViewController.pagesTable.nextKeyView = self.editorContainerViewController.view
//        self.editorContainerViewController.view.nextKeyView = self.inspectorContainerViewController.view
    }

    @IBAction func jumpToPage(_ sender: Any?) {
        self.showPageSelector(title: "Jump to page…") { [weak self] page in
            self?.viewModel.openPage(at: page.linkToPage())
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


    //MARK: - Toolbar
    func setupNewPageToolbarItem() {
        
    }


    //MARK: - Responder Chain
    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        if let editor = self.splitViewController.editorSplitViewController.editorContainerViewController.mainEditor,
            editor.responds(to: action) {
            print("calling to editor from window with \(action)")
            return editor
        }
        return super.supplementalTarget(forAction: action, sender: sender)
    }


    //MARK: - Actions
    @IBAction func newPage(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem,
            let rawType = menuItem.representedObject as? String,
            let type = PageContentType(rawValue: rawType) else {
                self.viewModel.createPage()
                return
        }
        self.viewModel.createPage(ofType: type)
    }

    @IBAction func newCanvas(_ sender: Any?) {
        self.viewModel.createCanvas()
    }

    @IBAction func deletePage(_ sender: Any?) {
        #warning("Add functionality back")
//        if (self.viewModel.selectedPagesInSidebar.count == 1), let page = self.viewModel.selectedPagesInSidebar.first {
//            self.viewModel.delete(page)
//        }
    }

    @IBAction func deleteCanvas(_ sender: Any?) {
        #warning("Add functionality back")
//        if let canvas = self.viewModel.selectedCanvasInSidebar {
//            self.viewModel.delete(canvas)
//        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(deletePage(_:)) {
//            return (self.viewModel.selectedPagesInSidebar.count == 1)
        }
        if menuItem.action == #selector(deleteCanvas(_:)) {
//            return (self.viewModel.selectedCanvasInSidebar != nil)
        }
        return true
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


    //MARK: - State Restoration
    override func encodeRestorableState(with coder: NSCoder) {
        let selectedIDStrings = self.viewModel.selectedSidebarObjectIDs.map { $0.stringRepresentation }
        coder.encode(selectedIDStrings, forKey: "selectedSidebarObjectIDs")
        super.encodeRestorableState(with: coder)
    }

    override func restoreState(with coder: NSCoder) {
        if let modelIDStrings = coder.decodeObject(forKey: "selectedSidebarObjectIDs") as? [String] {
            let selectedIDs = Set(modelIDStrings.compactMap { ModelID(string: $0) })
            self.viewModel.selectedSidebarObjectIDs = selectedIDs
        }
        super.restoreState(with: coder)
    }


    //MARK: - Actions
    @IBAction func findInDocument(_ sender: Any?) {
        self.window?.makeFirstResponder(self.searchField)
    }

    @IBAction func importFiles(_ sender: Any?) {
        guard let window = self.window else {
            return
        }
        let panel = NSOpenPanel()
        panel.allowedFileTypes = [kUTTypeText as String, kUTTypeImage as String]
        panel.allowsMultipleSelection = true
        panel.prompt = NSLocalizedString("Import", comment: "Import button title")
        panel.beginSheetModal(for: window) { [weak self] (response) in
            guard response == .OK else {
                return
            }
            self?.viewModel.importFiles(at: panel.urls)
        }
    }



    //MARK: - Split View Management

    @IBAction func splitViewControlChanged(_ sender: Any) {
        //        self.splitViewController.isSidebarCollapsed = !self.splitViewControl.isSelected(forSegment: 0)
        //        self.splitViewController.isInspectorCollapsed = !self.splitViewControl.isSelected(forSegment: 1)
    }

    private func updateSplitViewControl() {
        //        self.splitViewControl.setSelected(!self.splitViewController.isSidebarCollapsed, forSegment: 0)
        //        self.splitViewControl.setSelected(!self.splitViewController.isInspectorCollapsed, forSegment: 1)
    }

}

extension DocumentWindowController: DocumentWindow {
    func showAlert(_ alert: Alert, callback: @escaping (Int) -> Void) {
        guard let window = self.window else {
            return
        }

        alert.nsAlert.beginSheetModal(for: window) { (response) in
            callback(response.rawValue)
        }
    }
}
