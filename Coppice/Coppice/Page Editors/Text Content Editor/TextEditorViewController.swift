//
//  TextEditorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class TextEditorViewController: NSViewController, InspectableTextEditor, NSMenuItemValidation {
    @IBOutlet var editingTextView: NSTextView!
    @IBOutlet weak var scrollView: NSScrollView!

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
    private var attributedTextObserver: AnyCancellable!
    private var highlightedRangeObserver: AnyCancellable!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateTextView(with: self.viewModel.attributedText)

        guard self.viewModel.mode == .editing else {
            return
        }
//        self.selectableBinding = self.publisher(for: \.enabled).assign(to: \.isSelectable, on: self.editingTextView)
//        self.attributedTextObserver = self.publisher(for: \.viewModel.attributedText).sink { [weak self] in self?.updateTextView(with: $0) }
//        self.highlightedRangeObserver = self.viewModel.$highlightedRange.sink { self.highlight($0) }

        self.scrollView.contentInsets = GlobalConstants.textEditorInsets

        self.editingTextView.textStorage?.delegate = self
    }

    override func viewDidAppear() {
        self.highlight(self.viewModel.highlightedRange)
        super.viewDidAppear()

        self.attributedTextObserver = self.publisher(for: \.viewModel.attributedText).sink { [weak self] in self?.updateTextView(with: $0) }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        //Observing self requires us to explicitly cancel and clear out the observer, as it seems to hold an unretained reference to us
        self.attributedTextObserver?.cancel()
        self.attributedTextObserver = nil
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

    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(linkToPage(_:)) {
            return (self.editingTextView.selectedRange().length > 0)
        }
        return super.responds(to: aSelector)
    }

    private lazy var textEditorInspectorViewController: TextEditorInspectorViewController = {
        return TextEditorInspectorViewController(viewModel: TextEditorInspectorViewModel(editor: self, modelController: self.viewModel.modelController))
    }()


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

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleBold(_:)) {
            return self.validateItem(menuItem, keyPath: \.isBold, trait: .boldFontMask)
        }
        if menuItem.action == #selector(toggleItalic(_:)) {
            return self.validateItem(menuItem, keyPath: \.isItalic, trait: .italicFontMask)
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

    private func updateTextView(with text: NSAttributedString) {
        guard (self.updatingText == false) else {
            return
        }
        guard (self.editingText == false) || (self.viewModel.undoManager.isUndoing) || (self.viewModel.undoManager.isRedoing) else {
            return
        }
        self.updatingText = true
        self.editingTextView.textStorage?.setAttributedString(text)
        self.setupInitialTextViewAttributesIfNeeded()
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
    
    var isInCanvas: Bool {
        return (self.parentEditor as? PageEditorViewController)?.isInCanvas ?? false
    }
}


extension TextEditorViewController: Editor {
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


    func textShouldBeginEditing(_ textObject: NSText) -> Bool {
        return true
    }

    func textShouldEndEditing(_ textObject: NSText) -> Bool {
        return true
    }
}
