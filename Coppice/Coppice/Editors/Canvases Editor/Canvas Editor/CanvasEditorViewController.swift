//
//  CanvasEditorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore

class CanvasEditorViewController: NSViewController, NSMenuItemValidation, NSToolbarItemValidation, SplitViewContainable {

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var canvasView: CanvasView!
    @IBOutlet weak var toggleCanvasListButton: NSButton!
    @IBOutlet weak var bottomBarConstraint: NSLayoutConstraint!
    @objc dynamic let viewModel: CanvasEditorViewModel
    init(viewModel: CanvasEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CanvasEditorViewController", bundle: nil)
        self.identifier = NSUserInterfaceItemIdentifier(rawValue: "CanavsEditor")
        self.viewModel.view = self
        self.viewModel.layoutEngine.view = self
        self.originOffsetFromScrollPoint = self.viewModel.viewPortInCanvasSpace?.origin

        self.setupObservers()
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
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


    //MARK: - Observation

    var defaultsObserver: NSObjectProtocol?

    private func setupObservers() {
        self.defaultsObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.updatePageSpaceOrigin()
        }
    }

    var firstResponderObserver: AnyCancellable?
    var windowBecomeKeyObserver: NSObjectProtocol?
    var windowResignKeyObserver: NSObjectProtocol?
    private func setupActiveStateObservers() {
        self.firstResponderObserver = self.view.window?.publisher(for: \.firstResponder).sink(receiveValue: { [weak self] (responder) in
            self?.updateActivateState(with: responder)
            self?.updateSelection(with: responder)
        })

        self.windowBecomeKeyObserver = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: self.view.window, queue: .main, using: { [weak self ](_) in
            self?.updateActivateState(with: self?.view.window?.firstResponder)
        })
        self.windowResignKeyObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: self.view.window, queue: .main, using: { [weak self ](_) in
            self?.updateActivateState(with: self?.view.window?.firstResponder)
        })
    }

    private func cleanUpActiveStateObservers() {
        if let observer = self.windowBecomeKeyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = self.windowResignKeyObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        self.firstResponderObserver?.cancel()
        self.firstResponderObserver = nil
    }



    //MARK: - View Setup

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

        self.setupZoomObservation()
        self.updateZoomControl()

        self.bottomBarConstraint.constant = GlobalConstants.bottomBarHeight

        self.toggleCanvasListButton.image = NSImage.symbol(withName: Symbols.Toolbars.canvasListToggle)

        self.setupAccessibility()
        self.setupPro()
    }

    var enabled: Bool = true

    private func setupCanvasView() {
        self.canvasView.layoutEngine = self.layoutEngine

        self.canvasView.wantsLayer = true
        self.canvasView.layer?.masksToBounds = false

        self.canvasView.delegate = self
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.perform(#selector(forceFullLayout), with: nil, afterDelay: 4)
        self.setupActiveStateObservers()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()

        self.cleanUpActiveStateObservers()
    }

    private var performedInitialLayout = false
    override func viewDidLayout() {
        super.viewDidLayout()
        guard self.performedInitialLayout else {
            self.updateLayoutIfNeeded()
            return
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateLayoutIfNeeded), object: nil)
        self.perform(#selector(updateLayoutIfNeeded), with: nil, afterDelay: 0)
    }

    @objc private func updateLayoutIfNeeded() {
        self.notifyOfViewPortChangeIfNeeded()
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


    //MARK: - Activate state
    private(set) var active: Bool = false {
        didSet {
            self.pageViewControllers.forEach { $0.active = self.active }
        }
    }

    func updateActivateState(with firstResponder: NSResponder?) {
        guard let view = firstResponder as? NSView,
            let window = view.window else {
            self.active = false
            return
        }

        self.active = view.isDescendant(of: self.view) && window.isKeyWindow
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
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(notifyOfViewPortChangeIfNeeded), object: nil)
        if !self.isLayingOut {
            self.updateLastOriginOffset()
        }
        self.perform(#selector(notifyOfViewPortChangeIfNeeded), with: nil, afterDelay: 0.5)
    }

    @objc func notifyOfViewPortChangeIfNeeded() {
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
        //Prevent laying out until we know our size
        guard self.view.superview != nil else {
            return
        }
        self.isLayingOut = true
        self.updateEditability()
        self.updateAppearance()
        self.updateCanvas()
        self.updateSelectionRect()
        self.updatePages()
        self.updateArrows()
        self.updateEmptyState()
        self.sortViews()
        self.updateCanvasViewPort()
        self.updateInspectorsIfNeeded()
        self.isLayingOut = false
        self.hasLaidOut = true
        self.currentLayoutContext = nil
    }

    private func updateEditability() {
        if self.layoutEngine.editable {
            self.canvasView.registerForDraggedTypes([ModelID.PasteboardType, .fileURL])
        } else {
            self.canvasView.unregisterDraggedTypes()
        }
    }

    private func updateAppearance() {
        let appearance: NSAppearance?
        switch self.viewModel.theme {
        case .dark:
            appearance = NSAppearance(named: .darkAqua)
        case .light:
            appearance = NSAppearance(named: .aqua)
        default:
            appearance = nil
        }
        self.view.appearance = appearance
        self.canvasView.theme = self.viewModel.theme
        self.scrollView.backgroundColor = self.viewModel.theme.canvasBackgroundColor
    }

    private func updateCanvas() {
        guard (self.currentLayoutContext?.sizeChanged == true) || (self.currentLayoutContext?.pageOffsetChange != nil) else {
            return
        }

        let canvasSize = self.layoutEngine.canvasSize
        if (self.currentLayoutContext?.sizeChanged == true) {
            self.scrollView.magnification = 1
            self.canvasView.frame.size = canvasSize
            self.scrollView.magnification = self.viewModel.zoomFactor
        }

        if let lastPoint = self.originOffsetFromScrollPoint {
            self.scroll(toOriginOffset: lastPoint)
        } else {
            let scrollPoint = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2).rounded()
            self.scrollView.contentView.centre(on: scrollPoint)

            self.updateLastOriginOffset()
        }

        self.updatePageSpaceOrigin()
    }

    private func updatePageSpaceOrigin() {
        if (UserDefaults.standard.bool(forKey: UserDefaultsKeys.debugShowCanvasOrigin.rawValue)) {
            self.canvasView.pageSpaceOrigin = self.layoutEngine.convertPointToCanvasSpace(.zero)
        } else {
            self.canvasView.pageSpaceOrigin = nil
        }
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
            arrowView.frame = arrow.layoutFrame

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

    @IBAction override func selectAll(_ sender: Any?) {
        self.layoutEngine.selectAll()
    }

    @IBAction func deselectAll(_ sender: Any?) {
        self.layoutEngine.deselectAll()
    }

    private func updateSelection(with firstResponder: NSResponder?) {
        guard
            let view = firstResponder as? NSView,
            let canvasPageVC = self.pageViewController(containing: view) else {
                return
        }

        self.viewModel.select(canvasPageVC.viewModel.canvasPage)
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

        page.view = viewModel.pageEditor

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

    private func pageViewController(for canvasPage: CanvasPage) -> CanvasPageViewController? {
        return self.pageViewControllers.first { $0.viewModel.canvasPage.id == canvasPage.id }
    }

    private func pageViewController(containing view: NSView) -> CanvasPageViewController? {
        return self.pageViewControllers.first { view.isDescendant(of: $0.view) }
    }


    //MARK: - Empty State
    @IBOutlet var emptyStateView: NSView!
    private func updateEmptyState() {
        let isEmpty = (self.pageViewControllers.count == 0)
        if isEmpty {
            self.view.addSubview(self.emptyStateView)
            NSLayoutConstraint.activate([
                self.emptyStateView.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor),
                self.emptyStateView.centerYAnchor.constraint(equalTo: self.scrollView.centerYAnchor),
            ])
            self.scrollView.hasHorizontalScroller = false
            self.scrollView.hasVerticalScroller = false
        } else {
            self.emptyStateView.removeFromSuperview()
            self.scrollView.hasHorizontalScroller = true
            self.scrollView.hasVerticalScroller = true
        }
    }


    //MARK: - Arrow View Management
    private var arrowViews: [PageArrowView] {
        return self.canvasView.arrowLayer.subviews.compactMap { $0 as? PageArrowView }
    }

    private func arrowView(for arrow: LayoutEngineArrow) -> PageArrowView {
        if let arrowView = self.arrowViews.first(where: { $0.arrow?.betweenSamePages(as: arrow) ?? false }) {
            return arrowView
        }

        let newArrowView = PageArrowView(config: self.layoutEngine.configuration.arrow)
        newArrowView.lineColour = self.viewModel.canvas.theme.arrowColour
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

    private var zoomObservation: AnyCancellable!
    private func setupZoomObservation() {
        self.zoomObservation = NotificationCenter.default.publisher(for: NSScrollView.didEndLiveMagnifyNotification, object: self.scrollView)
            .sink { [weak self] (notification) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.viewModel.zoomFactor = strongSelf.scrollView.magnification
            }
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


    //MARK: - Menu Items
    @IBAction func addPageToCanvas(_ sender: Any?) {
        guard let windowController = self.windowController as? DocumentWindowController else {
            return
        }

        windowController.showPageSelector(title: NSLocalizedString("Add page to canvas…", comment: "Add page selector title")) { [weak self] (page) in
            self?.viewModel.addPages(with: [page.id])
        }
    }

    @IBAction func removeSelectedPages(_ sender: Any?) {
        self.viewModel.selectedCanvasPages.forEach { self.viewModel.close($0) }
    }

    @IBAction func deleteItems(_ sender: Any?) {
        guard (self.viewModel.selectedCanvasPages.count == 1), let page = self.viewModel.selectedCanvasPages.first?.page else {
            return
        }

        self.viewModel.documentWindowViewModel.deleteItems([page])
    }

    @IBAction func linkToPage(_ sender: Any?) {
        if (!HelpTipPresenter.shared.showTip(with: .textPageLink, fromToolbarItemWithIdentifier: .linkToPage)) {
            HelpTipPresenter.shared.showTip(with: .textPageLink, fromView: self.view, preferredEdge: .maxX)
        }
    }

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        if item.action == #selector(linkToPage(_:)) {
            if self.selectedPages.count == 1 {
                item.toolTip = nil;
                return true
            }
            item.toolTip = NSLocalizedString("Start editing a Page to create a link", comment: "Canvas Link to Page disabled tooltip")
            return false
        }
        return true
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(zoomControlChanged(_:)) {
            return true
        }
        let notEditableTooltip = NSLocalizedString("The current Canvas is not editable", comment: "Non-editable canvas action tooltip")
        if menuItem.action == #selector(addPageToCanvas(_:)) {
            menuItem.toolTip = (self.layoutEngine.editable ? nil : notEditableTooltip)
            return self.layoutEngine.editable
        }
        if menuItem.action == #selector(removeSelectedPages(_:)) {
            menuItem.toolTip = (self.layoutEngine.editable ? nil : notEditableTooltip)
            guard self.layoutEngine.editable else {
                return false
            }
            let selectedPagesCount = self.viewModel.selectedCanvasPages.count
            if selectedPagesCount == 1 {
                menuItem.title = NSLocalizedString("Close Selected Page", comment: "Close selected page singular menu item")
            } else {
                menuItem.title = NSLocalizedString("Close Selected Pages", comment: "Close selected pages plural menu item")
            }
            return (selectedPagesCount > 0)
        }
        if menuItem.action == #selector(deleteItems(_:)) {
            menuItem.toolTip = (self.layoutEngine.editable ? nil : notEditableTooltip)
            return (self.viewModel.selectedCanvasPages.count == 1) && self.layoutEngine.editable
        }
        if menuItem.action == #selector(zoomIn(_:)) {
            return self.viewModel.canZoomIn
        }
        if menuItem.action == #selector(zoomOut(_:)) {
            return self.viewModel.canZoomOut
        }
        if menuItem.action == #selector(zoomTo100(_:)) {
            return self.viewModel.canZoomTo100
        }
        if menuItem.action == #selector(selectAll(_:)) ||
            menuItem.action == #selector(deselectAll(_:)) {
            return true
        }
        if menuItem.action == #selector(linkToPage(_:)) {
            if self.selectedPages.count == 1 {
                menuItem.toolTip = nil;
                return true
            }
            menuItem.toolTip = NSLocalizedString("Start editing a Page to create a link", comment: "Canvas Link to Page disabled tooltip")
            return false
        }
        #if DEBUG
        if menuItem.action == #selector(saveCanvasImageToDisk(_:)) {
            return true
        }
        #endif
        return false
    }

    #if DEBUG
    @IBAction func saveCanvasImageToDisk(_ sender: Any?) {
        guard let window = self.view.window else {
            return
        }
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "\(self.viewModel.canvas.title).jpeg"
        let view = self.canvasView

        savePanel.beginSheetModal(for: window) { (modalResponse) in
            if modalResponse == .OK, let url = savePanel.url {
                try? view?.generateImage()?.jpegData()?.write(to: url)
            }
            window.endSheet(savePanel)
            savePanel.orderOut(nil)
        }
    }
    #endif


    //MARK: - SplitViewContainable
    func createSplitViewItem() -> NSSplitViewItem {
        let splitViewItem = NSSplitViewItem(viewController: self)
        splitViewItem.holdingPriority = NSLayoutConstraint.Priority(rawValue: 249)
        return splitViewItem
    }


    //MARK: - Accessibility
    private func setupAccessibility() {
        guard
            let scrollView = self.scrollView,
            let toggleButton = self.toggleCanvasListButton,
            let zoomControl = self.zoomControl else {
                return
        }

        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(NSLocalizedString("Canvas Editor", comment: "Canvas List accessibility label"))
        self.view.setAccessibilityChildren([scrollView, toggleButton, zoomControl])
    }


    //MARK: - Pro
    @IBOutlet weak var proImageView: NSImageView!
    @IBAction func proUpSell(_ sender: Any) {
    }

    private func setupPro() {
        self.proImageView.image = CoppiceSubscriptionManager.shared.proImage
    }

}


extension CanvasEditorViewController: Editor {
    var inspectors: [Inspector] {
        guard self.layoutEngine.editable, self.selectedPages.count == 1 else {
            return [self.canvasInspector]
        }
        return self.selectedPages[0].inspectors + [self.canvasInspector]
    }

    func open(_ link: PageLink) {
        self.viewModel.addPage(at: link)
    }
}


extension CanvasEditorViewController: CanvasViewDelegate {
    func willStartEditing(_ canvasView: CanvasView) {
        self.viewModel.documentWindowViewModel.registerStartOfEditing()
    }
    
    func didDropPages(with ids: [ModelID], at point: CGPoint, on canvasView: CanvasView) {
        let pageSpacePoint = self.layoutEngine.convertPointToPageSpace(point)
        self.viewModel.addPages(with: ids, centredOn: pageSpacePoint)
    }

    func didDropFiles(withURLs urls: [URL], at point: CGPoint, on canvasView: CanvasView) {
        self.viewModel.addPages(forFilesAtURLs: urls, centredOn: point)
    }

    func dragImageForPage(with id: ModelID, in canvasView: CanvasView) -> NSImage? {
        return self.viewModel.dragImageForPage(with: id)
    }
}


extension CanvasEditorViewController: CanvasEditorView {
    func updateZoomFactor() {
        self.zoom(to: self.viewModel.zoomFactor)
        self.updateZoomControl()
    }

    func flash(_ canvasPage: CanvasPage) {
        self.pageViewController(for: canvasPage)?.flash()
    }

    func notifyAccessibilityOfMove(_ canvasPages: [CanvasPage]) {
        guard let canvasView = self.canvasView else {
            return
        }
        let views = canvasPages.compactMap { self.pageViewController(for: $0)?.view }

        NSAccessibility.post(element: canvasView, notification: .layoutChanged, userInfo: [NSAccessibility.NotificationUserInfoKey.uiElements: views])
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
        guard self.layoutEngine.editable else {
            return
        }
        self.viewModel.close(page.viewModel.canvasPage)
    }

    func toggleSelection(of page: CanvasPageViewController) {
        if page.selected {
            self.viewModel.deselect(page.viewModel.canvasPage)
        } else {
            self.viewModel.select(page.viewModel.canvasPage, extendingSelection: true)
        }
    }
}
