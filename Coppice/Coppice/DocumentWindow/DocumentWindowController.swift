//
//  DocumentWindowController.swift
//  Coppice
//
//  Created by Martin Pilkington on 09/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine


class DocumentWindowController: NSWindowController {
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
        
        guard let window = self.window else {
            return
        }
        
        if #available(OSX 10.16, *) {
            window.styleMask.insert(.fullSizeContentView)
        }

        if let contentView = window.contentView {
            self.splitViewController.view.frame = contentView.bounds
        }
        self.contentViewController = self.splitViewController

//        self.sidebarViewController.pagesTable.nextKeyView = self.editorContainerViewController.view
//        self.editorContainerViewController.view.nextKeyView = self.inspectorContainerViewController.view
        self.setupNewPageSegmentedControl()
    }

    func performNewDocumentSetup() {
        self.splitViewController.sidebarViewController.performNewDocumentSetup()
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
    @IBOutlet weak var newPageSegmentedControl: NSSegmentedControl!

    lazy var newPageMenuDelegate: NewPageMenuDelegate = {
        let delegate = NewPageMenuDelegate()
        delegate.includeKeyEquivalents = false
        delegate.includeIcons = true
        return delegate
    }()

    lazy var newPageMenu: NSMenu = {
        let menu = NSMenu()
        menu.delegate = self.newPageMenuDelegate
        return menu
    }()

    var lastCreatedPageTypeObserver: AnyCancellable?
    private func setupNewPageSegmentedControl() {
        self.newPageSegmentedControl.setMenu(self.newPageMenu, forSegment: 1)
        self.lastCreatedPageTypeObserver = self.viewModel.$lastCreatePageType
            .map(\.addIcon)
            .sink { [weak self] (icon) in
                self?.newPageSegmentedControl.setImage(icon, forSegment: 0)
            }
    }

    @IBAction func toolbarNewPage(_ sender: Any) {
        guard
            let control = sender as? NSSegmentedControl,
            control.selectedSegment == 0
        else {
            return
        }

        NSApp.sendAction(#selector(NewPageMenuDelegate.newPage(_:)), to: nil, from: sender)
    }



    //MARK: - Responder Chain
    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        if let editor = self.splitViewController.editorContainerViewController.mainEditor {
            if let target = editor.supplementalTarget(forAction: action, sender: sender) {
                return target
            }
            if editor.responds(to: action) {
                return editor
            }
        }
        if let target = self.splitViewController.sidebarViewController.supplementalTarget(forAction: action, sender: sender) {
            return target
        }
        return super.supplementalTarget(forAction: action, sender: sender)
    }


    //MARK: - Actions

    @IBAction func newCanvas(_ sender: Any?) {
        self.viewModel.modelController.createCanvas()
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
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

    @IBAction func add10PagesToCanvas(_ sender: Any?) {
        (0..<10).forEach { _ in
            self.viewModel.modelController.createPage(ofType: .text, in: self.viewModel.folderForNewPages)
        }
    }


    //MARK: - State Restoration
    override func encodeRestorableState(with coder: NSCoder) {
        self.viewModel.encodeRestorableState(with: coder)
        super.encodeRestorableState(with: coder)
    }

    override func restoreState(with coder: NSCoder) {
        self.viewModel.restoreState(with: coder)
        super.restoreState(with: coder)
    }


    //MARK: - Actions
    @IBAction func findInDocument(_ sender: Any?) {
        self.window?.makeFirstResponder(self.searchField)
    }

    #if DEBUG
    lazy var previewGenerationWindowController: NSWindowController = {
        return PreviewGenerationDebugWindow(documentViewModel: self.viewModel)
    }()

    @IBAction func showPreviewGenerationWindow(_ sender: Any?) {
        self.previewGenerationWindowController.window?.makeKeyAndOrderFront(sender)
    }
    #endif
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
