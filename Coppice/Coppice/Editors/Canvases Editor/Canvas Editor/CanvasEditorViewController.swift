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
import M3Data

class CanvasEditorViewController: NSViewController, NSMenuItemValidation, SplitViewContainable {
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

    //MARK: - Subscribers
    private enum SubscriberKey {
        case pageContentDidChange
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

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

        self.windowBecomeKeyObserver = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: self.view.window, queue: .main, using: { [weak self] (_) in
            self?.updateActivateState(with: self?.view.window?.firstResponder)
        })
        self.windowResignKeyObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: self.view.window, queue: .main, using: { [weak self] (_) in
            self?.updateActivateState(with: self?.view.window?.firstResponder)
        })

        self.subscribers[.pageContentDidChange] = NotificationCenter.default.publisher(for: .pageContentLinkDidChange).sink { [weak self] notification in
            guard let self, let content = notification.object as? PageContent else {
                return
            }
            if content.page?.canvasPages.map(\.canvas).contains(self.viewModel.canvas) == true {
                DispatchQueue.main.async {
                    self.forceFullLayout()
                }
            }
        }
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
                                               selector: #selector(self.scrollingChanged(_:)),
                                               name: NSView.boundsDidChangeNotification,
                                               object: self.scrollView.contentView)

        self.setupZoomObservation()
        self.updateZoomControl()

        self.bottomBarConstraint.constant = GlobalConstants.bottomBarHeight

        self.toggleCanvasListButton.image = NSImage.symbol(withName: Symbols.Toolbars.canvasListToggle)

        self.setupAccessibility()
        self.setupPro()

        self.newPageMenuDelegate.action = #selector(self.newPageFromContextMenu(_:))
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
        self.perform(#selector(self.forceFullLayout), with: nil, afterDelay: 4)
        self.setupActiveStateObservers()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        //Make sure we clear the perform selector from above so we don't hold onto the UI
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.forceFullLayout), object: nil)

        self.cleanUpActiveStateObservers()
    }

    private var performedInitialLayout = false
    override func viewDidLayout() {
        super.viewDidLayout()
        guard self.performedInitialLayout else {
            self.updateLayoutIfNeeded()
            return
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.updateLayoutIfNeeded), object: nil)
        self.perform(#selector(self.updateLayoutIfNeeded), with: nil, afterDelay: 0)
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
            let window = view.window
        else {
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
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.notifyOfViewPortChangeIfNeeded), object: nil)
        if !self.isLayingOut {
            self.updateLastOriginOffset()
        }
        self.perform(#selector(self.notifyOfViewPortChangeIfNeeded), with: nil, afterDelay: 0.5)
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

	private func scrollToPageViewController(_ pageViewController: CanvasPageViewController) {
		self.scrollView.contentView.scrollToVisible(pageViewController.view.frame)
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
        var newArrows = [LayoutEngineLink]()
        for arrow in self.layoutEngine.links {
            let arrowView = self.arrowView(for: arrow)
            arrowView.arrow = arrow
            arrowView.canvasLink = self.viewModel.canvasLink(with: arrow.id)
            arrowView.canvasEditorViewController = self
            arrowView.sourcePage = self.viewModel.sourcePage(for: arrow)
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
            pageViewsToOrder[index] = vc.view
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
            let canvasPageVC = self.pageViewController(containing: view)
        else {
                return
        }

        self.viewModel.select(canvasPageVC.viewModel.canvasPage)
    }


    //MARK: - Page View Controller Management
    private var pageViewControllers: [CanvasPageViewController] {
        return self.children.compactMap { $0 as? CanvasPageViewController }
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

    func pageViewController(for canvasPage: CanvasPage) -> CanvasPageViewController? {
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

    private func arrowView(for arrow: LayoutEngineLink) -> PageArrowView {
        if let arrowView = self.arrowViews.first(where: { $0.arrow?.betweenSamePages(as: arrow) ?? false }) {
            return arrowView
        }

        let newArrowView = PageArrowView(config: self.layoutEngine.configuration.arrow)
        newArrowView.lineColour = self.viewModel.theme.arrowColour
        self.canvasView.arrowLayer.addSubview(newArrowView)
        return newArrowView
    }

    func arrowView(for canvasLink: CanvasLink) -> PageArrowView? {
        return self.arrowViews.first(where: { $0.canvasLink == canvasLink })
    }


    //MARK: - Zooming
    @IBOutlet weak var zoomControl: NSPopUpButton!
    @IBOutlet weak var zoomContextMenu: NSMenu!

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

    lazy var zoomMenuDelegate: ZoomMenuDelegate = {
        let zoomMenuDelegate = ZoomMenuDelegate()
        zoomMenuDelegate.zoomLevels = self.viewModel.zoomLevels
        return zoomMenuDelegate
    }()

    private func updateZoomControl() {
        self.zoomMenuDelegate.zoomLevels = self.viewModel.zoomLevels
        self.zoomContextMenu.delegate = self.zoomMenuDelegate

        self.zoomMenuDelegate.selectedLevel = self.viewModel.selectedZoomLevel

        guard let menu = self.zoomControl.menu else {
            return
        }
        self.zoomControl.removeAllItems()
        for index in 0..<self.zoomMenuDelegate.numberOfItems(in: menu) {
            let menuItem = NSMenuItem()
            if self.zoomMenuDelegate.menu(menu, update: menuItem, at: index, shouldCancel: false) {
                menu.addItem(menuItem)
            }
        }

        self.zoomControl.selectItem(at: self.viewModel.selectedZoomLevel)

        self.zoomControl.synchronizeTitleAndSelectedItem()
    }

    @IBAction func zoomControlChanged(_ sender: NSMenuItem?) {
        guard
            let menuItem = sender,
            let index = menuItem.menu?.index(of: menuItem)
        else {
            return
        }

        self.viewModel.selectedZoomLevel = index
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
    @IBOutlet var newPageMenuDelegate: NewPageMenuDelegate!
    @IBAction func newPageFromContextMenu(_ sender: NSMenuItem?) {
        guard
            let rawType = sender?.representedObject as? String,
            let type = PageContentType(rawValue: rawType)
        else {
            return
        }

        var centrePoint: CGPoint?
        if let location = self.canvasView.currentClickLocation {
            centrePoint = self.layoutEngine.convertPointToPageSpace(location)
        }
        self.viewModel.newPage(of: type, centredOn: centrePoint)
    }

    @IBAction func addPageToCanvas(_ sender: Any?) {
        guard let windowController = self.windowController as? DocumentWindowController else {
            return
        }

        windowController.showPageSelector(title: NSLocalizedString("Add page to canvas…", comment: "Add page selector title")) { [weak self] result in
            guard case .page(let page) = result else {
                return
            }
            var centrePoint: CGPoint?
            if let location = self?.canvasView.currentClickLocation {
                centrePoint = self?.layoutEngine.convertPointToPageSpace(location)
            }
            self?.viewModel.addPages(with: [page.id], centredOn: centrePoint)
        }
    }

    @IBAction func editPage(_ sender: Any) {
        guard
            let clickedLocation = self.canvasView.currentClickLocation,
            let page = self.layoutEngine.item(atCanvasPoint: clickedLocation) as? LayoutEnginePage
        else {
            return
        }

        self.layoutEngine.startEditing(page, atContentPoint: page.convertPointToContentSpace(clickedLocation))
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

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(self.zoomControlChanged(_:)) {
            return true
        }
        let notEditableTooltip = NSLocalizedString("The current Canvas is not editable", comment: "Non-editable canvas action tooltip")
        if menuItem.action == #selector(self.newPageFromContextMenu(_:)) {
            menuItem.toolTip = (self.layoutEngine.editable ? nil : notEditableTooltip)
            return self.layoutEngine.editable
        }
        if menuItem.action == #selector(self.addPageToCanvas(_:)) {
            menuItem.toolTip = (self.layoutEngine.editable ? nil : notEditableTooltip)
            return self.layoutEngine.editable
        }
        if menuItem.action == #selector(self.removeSelectedPages(_:)) {
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
        if menuItem.action == #selector(self.deleteItems(_:)) {
            menuItem.toolTip = (self.layoutEngine.editable ? nil : notEditableTooltip)
            return (self.viewModel.selectedCanvasPages.count == 1) && self.layoutEngine.editable
        }
        if menuItem.action == #selector(self.zoomIn(_:)) {
            return self.viewModel.canZoomIn
        }
        if menuItem.action == #selector(self.zoomOut(_:)) {
            return self.viewModel.canZoomOut
        }
        if menuItem.action == #selector(self.zoomTo100(_:)) {
            return self.viewModel.canZoomTo100
        }
        if menuItem.action == #selector(self.selectAll(_:)) ||
           menuItem.action == #selector(self.deselectAll(_:))
        {
            return true
        }
        if menuItem.action == #selector(TextEditorViewController.editLink(_:)) {
            if self.selectedPages.count == 1 {
                menuItem.toolTip = nil
                return true
            }
            menuItem.toolTip = NSLocalizedString("Start editing a Page to create a link", comment: "Canvas Link to Page disabled tooltip")
            return false
        }
        if menuItem.action == #selector(self.editPage(_:)) {
            return self.canvasView.clickedPageView != nil
        }
        return false
    }


    //MARK: - Focus Mode
    private var currentFocusModeEditor: (PageContentEditor & NSViewController)? {
        didSet {
            oldValue?.removeFromParent()
            oldValue?.view.removeFromSuperview()
            if let newValue = self.currentFocusModeEditor {
                self.addChild(newValue)
                self.view.addSubview(newValue.view)
                newValue.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    self.scrollView.leadingAnchor.constraint(equalTo: newValue.view.leadingAnchor),
                    self.scrollView.trailingAnchor.constraint(equalTo: newValue.view.trailingAnchor),
                    self.scrollView.topAnchor.constraint(equalTo: newValue.view.topAnchor),
                    self.scrollView.bottomAnchor.constraint(equalTo: newValue.view.bottomAnchor),
                ])
                self.layoutEngine.editable = false
            } else {
                self.layoutEngine.editable = true
            }
            self.inspectorsDidChange()
        }
    }

    func enterFocusMode(for pageContentEditor: PageContentEditor) {
        self.currentFocusModeEditor = pageContentEditor.contentEditorForFocusMode()
    }

    func exitFocusMode() {
        self.currentFocusModeEditor = nil
    }


    //MARK: - SplitViewContainable
    func createSplitViewItem() -> NSSplitViewItem {
        let splitViewItem = NSSplitViewItem(viewController: self)
        splitViewItem.holdingPriority = NSLayoutConstraint.Priority(rawValue: 249)
        return splitViewItem
    }


    //MARK: - Linking
    func linkToPage(from editor: PageContentEditor) {
        self.viewModel.startLinking(from: editor)
    }


    //MARK: - Accessibility
    private func setupAccessibility() {
        guard
            let scrollView = self.scrollView,
            let toggleButton = self.toggleCanvasListButton,
            let zoomControl = self.zoomControl
        else {
                return
        }

        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(NSLocalizedString("Canvas Editor", comment: "Canvas List accessibility label"))
        self.view.setAccessibilityChildren([scrollView, toggleButton, zoomControl])

        self.canvasView.customRotors = [
            CanvasPagesAccessibilityRotor(canvas: self.viewModel.canvas, canvasEditor: self),
            CanvasLinksAccessibilityRotor(canvas: self.viewModel.canvas, canvasEditor: self),
        ]
    }


    //MARK: - Pro
    @IBOutlet weak var proImageView: NSImageView!
    @IBAction func proUpSell(_ sender: Any) {}

    private func setupPro() {
        self.proImageView.image = CoppiceProUpsell.shared.proImage
    }
}


extension CanvasEditorViewController: Editor {
    var inspectors: [Inspector] {
        if let focusModeEditor = self.currentFocusModeEditor {
            return focusModeEditor.inspectors
        }
        guard self.layoutEngine.editable, self.selectedPages.count == 1 else {
            return [self.canvasInspector]
        }
        return self.selectedPages[0].inspectors + [self.canvasInspector]
    }

    func open(_ link: PageLink) {
        self.viewModel.addPage(at: link,
                               useAlternate: NSApplication.shared.currentEvent?.modifierFlags.contains(.command) == true)
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
		guard let pageViewController = self.pageViewController(for: canvasPage) else {
			return
		}

		self.scrollToPageViewController(pageViewController)
		pageViewController.flash()
    }

    func notifyAccessibilityOfMove(_ canvasPages: [CanvasPage]) {
        guard let canvasView = self.canvasView else {
            return
        }
        let views = canvasPages.compactMap { self.pageViewController(for: $0)?.view }

        NSAccessibility.post(element: canvasView, notification: .layoutChanged, userInfo: [NSAccessibility.NotificationUserInfoKey.uiElements: views])
    }

    func themeDidChange() {
        self.forceFullLayout()
    }
}


extension CanvasEditorViewController: CanvasLayoutView {
    func layoutChanged(with context: CanvasLayoutEngine.LayoutContext) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.layout), object: nil)
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
