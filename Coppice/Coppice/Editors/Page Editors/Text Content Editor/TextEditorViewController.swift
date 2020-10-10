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

class TextEditorViewController: NSViewController, InspectableTextEditor, NSMenuItemValidation, NSToolbarItemValidation {
    @IBOutlet var editingTextView: NSTextView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var placeHolderLabel: NSTextField!

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

    private var selectableBinding: AnyCancellable!
    private var highlightedRangeObserver: AnyCancellable!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateTextView(with: self.viewModel.attributedText)

//        self.selectableBinding = self.publisher(for: \.enabled).assign(to: \.isSelectable, on: self.editingTextView)
//        self.attributedTextObserver = self.publisher(for: \.viewModel.attributedText).sink { [weak self] in self?.updateTextView(with: $0) }
//        self.highlightedRangeObserver = self.viewModel.$highlightedRange.sink { self.highlight($0) }

        self.scrollView.contentInsets = GlobalConstants.textEditorInsets

        self.editingTextView.textStorage?.delegate = self

        self.updatePlaceholder()
    }

    override func viewDidAppear() {
        self.highlight(self.viewModel.highlightedRange)
        self.updatePlaceholder()
        super.viewDidAppear()
    }

    @objc dynamic var enabled: Bool = true

    @IBAction func createNewLinkedPage(_ sender: Any?) {
        guard let item = sender as? NSMenuItem else {
            return
        }

        var updatingSelection = true
        if let event = NSApp.currentEvent, event.modifierFlags.contains(.option) {
            updatingSelection = false
        }

        guard let rawType = item.representedObject as? String,
            let type = PageContentType(rawValue: rawType) else {
            return
        }
        let selectedRange = self.editingTextView.selectedRange()
        self.viewModel.createNewLinkedPage(ofType: type, from: selectedRange, updatingSelection: updatingSelection)
    }

    @IBAction func linkToPage(_ sender: Any?) {
        guard let windowController = (self.windowController as? DocumentWindowController) else {
            return
        }
        let selectedRange = self.editingTextView.selectedRange()
        windowController.showPageSelector(title: "Link to page…") { [weak self] (page) in
            self?.viewModel.link(to: page, for: selectedRange)
        }
    }

    private lazy var textEditorInspectorViewController: TextEditorInspectorViewController = {
        return TextEditorInspectorViewController(viewModel: TextEditorInspectorViewModel(editor: self, modelController: self.viewModel.modelController))
    }()



    //MARK: - Placeholder
    @objc dynamic var showPlaceholder: Bool {
        return self.editingTextView.string.count == 0
    }


    //MARK: - InspectableTextEditor
    @Published var selectionAttributes: TextEditorAttributes?

    var selectionAttributesDidChange: AnyPublisher<TextEditorAttributes?, Never> {
        return self.$selectionAttributes.eraseToAnyPublisher()
    }

    private func updateSelectionAttributes() {
        var baseAttributes = self.editingTextView.typingAttributes
        baseAttributes.merge(self.editingTextView.selectedTextAttributes) { (key1, _) in key1 }

        guard self.editingTextView.isTextSelected else {
            self.selectionAttributes = TextEditorAttributes(attributes: baseAttributes)
            return
        }

        guard let textStorage = self.editingTextView.textStorage else {
            return
        }

        let ranges = self.editingTextView.selectedRanges.compactMap { $0.rangeValue }.filter { ($0.lowerBound < textStorage.length) && ($0.upperBound <= textStorage.length) }
        self.selectionAttributes = textStorage.textEditorAttributes(in: ranges, typingAttributes: baseAttributes)
    }

    func updateSelection(with editorAttributes: TextEditorAttributes) {
        guard self.editingTextView.isTextSelected else {
            self.editingTextView.typingAttributes = editorAttributes.apply(to: self.editingTextView.typingAttributes)
            self.updateSelectionAttributes()
            return
        }

        let ranges = self.editingTextView.selectedRanges.compactMap { $0.rangeValue }
        self.editingTextView.modifyText(in: ranges) { (textStorage) in
            textStorage.apply(editorAttributes, to: ranges)
        }
        self.updateSelectionAttributes()
    }


    //MARK: - Fix Font Menu
    //For some reason certain fonts won't correctly show they can toggle bold or italic, so we have to handle that ourselves (BUB-190)
    @IBAction func toggleBold(_ sender: Any?) {
        guard let attributes = self.selectionAttributes else {
            return
        }
        self.updateSelection(with: TextEditorAttributes(isBold: !(attributes.isBold ?? false)))
    }

    @IBAction func toggleItalic(_ sender: Any?) {
        guard let attributes = self.selectionAttributes else {
            return
        }
        self.updateSelection(with: TextEditorAttributes(isItalic: !(attributes.isItalic ?? false)))
    }

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        if item.action == #selector(linkToPage(_:)) {
            let enabled = (self.editingTextView.selectedRange().length > 0)
            item.toolTip = enabled ? NSLocalizedString("Link to Page", comment: "Link to Page enabled tooltip")
                                   : NSLocalizedString("Select some text to link it to another Page", comment: "Link to Page disabled tooltip")
            return enabled
        }
        return true
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleBold(_:)) {
            return self.validateItem(menuItem, keyPath: \.isBold, trait: .boldFontMask)
        }
        if menuItem.action == #selector(toggleItalic(_:)) {
            return self.validateItem(menuItem, keyPath: \.isItalic, trait: .italicFontMask)
        }
        if menuItem.action == #selector(linkToPage(_:)) {
            let enabled = (self.editingTextView.selectedRange().length > 0)
            menuItem.toolTip = enabled ? nil : NSLocalizedString("Select some text to link it to another Page", comment: "Link to Page disabled tooltip")
            return enabled
        }
        return true
    }

    private func validateItem(_ menuItem: NSMenuItem, keyPath: KeyPath<TextEditorAttributes, Bool?>, trait: NSFontTraitMask) -> Bool {
        guard let attributes = self.selectionAttributes else {
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


    //MARK: - Placeholder
    private func updatePlaceholder() {
        self.placeHolderLabel.stringValue = self.isInCanvas ? NSLocalizedString("Double-click to start writing", comment: "Text Editor on canvas placeholder")
                                                            : NSLocalizedString("Click to start writing", comment: "Text Editor placeholder")
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
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateText), object: nil)
        //This is to stop recording any edits while undoing/redoing
        guard (self.viewModel.undoManager.isUndoing == false) && (self.viewModel.undoManager.isRedoing == false) && !self.updatingText else {
            return
        }

        if !singleCharacterChange {
            self.updateText()
        } else {
            self.perform(#selector(updateText), with: nil, afterDelay: 0.5)
        }
    }

    private var updatingText = false
    @objc dynamic private func updateText() {
        self.updatingText = true
        self.viewModel.attributedText = self.editingTextView.attributedString().copy() as! NSAttributedString
        self.updatingText = false
        self.updateSelectionAttributes()
    }


    //MARK: - Page Link Manager
    private var pageLinkManager: PageLinkManager {
        return self.viewModel.pageLinkManager
    }

    private func updatePageLinkManager() {
        guard self.editingText else {
            self.pageLinkManager.currentTextStorage = nil
            self.pageLinkManager.delegate = nil
            return
        }
        self.pageLinkManager.delegate = self
        self.pageLinkManager.currentTextStorage = self.editingTextView.textStorage
    }


    //MARK: - Search
    private func highlight(_ range: NSRange?) {
        guard let highlightRange = range else {
            self.editingTextView.showFindIndicator(for: NSRange(location: NSNotFound, length: 0))
            return
        }
        self.editingTextView.showFindIndicator(for: highlightRange)
    }

    var simulateInCanvas: Bool = false
    
    var isInCanvas: Bool {
        if self.simulateInCanvas {
            return true
        }
        return (self.parentEditor as? PageEditorViewController)?.isInCanvas ?? false
    }
}


extension TextEditorViewController: PageContentEditor {
    var inspectors: [Inspector] {
        return [self.textEditorInspectorViewController]
    }
    
    func prepareForDisplay(withSafeAreaInsets safeAreaInsets: NSEdgeInsets) {
        if #available(OSX 10.16, *) {
            var insets = NSEdgeInsets(top: 10, left: 5, bottom: 5, right: 5)
            if !self.isInCanvas {
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


extension TextEditorViewController: PageLinkManagerDelegate {
    func shouldChangeText(in ranges: [NSRange], manager: PageLinkManager) -> Bool {
        return true //Can't use the actual method because the swift compiler is being funny
    }

    func textDidChange(in manager: PageLinkManager) {
        self.editingTextView.didChangeText()
    }
}


extension TextEditorViewController: NSTextStorageDelegate {
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        //Both the page link manager and ourselves need this call but only one can be the delegate
        self.pageLinkManager.textStorage(textStorage, didProcessEditing: editedMask, range: editedRange, changeInLength: delta)

        if (editedMask.contains(.editedCharacters) && (abs(delta) == 1)) {
            self.textNeedsUpating(singleCharacterChange: true)
        } else {
            self.textNeedsUpating(singleCharacterChange: false)
        }
    }
}


extension TextEditorViewController: NSTextViewDelegate {
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Link to Page…", action: #selector(linkToPage(_:)), keyEquivalent: "")

        let createPageItem = menu.addItem(withTitle: "Create New Linked Page", action: nil, keyEquivalent: "")
        let createPageMenu = NSMenu()
        createPageMenu.delegate = self.newPageMenuDelegate
        createPageItem.submenu = createPageMenu
        return menu
    }

    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        guard let url = link as? URL else {
            return false
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
        self.updateSelectionAttributes()
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
