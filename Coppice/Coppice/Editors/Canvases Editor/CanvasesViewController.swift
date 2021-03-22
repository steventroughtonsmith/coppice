//
//  CanvasesViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class CanvasesViewController: NSSplitViewController, NSMenuItemValidation {
    let viewModel: CanvasesViewModel
    init(viewModel: CanvasesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CanvasesView", bundle: nil)
        viewModel.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var canvasListViewController: CanvasListViewController = {
        let viewModel = CanvasListViewModel(documentWindowViewModel: self.viewModel.documentWindowViewModel)
        return CanvasListViewController(viewModel: viewModel)
    }()

    let noCanvasViewController = NoCanvasViewController()

    var enabled: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateSplitViewItems()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.viewModel.startObserving()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.viewModel.stopObserving()
    }


    private func updateSplitViewItems() {
        var splitViewItems = [NSSplitViewItem]()
        if self.viewModel.showCanvasList {
            splitViewItems.append(self.item(for: self.canvasListViewController))
        }

        if let canvasEditor = self.currentCanvasEditor {
            splitViewItems.append(self.item(for: canvasEditor))
        } else {
            splitViewItems.append(self.item(for: self.noCanvasViewController))
        }

        self.splitViewItems = splitViewItems
        self.inspectorsDidChange()
    }

    private func item(for viewController: SplitViewContainable & NSViewController) -> NSSplitViewItem {
        return self.splitViewItem(for: viewController) ?? viewController.createSplitViewItem()
    }

    var currentCanvasEditor: CanvasEditorViewController? {
        didSet {
            self.updateSplitViewItems()
        }
    }

    private func updateCanvasEditor() {
        guard let canvas = self.viewModel.currentCanvas else {
            self.currentCanvasEditor = nil
            return
        }
        guard self.currentCanvasEditor?.viewModel.canvas != canvas else {
            return
        }
        let viewModel = CanvasEditorViewModel(canvas: canvas, documentWindowViewModel: self.viewModel.documentWindowViewModel)
        self.currentCanvasEditor = CanvasEditorViewController(viewModel: viewModel)
        self.view.window?.recalculateKeyViewLoop()
    }


    var isSidebarCompact: Bool {
        get { UserDefaults.standard.bool(forKey: .canvasListIsCompact) }
        set {
            UserDefaults.standard.set(newValue, forKey: .canvasListIsCompact)
            self.thumbnailsNeedUpdate()
        }
    }


    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        if self.canvasListViewController.responds(to: action) {
            return self.canvasListViewController
        }
        if let editor = self.currentCanvasEditor, editor.responds(to: action) {
            return editor
        }
        return super.supplementalTarget(forAction: action, sender: sender)
    }

    //MARK: - SplitViewDelegate
    override func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        //If we're getting smaller than the minimum regular size we want to see if we want to switch to compact
        if proposedPosition < CanvasListViewController.regularMinimumSize {
            //We switch to compact if we're over half way towards compact sized
            let crossOverPoint = (CanvasListViewController.regularMinimumSize + CanvasListViewController.compactSize) / 2
            self.isSidebarCompact = (proposedPosition < crossOverPoint)
            return self.splitViewItem(for: self.canvasListViewController)?.minimumThickness ?? CanvasListViewController.regularMinimumSize
        }
        return proposedPosition
    }

    override func splitViewDidResizeSubviews(_ notification: Notification) {
        super.splitViewDidResizeSubviews(notification)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.thumbnailsNeedUpdate), object: nil)
        self.perform(#selector(self.thumbnailsNeedUpdate), with: nil, afterDelay: 0)
    }

    @objc dynamic func thumbnailsNeedUpdate() {
        self.viewModel.documentWindowViewModel.thumbnailController.currentThumbnailSize = self.canvasListViewController.currentThumbnailSize
    }

    @IBAction func toggleCanvasList(_ sender: Any?) {
        self.isSidebarCompact.toggle()
    }


    //MARK: - Exporting

    @IBAction func exportCanvasAsImage(_ sender: Any?) {
        guard
            let window = self.view.window,
            let canvas = self.viewModel.currentCanvas
        else {
            return
        }
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "\(canvas.title).jpeg"

        savePanel.beginSheetModal(for: window) { (modalResponse) in
            if modalResponse == .OK, let url = savePanel.url {
                self.generateImage(for: canvas) { image in
                    do {
                        try image.jpegData()?.write(to: url)
                    } catch let e {
                        self.windowController?.presentError(e)
                    }
                }
            }
            window.endSheet(savePanel)
            savePanel.orderOut(nil)
        }
    }

    private func generateImage(for canvas: Canvas, completion: @escaping (NSImage) -> Void) {
        let imageGenerator = CanvasImageGenerator(canvas: canvas, contentBorder: 200)
        if let image = imageGenerator.generateImage() {
            completion(image)
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(self.exportCanvasAsImage(_:)) {
            return self.viewModel.currentCanvas != nil
        }
        return false
    }
}


extension CanvasesViewController: CanvasesView {
    func currentCanvasChanged() {
        self.updateCanvasEditor()
    }

    func canvasListStateChanged() {
        self.updateSplitViewItems()
    }
}


extension CanvasesViewController: Editor {
    var inspectors: [Inspector] {
        return self.currentCanvasEditor?.inspectors ?? []
    }
}

