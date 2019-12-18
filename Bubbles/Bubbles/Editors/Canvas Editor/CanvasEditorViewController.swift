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
        self.identifier = NSUserInterfaceItemIdentifier(rawValue: "CanavsEditor")
        self.viewModel.view = self
        self.viewModel.layoutEngine.view = self
        self.originOffsetFromScrollPoint = self.viewModel.viewPortInCanvasSpace?.origin
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func encodeRestorableState(with coder: NSCoder) {
        if let offset = self.originOffsetFromScrollPoint {
            coder.encode(NSStringFromPoint(offset), forKey: "originOffsetFromScrollPoint")
        }
        super.encodeRestorableState(with: coder)
    }

    override func restoreState(with coder: NSCoder) {
        super.restoreState(with: coder)
        if let pointString = coder.decodeObject(forKey: "originOffsetFromScrollPoint") as? String {
            self.originOffsetFromScrollPoint = NSPointFromString(pointString)
        }

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

    var enabled: Bool = true

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
            self.invalidateRestorableState()
            self.scrollView.invalidateRestorableState()
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
        guard self.performedInitialLayout else {
            return
        }

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
        self.updateArrows()
        self.sortViews()
        self.updateCanvasViewPort()
        self.updateInspectorsIfNeeded()
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

    private func updateArrows() {
        var existingViews = self.arrowViews
        var newArrows = [LayoutEngineArrow]()
        for arrow in self.layoutEngine.arrows {
            let arrowView = self.arrowView(for: arrow)
            arrowView.arrow = arrow
            arrowView.frame = arrow.frame

            newArrows.append(arrow)
            if let index = existingViews.firstIndex(of: arrowView) {
                existingViews.remove(at: index)
            }
        }

        existingViews.forEach { $0.removeFromSuperview() }
    }

    private func sortViews() {
        let newPageUUIDs = self.layoutEngine.pages.map { $0.id }
        var pageViewsToOrder = [NSView?](repeating: nil, count: newPageUUIDs.count)
        for vc in self.pageViewControllers {
            guard let index = newPageUUIDs.firstIndex(of: vc.uuid) else {
                continue
            }
            pageViewsToOrder.insert(vc.view, at: index)
        }
        let pageViews = pageViewsToOrder.compactMap { $0 }
        self.canvasView.pageLayer.subviews = pageViews
    }


    //MARK: - Page Selections
    var selectedPages: [CanvasPageViewController] {
        return self.pageViewControllers.filter { $0.selected }
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

        let viewModel = CanvasPageViewModel(canvasPage: canvasPage,
                                            documentWindowViewModel: self.viewModel.documentWindowViewModel)
        let viewController = CanvasPageViewController(viewModel: viewModel)
        viewController.delegate = self

        self.addChild(viewController)
        self.canvasView.addPageView(viewController.typedView)
        return viewController
    }

    private func removePageViewController(with uuid: UUID) {
        guard let viewController = self.pageViewControllers.first(where: { $0.uuid == uuid }) else {
            return
        }
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }


    //MARK: - Arrow View Management
    private var arrowViews: [PageArrowView] {
        return self.canvasView.arrowLayer.subviews.compactMap { $0 as? PageArrowView }
    }

    private func arrowView(for arrow: LayoutEngineArrow) -> PageArrowView {
        if let arrowView = self.arrowViews.first(where: { $0.arrow?.childID == arrow.childID && $0.arrow?.parentID == arrow.parentID }) {
            return arrowView
        }

        let newArrowView = PageArrowView(lineWidth: self.layoutEngine.configuration.arrowWidth)
        self.canvasView.arrowLayer.addSubview(newArrowView)
        return newArrowView
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


    //MARK: - Inspectors
    private func updateInspectorsIfNeeded() {
        guard self.currentLayoutContext?.selectionChanged == true else {
            return
        }
        self.inspectorsDidChange()
    }

    private lazy var canvasInspector: CanvasInspectorViewController = {
        return CanvasInspectorViewController(viewModel: self.viewModel.canvasInspectorViewModel)
    }()
}


extension CanvasEditorViewController: Editor {
    var inspectors: [Inspector] {
        guard self.selectedPages.count == 1 else {
            return [self.canvasInspector]
        }
        return self.selectedPages[0].inspectors + [self.canvasInspector]
    }
}


extension CanvasEditorViewController: CanvasViewDelegate {
    func didDropPage(with id: ModelID, at point: CGPoint, on canvasView: CanvasView) {
        self.viewModel.addPage(at: PageLink(destination: id), centredOn: point)
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
        self.layout()
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
