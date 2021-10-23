//
//  DocumentWindowController.swift
//  Coppice
//
//  Created by Martin Pilkington on 09/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore
import M3Subscriptions

class DocumentWindowController: NSWindowController, NSMenuItemValidation {
    let splitViewController: RootSplitViewController
    let documentContentViewController = DocumentContentViewController()

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

    override func windowDidLoad() {
        super.windowDidLoad()

        guard let window = self.window else {
            return
        }

        if #available(OSX 10.16, *) {
            window.styleMask.insert(.fullSizeContentView)
        }

        self.documentContentViewController.addChild(self.splitViewController)
        self.documentContentViewController.view.addSubview(self.splitViewController.view, withInsets: NSEdgeInsetsZero)

        if let contentView = window.contentView {
            self.documentContentViewController.view.frame = contentView.bounds
        }
        self.contentViewController = self.documentContentViewController

//        self.sidebarViewController.pagesTable.nextKeyView = self.editorContainerViewController.view
//        self.editorContainerViewController.view.nextKeyView = self.inspectorContainerViewController.view
        self.setupNewPageSegmentedControl()

        self.setupToolbar()
    }

    var mainToolbarDelegate: MainToolbarDelegate?
    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: "mainToolbar")
        toolbar.autosavesConfiguration = true
        toolbar.allowsUserCustomization = true
        if #available(OSX 10.16, *) {
            toolbar.displayMode = .iconOnly
        } else {
            toolbar.displayMode = .iconAndLabel
        }

        let toolbarDelegate = MainToolbarDelegate(toolbar: toolbar,
                                                  searchField: self.searchField,
                                                  newPageControl: self.newPageSegmentedControl,
                                                  splitView: self.splitViewController.splitView)
        self.mainToolbarDelegate = toolbarDelegate
        self.window?.toolbar = toolbar
    }

    func performNewDocumentSetup() {
        self.splitViewController.sidebarViewController.performNewDocumentSetup()
    }

    @IBAction func jumpToPage(_ sender: Any?) {
        self.showPageSelector(title: "Jump to page…") { [weak self] result in
            guard case .page(let page) = result else {
                return
            }
            self?.viewModel.openPage(at: page.linkToPage())
        }
    }

    func showPageSelector(title: String, callback: @escaping PageSelectorViewModel.SelectionBlock) {
        let viewModel = PageSelectorViewModel(title: title, documentWindowViewModel: self.viewModel) { [weak self] page in
            callback(page)
            self?.pageSelectorWindowController = nil
        }
        self.pageSelectorWindowController = PageSelectorWindowController(viewModel: viewModel)
        self.pageSelectorWindowController?.show(over: self.window)
    }


    //MARK: - Toolbar
    var newPageSegmentedControl: NSSegmentedControl = {
        let image = NSImage.symbol(withName: Symbols.Page.text(.small))!
        let control = HoverSegmentedControl(images: [image],
                                            trackingMode: .momentary,
                                            target: nil,
                                            action: #selector(NewPageMenuDelegate.newPage(_:)))
        var controlWidth: CGFloat = 35
        if #available(OSX 10.16, *) {
            controlWidth = 30
        }
        control.setWidth(controlWidth, forSegment: 0)
        return control
    }()

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
        self.newPageSegmentedControl.setMenu(self.newPageMenu, forSegment: 0)
        self.lastCreatedPageTypeObserver = self.viewModel.$lastCreatePageType
            .map(\.addIcon)
            .sink { [weak self] (icon) in
                self?.newPageSegmentedControl.setImage(icon, forSegment: 0)
                self?.newPageTouchBarItem?.collapsedRepresentationImage = icon
            }
    }


    //MARK: - Info Alerts
    func displayInfoAlert(_ infoAlert: InfoAlert) {
        let viewController = InfoAlertViewController(alert: infoAlert)
        viewController.didDismissBlock = { [weak self] in
            self?.documentContentViewController.currentInfoAlert = nil
        }
        self.documentContentViewController.currentInfoAlert = viewController
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

    private var canCreateCanvases: Bool {
        let proEnabled = CoppiceSubscriptionManager.shared.activationResponse?.isActive == true
        let hasCanvases = self.viewModel.modelController.canvasCollection.all.count > 0
        return proEnabled || !hasCanvases
    }

    @IBAction func newCanvas(_ sender: Any?) {
        guard self.canCreateCanvases else {
            self.showCanvasProPopover(from: sender)
            return
        }
        self.viewModel.modelController.createCanvas()
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if (menuItem.action == #selector(self.newCanvas(_:))) {
            let subManager = CoppiceSubscriptionManager.shared
            let proEnabled = (subManager.activationResponse?.isActive == true)

            menuItem.image = proEnabled ? nil : subManager.proImage
            menuItem.toolTip = self.canCreateCanvases ? nil : NSLocalizedString("Creating more than 1 canvas requires a Coppice Pro subscription", comment: "Canvas creation Coppice Pro subscription")

            return self.canCreateCanvases
        }
        return true
    }

    private func showCanvasProPopover(from sender: Any?) {
        guard let view = sender as? NSView else {
            return
        }

        CoppiceSubscriptionManager.shared.showProPopover(for: .unlimitedCanvases, from: view, preferredEdge: .maxY)
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
