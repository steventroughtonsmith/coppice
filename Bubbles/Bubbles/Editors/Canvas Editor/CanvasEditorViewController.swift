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
    @IBOutlet weak var canvasView: CanvasView!
    @objc dynamic let viewModel: CanvasEditorViewModel
    init(viewModel: CanvasEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CanvasEditorViewController", bundle: nil)
        self.viewModel.view = self
        self.viewModel.layoutEngine.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.canvasView.layoutEngine = self.viewModel.layoutEngine
    }

    @IBAction func addTestPage(_ sender: Any?) {
        self.viewModel.createTestPage()
    }

    
    //MARK: - Layout
    @objc func layout() {
        self.updateSelectionRect()
        self.updatePages()
    }

    private func updateSelectionRect() {
        self.canvasView.selectionRect = self.viewModel.layoutEngine.selectionRect
    }

    private func updatePages() {
        var idsToRemove = self.pageViewControllers.map { $0.uuid }
        for page in self.viewModel.layoutEngine.pages {
            guard let viewController = self.pageViewController(for: page) else {
                continue
            }

            if let idIndex = idsToRemove.firstIndex(of: page.id) {
                idsToRemove.remove(at: idIndex)
            }
            self.apply(page, to: viewController)
        }

        for id in idsToRemove {
            self.removePageViewController(with: id)
        }
    }

    private func apply(_ layoutPage: LayoutEnginePage, to viewController: CanvasPageViewController) {
        viewController.view.frame = layoutPage.canvasFrame
    }


    //MARK: - Page View Controller Management
    private var pageViewControllers: [CanvasPageViewController] {
        return self.children.compactMap({ $0 as? CanvasPageViewController })
    }

    private func pageViewController(for page: LayoutEnginePage) -> CanvasPageViewController? {
        guard let canvasPage = self.viewModel.canvasPage(with: page.id) else {
            return nil
        }

        if let pageViewController = self.pageViewControllers.first(where: { $0.uuid == page.id }) {
            return pageViewController
        }

        let viewModel = CanvasPageViewModel(canvasPage: canvasPage)
        let viewController = CanvasPageViewController(viewModel: viewModel)
        page.componentProvider = viewController

        self.addChild(viewController)
        self.canvasView.addSubview(viewController.view)
        return viewController
    }

    private func removePageViewController(with uuid: UUID) {
        guard let viewController = self.pageViewControllers.first(where: { $0.uuid == uuid }) else {
            return
        }
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }

}

extension CanvasEditorViewController: CanvasEditorView {}

extension CanvasEditorViewController: CanvasLayoutView {
    func layoutChanged() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(layout), object: nil)
        self.perform(#selector(layout), with: nil, afterDelay: 0)
    }

    var viewPortFrame: CGRect {
        return self.scrollView.contentView.bounds
    }
}
