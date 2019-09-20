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
        self.layout()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(scrollingChanged(_:)),
                                               name: NSView.boundsDidChangeNotification,
                                               object: self.scrollView.contentView)
    }

    @IBAction func addTestPage(_ sender: Any?) {
        self.viewModel.createTestPage()
    }

    private var lastScrollPoint: CGPoint?
    @objc func scrollingChanged(_ sender: Any?) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scrollingEnded), object: nil)
        let scrollPoint = self.scrollView.contentView.visualCentre
        self.lastScrollPoint = self.viewModel.layoutEngine.convertPointToPageSpace(scrollPoint)
        self.perform(#selector(scrollingEnded), with: nil, afterDelay: 0.5)

    }

    @objc func scrollingEnded() {
        guard self.hasLaidOut == false else {
            self.hasLaidOut = false
            return
        }
        self.viewModel.layoutEngine.viewPortChanged()
    }

    
    //MARK: - Layout
    private var hasLaidOut = false
    @objc func layout() {
        self.updateCanvas()
        self.updateSelectionRect()
        self.updatePages()
        self.sortViews()
        self.hasLaidOut = true
    }

    private func updateCanvas() {
        guard self.canvasView.frame.size != self.viewModel.layoutEngine.canvasSize else {
            return
        }
        var singlePageOffset: CGPoint? = nil
        if self.pageViewControllers.count == 1 && self.viewModel.layoutEngine.pages.count == 1 {
            singlePageOffset = self.pageViewControllers.first?.view.frame.origin.minus(self.scrollView.contentView.bounds.origin)
        }


        let magnification = self.scrollView.magnification
        self.scrollView.magnification = 1
        let canvasSize = self.viewModel.layoutEngine.canvasSize
        self.canvasView.frame.size = canvasSize
        self.scrollView.magnification = magnification

        var scrollPoint = CGPoint(x: canvasSize.width / 2,
                                  y: canvasSize.height / 2)

        if let offset = singlePageOffset,
           let scrollOffset = self.pageViewControllers.first?.view.frame.origin.minus(offset) {
            self.scrollView.contentView.scroll(to: scrollOffset)
            return
        }

        if let lastPoint = self.lastScrollPoint, self.viewModel.layoutEngine.pages.count > 0 {
            let canvasPoint = self.viewModel.layoutEngine.convertPointToCanvasSpace(lastPoint)
            if ((canvasSize.width * self.scrollView.magnification) > self.scrollView.frame.width) {
                scrollPoint.x = canvasPoint.x
            }
            if ((canvasSize.height * self.scrollView.magnification) > self.scrollView.frame.height) {
                scrollPoint.y = canvasPoint.y
            }
        }

        self.scrollView.contentView.centre(on: scrollPoint)
        self.lastScrollPoint = self.viewModel.layoutEngine.convertPointToPageSpace(scrollPoint)
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

    private func sortViews() {
        var currentSubviews = self.canvasView.subviews
        let newPageUUIDs = self.viewModel.layoutEngine.pages.map { $0.id }
        var pageViewsToOrder = [NSView?](repeating: nil, count: newPageUUIDs.count)
        for vc in self.pageViewControllers {
            guard let index = newPageUUIDs.firstIndex(of: vc.uuid) else {
                continue
            }
            if let subviewIndex = currentSubviews.firstIndex(of: vc.view) {
                currentSubviews.remove(at: subviewIndex)
            }
            pageViewsToOrder.insert(vc.view, at: index)
        }
        let pageViews = pageViewsToOrder.compactMap { $0 }
        self.canvasView.subviews = pageViews + currentSubviews
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
        self.magnify(by: 2)
    }

    @IBAction func zoomOut(_ sender: Any) {
        self.magnify(by: 0.5)
    }

    @IBAction func zoomTo100(_ sender: Any) {
        self.magnify(by: 1 / self.scrollView.magnification)
    }

    private func magnify(by factor: CGFloat) {
        let centrePoint = self.scrollView.contentView.visualCentre
        self.scrollView.magnification *= factor
        self.scrollView.contentView.centre(on: centrePoint)
        self.viewModel.layoutEngine.viewPortChanged()
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
