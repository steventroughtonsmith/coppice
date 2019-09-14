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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(scrollingChanged(_:)),
                                               name: NSView.boundsDidChangeNotification,
                                               object: self.scrollView.contentView)
        self.layout()
    }

    @IBAction func addTestPage(_ sender: Any?) {
        self.viewModel.createTestPage()
    }

    private var lastScrollPoint: CGPoint?
    @objc func scrollingChanged(_ sender: Any?) {
        let scrollPoint = self.scrollView.contentView.bounds.origin
        self.lastScrollPoint = self.viewModel.layoutEngine.convertPointToPageSpace(scrollPoint)
    }

    
    //MARK: - Layout
    @objc func layout() {
        self.updateCanvas()
        self.updateSelectionRect()
        self.updatePages()
    }

    private func updateCanvas() {
        self.canvasView.frame.size = self.viewModel.layoutEngine.canvasSize
        if let lastScrollPoint = self.lastScrollPoint, self.viewModel.layoutEngine.pages.count > 0 {
            let canvasPoint = self.viewModel.layoutEngine.convertPointToCanvasSpace(lastScrollPoint)
            self.scrollView.contentView.scroll(to: canvasPoint)
        }
        else {
            let x = (self.canvasView.frame.width - self.scrollView.frame.width) / 2
            let y = (self.canvasView.frame.height - self.scrollView.frame.height) / 2
            self.scrollView.contentView.scroll(to: CGPoint(x: x, y: y))
        }

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
        viewController.selected = layoutPage.selected
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
        viewController.delegate = self
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


    //MARK: - Zooming
    @IBAction func zoomIn(_ sender: Any) {
        self.scrollView.magnification *= 2
    }

    @IBAction func zoomOut(_ sender: Any) {
        self.scrollView.magnification /= 2
    }

    @IBAction func zoomTo100(_ sender: Any) {
        self.scrollView.magnification = 1
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

extension CanvasEditorViewController: CanvasPageViewControllerDelegate {
    func close(_ page: CanvasPageViewController) {
        self.viewModel.close(page.viewModel.canvasPage)
    }
}
