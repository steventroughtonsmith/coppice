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

    @IBOutlet weak var sidebarContainer: NSView!
    @IBOutlet weak var editorContainer: NSView!
    @IBOutlet weak var inspectorContainer: NSView!

    @IBOutlet weak var searchField: NSSearchField!

    private var pageSelectorWindowController: PageSelectorWindowController?

    var sidebarViewController: SidebarViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let newVC = self.sidebarViewController {
                self.sidebarContainer.addSubview(newVC.view, withInsets: NSEdgeInsetsZero)
            }
        }
    }

    var editorContainerViewController: EditorContainerViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let newVC = self.editorContainerViewController {
                self.editorContainer.addSubview(newVC.view, withInsets: NSEdgeInsetsZero)
            }
        }
    }

    var inspectorContainerViewController: InspectorContainerViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            if let newVC = self.inspectorContainerViewController {
                self.inspectorContainer.addSubview(newVC.view, withInsets: NSEdgeInsetsZero)
            }
        }
    }

    @objc dynamic let viewModel: DocumentWindowViewModel
    init(viewModel: DocumentWindowViewModel) {
        self.viewModel = viewModel
        super.init(window: nil)
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

        self.splitViewController.splitView = self.splitView
        self.splitViewController.delegate = self as SplitViewControllerDelegate
        self.setupViewControllers()

        self.sidebarViewController?.pagesTable.nextKeyView = self.editorContainerViewController?.view
        self.editorContainerViewController?.view.nextKeyView = self.inspectorContainerViewController?.view
    }

    private func setupViewControllers() {
        guard let document = self.document as? Document else {
            return
        }

        self.viewModel.document = document

        let sidebarVM = SidebarViewModel(documentWindowViewModel: self.viewModel)
        self.sidebarViewController = SidebarViewController(viewModel: sidebarVM)

        self.editorContainerViewController = EditorContainerViewController(viewModel: EditorContainerViewModel(documentWindowViewModel: self.viewModel))
        self.editorContainerViewController?.delegate = self
        self.inspectorContainerViewController = InspectorContainerViewController(viewModel: InspectorContainerViewModel(documentWindowViewModel: self.viewModel))
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

        guard self.viewModel.selectedCanvasInSidebar == nil else {
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
        self.viewModel.selectedSidebarObjectIDs = Set([id])
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
        self.viewModel.createPage()
    }

    @IBAction func newCanvas(_ sender: Any?) {
        self.viewModel.createCanvas()
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


    //MARK: - Split View Management
    private let splitViewController = SplitViewController()

    @IBAction func splitViewControlChanged(_ sender: Any) {
        self.splitViewController.isSidebarCollapsed = !self.splitViewControl.isSelected(forSegment: 0)
        self.splitViewController.isInspectorCollapsed = !self.splitViewControl.isSelected(forSegment: 1)
    }

    private func updateSplitViewControl() {
        self.splitViewControl.setSelected(!self.splitViewController.isSidebarCollapsed, forSegment: 0)
        self.splitViewControl.setSelected(!self.splitViewController.isInspectorCollapsed, forSegment: 1)
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


extension DocumentWindowController: EditorContainerViewControllerDelegate {
    func open(_ page: PageLink, from viewController: EditorContainerViewController) {
        self.openPage(at: page)
    }
}


extension DocumentWindowController: SplitViewControllerDelegate {
    func collapsedStatedDidChange(in splitViewController: SplitViewController) {
        self.updateSplitViewControl()
    }
}
