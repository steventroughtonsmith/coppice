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
        self.originOffsetFromScrollPoint = self.viewModel.viewPortInCanvasSpace?.origin
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var layoutEngine: CanvasLayoutEngine {
        return self.viewModel.layoutEngine
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCanvasView()

        self.forceFullLayout()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(scrollingChanged(_:)),
                                               name: NSView.boundsDidChangeNotification,
                                               object: self.scrollView.contentView)
        self.updateZoomControl()
    }

    private func setupCanvasView() {
        self.canvasView.layoutEngine = self.layoutEngine

        self.canvasView.wantsLayer = true
        self.canvasView.layer?.masksToBounds = false

        self.canvasView.delegate = self
        self.canvasView.registerForDraggedTypes([ModelID.PasteboardType])
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.perform(#selector(forceFullLayout), with: nil, afterDelay: 4)
    }

    private var performedInitialLayout = false
    override func viewDidLayout() {
        super.viewDidLayout()
        guard self.performedInitialLayout == false else {
            return
        }
        if (self.viewModel.canvasPages.count == 0) {
            let canvasSize = self.layoutEngine.canvasSize
            let scrollPoint = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2).rounded()
            self.scrollView.contentView.centre(on: scrollPoint)
        }
        self.performedInitialLayout = true
    }

    @IBAction func addTestPage(_ sender: Any?) {
        self.viewModel.createTestPage()
    }


    //MARK: - Scrolling
    private var originOffsetFromScrollPoint: CGPoint? {
        didSet {
            self.updateCanvasViewPort()
        }
    }

    @objc func scrollingChanged(_ sender: Any?) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scrollingEnded), object: nil)
        if !self.isLayingOut {
            self.updateLastOriginOffset()
        }
        self.perform(#selector(scrollingEnded), with: nil, afterDelay: 0.5)
    }

    @objc func scrollingEnded() {
        guard self.hasLaidOut == false else {
            self.hasLaidOut = false
            return
        }
        self.layoutEngine.viewPortChanged()
    }

    private func updateLastOriginOffset() {
        let originInCanvas = self.layoutEngine.convertPointToCanvasSpace(.zero)
        self.originOffsetFromScrollPoint = originInCanvas.minus(self.scrollView.contentView.bounds.origin)
    }

    private func scroll(toOriginOffset originOffset: CGPoint) {
        let originInCanvas = self.layoutEngine.convertPointToCanvasSpace(.zero)
        let scrollPoint = originInCanvas.minus(originOffset)
        self.scrollView.contentView.bounds.origin = scrollPoint
    }

    private func updateCanvasViewPort() {
        guard let origin = self.originOffsetFromScrollPoint else {
            self.viewModel.viewPortInCanvasSpace = nil
            return
        }
        self.viewModel.viewPortInCanvasSpace = CGRect(origin: origin, size: self.scrollView.frame.size)
    }

    
    //MARK: - Layout
    private var hasLaidOut = false
    private var isLayingOut = false
    private var currentLayoutContext: CanvasLayoutEngine.LayoutContext?
    @objc private func forceFullLayout() {
        self.currentLayoutContext = CanvasLayoutEngine.LayoutContext(sizeChanged: true, pageOffsetChange: .zero)
        self.layout()
    }

    @objc func layout() {
        self.isLayingOut = true
        self.updateCanvas()
        self.updateSelectionRect()
        self.updatePages()
        self.sortViews()
        self.updateCanvasViewPort()
        self.isLayingOut = false
        self.hasLaidOut = true
        self.currentLayoutContext = nil
    }

    private func updateCanvas() {
        guard (self.currentLayoutContext?.sizeChanged == true) || (self.currentLayoutContext?.pageOffsetChange != nil) else {
            return
        }

        let canvasSize = self.layoutEngine.canvasSize
        if (self.currentLayoutContext?.sizeChanged == true) {
            let magnification = self.scrollView.magnification
            self.scrollView.magnification = 1
            self.canvasView.frame.size = canvasSize
            self.scrollView.magnification = magnification
        }

        if let lastPoint = self.originOffsetFromScrollPoint {
            self.scroll(toOriginOffset: lastPoint)
        } else {
            let scrollPoint = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2).rounded()
            self.scrollView.contentView.centre(on: scrollPoint)

            self.updateLastOriginOffset()
        }

        self.canvasView.pageSpaceOrigin = self.layoutEngine.convertPointToCanvasSpace(.zero)
    }

    private func updateSelectionRect() {
        self.canvasView.selectionRect = self.layoutEngine.selectionRect
    }

    private func updatePages() {
        var idsToRemove = self.pageViewControllers.map { $0.uuid }
        for page in self.layoutEngine.pages {
            guard let viewController = self.pageViewController(for: page) else {
                continue
            }

            if let idIndex = idsToRemove.firstIndex(of: page.id) {
                idsToRemove.remove(at: idIndex)
            }
            viewController.apply(page)
        }

        for id in idsToRemove {
            self.removePageViewController(with: id)
        }
    }

    private func sortViews() {
        var currentSubviews = self.canvasView.subviews
        let newPageUUIDs = self.layoutEngine.pages.map { $0.id }
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

        let viewModel = CanvasPageViewModel(canvasPage: canvasPage, modelController: self.viewModel.modelController)
        let viewController = CanvasPageViewController(viewModel: viewModel)
        viewController.delegate = self

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
    @IBOutlet weak var zoomControl: NSPopUpButton!

    @IBAction func zoomIn(_ sender: Any) {
        self.viewModel.zoomIn()
    }

    @IBAction func zoomOut(_ sender: Any) {
        self.viewModel.zoomOut()
    }

    @IBAction func zoomTo100(_ sender: Any) {
        self.viewModel.zoomTo100()
    }

    private func zoom(to zoomFactor: CGFloat) {
        let centrePoint = self.scrollView.contentView.visualCentre
        self.scrollView.magnification = zoomFactor
        self.scrollView.contentView.centre(on: centrePoint)
        self.layoutEngine.viewPortChanged()
    }

    private func updateZoomControl() {
        self.zoomControl.removeAllItems()
        for item in self.viewModel.zoomLevels {
            self.zoomControl.addItem(withTitle: "\(item)%")
        }
        self.zoomControl.selectItem(at: self.viewModel.selectedZoomLevel)
    }

    @IBAction func zoomControlChanged(_ sender: Any?) {
        self.viewModel.selectedZoomLevel = self.zoomControl.indexOfSelectedItem
    }
}

extension CanvasEditorViewController: CanvasViewDelegate {
    func didDrop(pageWithID: ModelID, at point: CGPoint, on canvasView: CanvasView) {
        self.viewModel.addPage(with: pageWithID, centredOn: point)
    }
}

extension CanvasEditorViewController: CanvasEditorView {
    func updateZoomFactor() {
        self.zoom(to: self.viewModel.zoomFactor)
        self.updateZoomControl()
    }
}

extension CanvasEditorViewController: CanvasLayoutView {
    func layoutChanged(with context: CanvasLayoutEngine.LayoutContext) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(layout), object: nil)
        if let currentContext = self.currentLayoutContext {
            self.currentLayoutContext = currentContext.merged(with: context)
        } else {
            self.currentLayoutContext = context
        }
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
