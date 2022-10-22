//
//  TextEditorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore

class TextEditorViewController: NSViewController, NSMenuItemValidation, NSToolbarItemValidation {
    @IBOutlet var editingTextView: CanvasTextView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var placeHolderLabel: NSTextField!
    @IBOutlet var placeHolderLeftConstraint: NSLayoutConstraint!
    @IBOutlet var placeHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet var widthConstraint: NSLayoutConstraint!

    @objc dynamic let viewModel: TextEditorViewModel
    init(viewModel: TextEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "TextEditorViewController", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    lazy var newPageMenuDelegate: NewPageMenuDelegate = {
        let delegate = NewPageMenuDelegate()
        delegate.action = #selector(createNewLinkedPage(_:))
        return delegate
    }()

	//MARK: - Subscribers
	private enum SubscriberKey {
		case searchResultsWereClicked
	}

	private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    private var selectableBinding: AnyCancellable!
    private var highlightedRangeObserver: AnyCancellable!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateTextView(with: self.viewModel.attributedText)

        self.scrollView.automaticallyAdjustsContentInsets = false
        self.scrollView.contentInsets = GlobalConstants.textEditorInsets(fullSize: (self.viewModel.viewMode != .canvas))

        self.editingTextView.textStorage?.delegate = self

        self.updatePlaceholder()

        self.attributeEditor.textView = self.editingTextView

        self.widthConstraint.isActive = (self.viewModel.viewMode != .canvas)

        if (self.viewModel.viewMode != .canvas) {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 3
            self.scrollView.shadow = shadow
        }
        self.setupTextViewNotifications()
    }

    override func viewDidAppear() {
        self.highlight(self.viewModel.highlightedRange)
        self.updatePlaceholder()

		self.subscribers[.searchResultsWereClicked] = NotificationCenter.default.publisher(for: .searchResultsWereClickedNotification).sink { [weak self] _ in
			guard let self = self else {
				return
			}
			self.highlight(self.viewModel.highlightedRange)
		}
        super.viewDidAppear()
    }

	override func viewDidDisappear() {
		super.viewDidDisappear()
		self.subscribers[.searchResultsWereClicked] = nil
	}

    @objc dynamic var enabled: Bool = true {
        didSet {
            self.attributeEditor.editorEnabled = self.enabled
        }
    }

    @IBAction func createNewLinkedPage(_ sender: Any?) {
        guard let item = sender as? NSMenuItem else {
            return
        }

        var updatingSelection = true
        if let event = NSApp.currentEvent, event.modifierFlags.contains(.option) {
            updatingSelection = false
        }

        guard let rawType = item.representedObject as? String,
            let type = PageContentType(rawValue: rawType)
        else {
            return
        }
        let selectedRange = self.editingTextView.selectedRange()
        self.viewModel.createNewLinkedPage(ofType: type, from: selectedRange, updatingSelection: updatingSelection)
    }

    @IBAction func editLink(_ sender: Any?) {
        self.linkInspectorViewController.startEditingLink()
    }

    @IBAction func copyExistingLink(_ sender: Any?) {
        guard case .url(let url) = self.attributeEditor.selectedLink else {
            return
        }

        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(url.absoluteString, forType: .URL)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([pasteboardItem])
    }

    @IBAction func removeLink(_ sender: Any?) {
        self.attributeEditor.updateSelection(with: .empty)
    }

    let attributeEditor = TextEditorAttributeEditor()

    private lazy var textEditorInspectorViewController: TextEditorFontInspectorViewController = {
        return TextEditorFontInspectorViewController(viewModel: TextEditorFontInspectorViewModel(attributeEditor: self.attributeEditor))
    }()

    private lazy var textEditorParagraphInspectorViewController: TextEditorParagraphInspectorViewController = {
        return TextEditorParagraphInspectorViewController(viewModel: TextEditorParagraphInspectorViewModel(attributeEditor: self.attributeEditor))
    }()

    private lazy var linkInspectorViewController: LinkInspectorViewController = {
        return LinkInspectorViewController(viewModel: LinkInspectorViewModel(linkEditor: self.attributeEditor,
                                                                             page: self.viewModel.textContent.page,
                                                                             documentWindowViewModel: self.viewModel.documentWindowViewModel))
    }()

    private var textViewNotifications: [NSObjectProtocol] = []
    private func setupTextViewNotifications() {
        self.textViewNotifications.append(NotificationCenter.default.addObserver(forName: .canvasTextViewDidBecomeFirstResponder, object: nil, queue: .main, using: { [weak self] (_) in
            self?.willChangeValue(for: \.showPlaceholder)
            self?.didChangeValue(for: \.showPlaceholder)
        }))
        self.textViewNotifications.append(NotificationCenter.default.addObserver(forName: .canvasTextViewDidResignFirstResponder, object: nil, queue: .main, using: { [weak self] (_) in
            self?.willChangeValue(for: \.showPlaceholder)
            self?.didChangeValue(for: \.showPlaceholder)
        }))
    }


    //MARK: - Placeholder
    @objc dynamic var showPlaceholder: Bool {
        return self.editingTextView.string.count == 0 && (self.view.window?.firstResponder != self.editingTextView)
    }

    private func updatePlaceholder() {
        self.placeHolderTopConstraint.constant = self.scrollView.contentInsets.top
        self.placeHolderLeftConstraint.constant = self.scrollView.contentInsets.left + 5
        self.placeHolderLabel.stringValue = self.viewModel.viewMode == .canvas ? NSLocalizedString("Double-click to start writing", comment: "Text Editor on canvas placeholder")
                                                                               : NSLocalizedString("Click to start writing", comment: "Text Editor placeholder")
    }


    //MARK: - Fix Font Menu
    //For some reason certain fonts won't correctly show they can toggle bold or italic, so we have to handle that ourselves (BUB-190)
    @IBAction func toggleBold(_ sender: Any?) {
        guard let attributes = self.attributeEditor.selectedFontAttributes else {
            return
        }
        self.attributeEditor.updateSelection(with: TextEditorFontAttributes(isBold: !(attributes.isBold ?? false)))
    }

    @IBAction func toggleItalic(_ sender: Any?) {
        guard let attributes = self.attributeEditor.selectedFontAttributes else {
            return
        }
        self.attributeEditor.updateSelection(with: TextEditorFontAttributes(isItalic: !(attributes.isItalic ?? false)))
    }

    @IBAction func increaseFontSize(_ sender: Any?) {
        self.attributeEditor.updateSelection(with: TextEditorFontAttributes(fontSize: .increase))
    }

    @IBAction func decreaseFontSize(_ sender: Any?) {
        self.attributeEditor.updateSelection(with: TextEditorFontAttributes(fontSize: .decrease))
    }

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        if item.action == #selector(self.editLink(_:)) {
            let enabled = (self.editingTextView.selectedRange().length > 0)
            item.toolTip = enabled ? NSLocalizedString("Link to Page", comment: "Link to Page enabled tooltip")
                                   : NSLocalizedString("Select some text to link it to another Page", comment: "Link to Page disabled tooltip")
            return enabled
        }
        return true
    }

    @IBOutlet var contextMenu: NSMenu!
    @IBOutlet var createLinkedPageMenu: NSMenu! {
        didSet {
            self.createLinkedPageMenu.delegate = self.newPageMenuDelegate
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(self.toggleBold(_:)) {
            return self.validateItem(menuItem, keyPath: \.isBold, trait: .boldFontMask)
        }
        if menuItem.action == #selector(self.toggleItalic(_:)) {
            return self.validateItem(menuItem, keyPath: \.isItalic, trait: .italicFontMask)
        }
        if menuItem.action == #selector(self.editLink(_:)) {
            switch self.attributeEditor.selectedLink {
            case .noSelection:
                menuItem.toolTip = NSLocalizedString("Select some text to create a link", comment: "Link to Page disabled tooltip")
                menuItem.title = NSLocalizedString("Create Link", comment: "Create Link menu item title")
            case .empty:
                menuItem.toolTip = nil
                menuItem.title = NSLocalizedString("Create Link", comment: "Create Link menu item title")
            case .multipleSelection, .pageLink, .url:
                menuItem.toolTip = nil
                menuItem.title = NSLocalizedString("Edit Link", comment: "Edit Link menu item title")
            }
            return (self.attributeEditor.selectedLink != .noSelection)
        }
        if menuItem.action == #selector(self.copyExistingLink(_:)) {
            let isCopyableLink: Bool

            switch self.attributeEditor.selectedLink {
            case .noSelection, .empty, .multipleSelection, .pageLink:
                isCopyableLink = false
            case .url:
                isCopyableLink = true
            }

            if menuItem.menu?.isInMainMenu == false {
                menuItem.isHidden = !isCopyableLink
            }
            return isCopyableLink
        }
        if menuItem.action == #selector(self.removeLink(_:)) {
            let isSingleLink: Bool

            switch self.attributeEditor.selectedLink {
            case .noSelection, .empty, .multipleSelection:
                isSingleLink = false
            case .pageLink, .url:
                isSingleLink = true
            }

            if menuItem.menu?.isInMainMenu == false {
                menuItem.isHidden = !isSingleLink
            }
            return isSingleLink
        }
        return true
    }

    private func validateItem(_ menuItem: NSMenuItem, keyPath: KeyPath<TextEditorFontAttributes, Bool?>, trait: NSFontTraitMask) -> Bool {
        guard let attributes = self.attributeEditor.selectedFontAttributes else {
            return false
        }
        let isTraitTrue = (attributes[keyPath: keyPath] == nil) || (attributes[keyPath: keyPath] == true)
        if let currentFont = NSFontManager.shared.selectedFont {
            let newFont: NSFont
            if isTraitTrue {
                newFont = NSFontManager.shared.convert(currentFont, toNotHaveTrait: trait)
            } else {
                newFont = NSFontManager.shared.convert(currentFont, toHaveTrait: trait)
            }
            if newFont == currentFont {
                return false
            }
        }
        menuItem.state = isTraitTrue ? .on : .off

        return true
    }


    //MARK: - Update Model
    private var editingText = false {
        didSet {
            self.updatePageLinkManager()
        }
    }

    private func setupInitialTextViewAttributesIfNeeded() {
        guard let storage = self.editingTextView.textStorage, storage.length == 0 else {
            return
        }

        self.editingTextView.font = Page.defaultFont
        self.editingTextView.textColor = NSColor.black
        self.editingTextView.alignment = .natural
    }

    func updateTextView(with text: NSAttributedString) {
        guard (self.updatingText == false) else {
            return
        }
        guard (self.editingText == false) || (self.viewModel.undoManager.isUndoing) || (self.viewModel.undoManager.isRedoing) else {
            return
        }
        self.updatingText = true
        self.willChangeValue(for: \.showPlaceholder)
        self.editingTextView.textStorage?.setAttributedString(text)
        self.setupInitialTextViewAttributesIfNeeded()
        self.didChangeValue(for: \.showPlaceholder)
        self.updatingText = false
    }

    private func textNeedsUpating(singleCharacterChange: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.updateText), object: nil)
        //This is to stop recording any edits while undoing/redoing
        guard (self.viewModel.undoManager.isUndoing == false) && (self.viewModel.undoManager.isRedoing == false) && !self.updatingText else {
            return
        }

        if !singleCharacterChange {
            self.updateText()
        } else {
            self.perform(#selector(self.updateText), with: nil, afterDelay: 0.5)
        }
    }

    private var updatingText = false
    @objc dynamic private func updateText() {
        self.updatingText = true
        self.viewModel.attributedText = self.editingTextView.attributedString().copy() as! NSAttributedString
        self.updatingText = false
        self.attributeEditor.update()
    }


    //MARK: - Page Link Manager
    private var pageLinkManager: TextPageLinkManager? {
        return self.viewModel.pageLinkManager
    }

    private func updatePageLinkManager() {
        guard let pageLinkManager = self.pageLinkManager else {
            return
        }

        guard self.editingText else {
            pageLinkManager.currentTextStorage = nil
            pageLinkManager.delegate = nil
            return
        }
        pageLinkManager.delegate = self
        pageLinkManager.currentTextStorage = self.editingTextView.textStorage
    }


    //MARK: - Search
    private func highlight(_ range: NSRange?) {
        guard let highlightRange = range else {
            self.editingTextView.showFindIndicator(for: NSRange(location: 0, length: 0))
            return
        }
        self.editingTextView.showFindIndicator(for: highlightRange)
    }
}


extension TextEditorViewController: PageContentEditor {
    var inspectors: [Inspector] {
        guard self.enabled else {
            return []
        }
        return [self.textEditorInspectorViewController, self.textEditorParagraphInspectorViewController, self.linkInspectorViewController]
    }

    func prepareForDisplay(withSafeAreaInsets safeAreaInsets: NSEdgeInsets) {
        if #available(OSX 10.16, *) {
            var insets = GlobalConstants.textEditorInsets(fullSize: (self.viewModel.viewMode != .canvas))
            if (self.viewModel.viewMode != .canvas) {
                insets.top += safeAreaInsets.top
            }
            self.scrollView.contentInsets = insets
            NSView.animate(withDuration: 0) {
                self.view.layoutSubtreeIfNeeded()
            }
        }
    }

    func startEditing(at point: CGPoint) {
        let textViewPoint = self.editingTextView.convert(point, from: self.view)
        let insertionPoint = self.editingTextView.characterIndexForInsertion(at: textViewPoint)
        self.view.window?.makeFirstResponder(self.editingTextView)
        self.editingTextView.setSelectedRange(NSRange(location: insertionPoint, length: 0))
    }

    func stopEditing() {
        if (self.editingText) {
            self.view.window?.makeFirstResponder(nil)
        }
    }

    func isLink(at point: CGPoint) -> Bool {
        let textViewPoint = self.editingTextView.convert(point, from: self.view)
        //We want to make sure the click is inside the bounds of the text
        guard
            self.editingTextView.bounds.contains(textViewPoint),
            let textContainer = self.editingTextView.textContainer,
            let layoutManager = self.editingTextView.layoutManager,
            layoutManager.usedRect(for: textContainer).contains(textViewPoint)
        else {
            return false
        }
        let insertionPoint = self.editingTextView.characterIndexForInsertion(at: textViewPoint)
        guard (self.editingTextView.textStorage?.length ?? 0) > insertionPoint else {
            return false
        }
        guard let attributes = self.editingTextView.textStorage?.attributes(at: insertionPoint, effectiveRange: nil) else {
            return false
        }
        return attributes[.link] != nil
    }

    func openLink(at point: CGPoint) {
        let textViewPoint = self.editingTextView.convert(point, from: self.view)
        let insertionPoint = self.editingTextView.characterIndexForInsertion(at: textViewPoint)
        guard
            let attributes = self.editingTextView.textStorage?.attributes(at: insertionPoint, effectiveRange: nil),
            let link = attributes[.link]
        else {
            return
        }
        self.editingTextView.clicked(onLink: link, at: insertionPoint)
    }
}


extension TextEditorViewController: TextEditorView {
    func addLink(with url: URL, to range: NSRange) {
        self.editingTextView.modifyText(in: [range]) { (textStorage) in
            textStorage.addAttribute(.link, value: url, range: range)
        }
    }
}

extension TextEditorViewController: NSTextDelegate {
    func textDidBeginEditing(_ notification: Notification) {
        self.viewModel.documentWindowViewModel.registerStartOfEditing()
        self.editingText = true
    }

    func textDidEndEditing(_ notification: Notification) {
        self.editingText = false
    }
}


extension TextEditorViewController: TextPageLinkManagerDelegate {
    func shouldChangeText(in ranges: [NSRange], manager: TextPageLinkManager) -> Bool {
        return true //Can't use the actual method because the swift compiler is being funny
    }

    func textDidChange(in manager: TextPageLinkManager) {
        self.editingTextView.didChangeText()
    }
}


extension TextEditorViewController: NSTextStorageDelegate {
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        //Both the page link manager and ourselves need this call but only one can be the delegate
        self.pageLinkManager?.textStorage(textStorage, didProcessEditing: editedMask, range: editedRange, changeInLength: delta)

        if (editedMask.contains(.editedCharacters) && (abs(delta) == 1)) {
            self.textNeedsUpating(singleCharacterChange: true)
        } else {
            self.textNeedsUpating(singleCharacterChange: false)
        }
    }
}


extension TextEditorViewController: NSTextViewDelegate {
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        menu.removeSection(startingAtItemWithAction: #selector(self.copyExistingLink(_:)))

        var insertionIndex = menu.indexOfItem(withTarget: nil, andAction: #selector(NSTextView.paste(_:)))
        guard insertionIndex != -1 else {
            return menu
        }

        insertionIndex += 1 //Check next
        while insertionIndex < menu.items.count {
            if menu.item(at: insertionIndex)?.isSeparatorItem == true {
                break
            }
        }
        insertionIndex += 1 //Insert after separator

        for item in self.contextMenu.items {
            guard let copiedItem = item.copy() as? NSMenuItem else {
                continue
            }
            menu.insertItem(copiedItem, at: insertionIndex)
            insertionIndex += 1
        }
        menu.insertItem(NSMenuItem.separator(), at: insertionIndex)
        return menu
    }

    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        guard let url = link as? URL else {
            return false
        }

        //If the user is holding option we want to capture the link event but NOT open the link
        guard NSApp.currentEvent?.modifierFlags.contains(.option) != true else {
            textView.selectedRanges = [NSValue(range: NSRange(location: charIndex, length: 0))]
            return true
        }

        guard let pageLink = PageLink(url: url) else {
            return false
        }
        self.open(pageLink)
        return true
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard (notification.object as? NSTextView) == self.editingTextView else {
            return
        }
        self.attributeEditor.update()
    }

    func textView(_ textView: NSTextView, shouldChangeTextInRanges affectedRanges: [NSValue], replacementStrings: [String]?) -> Bool {
        return true
    }

    func textDidChange(_ notification: Notification) {
        self.willChangeValue(for: \.showPlaceholder)
        self.didChangeValue(for: \.showPlaceholder)
    }

    func textShouldBeginEditing(_ textObject: NSText) -> Bool {
        return true
    }

    func textShouldEndEditing(_ textObject: NSText) -> Bool {
        return true
    }
}


class TextEditorContainerView: NSView {
    @IBOutlet var placeHolderLabel: NSTextField!
    @IBOutlet var canvasTextView: CanvasTextView!
    override func hitTest(_ point: NSPoint) -> NSView? {
        let view = super.hitTest(point)
        if (view == self.placeHolderLabel) {
            return self.canvasTextView
        }
        return view
    }
}
