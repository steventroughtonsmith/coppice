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

    private var selectableBinding: AnyCancellable!
    private var highlightedRangeObserver: AnyCancellable!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateTextView(with: self.viewModel.attributedText)

//        self.selectableBinding = self.publisher(for: \.enabled).assign(to: \.isSelectable, on: self.editingTextView)
//        self.attributedTextObserver = self.publisher(for: \.viewModel.attributedText).sink { [weak self] in self?.updateTextView(with: $0) }
//        self.highlightedRangeObserver = self.viewModel.$highlightedRange.sink { self.highlight($0) }

        self.scrollView.automaticallyAdjustsContentInsets = false
        self.scrollView.contentInsets = GlobalConstants.textEditorInsets(fullSize: !self.viewModel.isInCanvas)

        self.editingTextView.textStorage?.delegate = self

        self.updatePlaceholder()

        self.attributeEditor.textView = self.editingTextView

        self.widthConstraint.isActive = !self.viewModel.isInCanvas

        if (!self.viewModel.isInCanvas) {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 3
            self.scrollView.shadow = shadow
        }
        self.setupTextViewNotifications()
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
            let type = PageContentType(rawValue: rawType)
        else {
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

    let attributeEditor = TextEditorAttributeEditor()

    private lazy var textEditorInspectorViewController: TextEditorFontInspectorViewController = {
        return TextEditorFontInspectorViewController(viewModel: TextEditorFontInspectorViewModel(attributeEditor: self.attributeEditor, modelController: self.viewModel.modelController))
    }()

    private lazy var textEditorParagraphInspectorViewController: TextEditorParagraphInspectorViewController = {
        return TextEditorParagraphInspectorViewController(viewModel: TextEditorParagraphInspectorViewModel(attributeEditor: self.attributeEditor, modelController: self.viewModel.modelController))
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
        self.placeHolderLabel.stringValue = self.viewModel.isInCanvas ? NSLocalizedString("Double-click to start writing", comment: "Text Editor on canvas placeholder")
                                                                      : NSLocalizedString("Click to start writing", comment: "Text Editor placeholder")
    }



    //MARK: - InspectableTextEditor
//    @Published var selectedFontAttributes: TextEditorFontAttributes?
//    var selectedFontAttributesDidChange: AnyPublisher<TextEditorFontAttributes?, Never> {
//        return self.$selectedFontAttributes.eraseToAnyPublisher()
//    }
//
//    func updateSelection(with editorAttributes: TextEditorFontAttributes) {
//        guard self.editingTextView.isTextSelected else {
//            self.editingTextView.typingAttributes = editorAttributes.apply(to: self.editingTextView.typingAttributes)
//            self.updateSelectedFontAttributes()
//            return
//        }
//
//        let ranges = self.editingTextView.selectedRanges.compactMap { $0.rangeValue }
//        self.editingTextView.modifyText(in: ranges) { (textStorage) in
//            textStorage.apply(editorAttributes, to: ranges)
//        }
//        self.updateSelectedFontAttributes()
//    }
//
//    private func updateSelectedFontAttributes() {
//        var baseAttributes = self.editingTextView.typingAttributes
//        baseAttributes.merge(self.editingTextView.selectedTextAttributes) { (key1, _) in key1 }
//
//        guard self.editingTextView.isTextSelected else {
//            self.selectedFontAttributes = TextEditorFontAttributes.withAttributes(baseAttributes)
//            return
//        }
//
//        guard let textStorage = self.editingTextView.textStorage else {
//            return
//        }
//
//        let ranges = self.editingTextView.selectedRanges.compactMap { $0.rangeValue }.filter { ($0.lowerBound < textStorage.length) && ($0.upperBound <= textStorage.length) }
//        self.selectedFontAttributes = textStorage.textEditorFontAttributes(in: ranges, typingAttributes: baseAttributes)
//    }
//
//    @Published var selectedParagraphAttributes: TextEditorParagraphAttributes?
//    var selectedParagraphAttributesDidChange: AnyPublisher<TextEditorParagraphAttributes?, Never> {
//        return self.$selectedParagraphAttributes.eraseToAnyPublisher()
//    }
//
//    func updateSelection(with paragraphAttributes: TextEditorParagraphAttributes) {
//        let ranges = self.editingTextView.selectedRanges.compactMap { $0.rangeValue }
//        self.editingTextView.modifyText(in: ranges) { (textStorage) in
//            textStorage.apply(paragraphAttributes, to: ranges)
//        }
//        self.updateSelectedParagraphAttributes()
//    }
//
//    private func updateSelectedParagraphAttributes() {
//        guard let textStorage = self.editingTextView.textStorage else {
//            return
//        }
//
//        var baseAttributes = self.editingTextView.typingAttributes
//        baseAttributes.merge(self.editingTextView.selectedTextAttributes) { (key1, _) in key1 }
//
//        let ranges = self.editingTextView.selectedRanges.compactMap { $0.rangeValue }.filter { ($0.lowerBound <= textStorage.length) && ($0.upperBound <= textStorage.length) }
//        self.selectedParagraphAttributes = textStorage.textEditorParagraphAttributes(in: ranges, typingAttributes: baseAttributes)
//    }
//
//
//    @Published var selectedListTypes: [NSTextList]?
//    var selectedListTypesDidChange: AnyPublisher<[NSTextList]?, Never> {
//        return self.$selectedListTypes.eraseToAnyPublisher()
//    }
//
//    func updateSelection(withListType listType: NSTextList?) {
//        let (range, level) = self.calculateEditingRangeAndLevelForList()
//        guard let editingRange = range else {
//            return
//        }
//
//        var selectedLocation = self.editingTextView.selectedRange().location
//
//        self.editingTextView.modifyText(in: [editingRange]) { (textStorage) in
//            guard editingRange.location < textStorage.length else {
//                if let list = listType {
//                    let string = "\t\(list.marker(forItemNumber: 0))\t"
//                    var attributes = self.editingTextView.typingAttributes
//                    let paragraphStyle = (attributes[.paragraphStyle] as? NSParagraphStyle) ?? self.editingTextView.defaultParagraphStyle ?? NSParagraphStyle()
//                    if let mutableStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle {
//                        mutableStyle.textLists = [list]
//                        attributes[.paragraphStyle] = mutableStyle.copy()
//                    }
//
//                	textStorage.append(NSAttributedString(string: string, attributes: attributes))
//                }
//                return
//            }
//
//            let oldString = textStorage.copy() as! NSAttributedString
//            var replacements: [(NSRange, String)] = []
//            textStorage.enumerateAttribute(.paragraphStyle, in: editingRange, options: []) { (attribute, effectiveRange, _) in
//                guard
//                    let oldParagraphStyle = attribute as? NSParagraphStyle,
//                    let newParagraphStyle = oldParagraphStyle.mutableCopy() as? NSMutableParagraphStyle
//                else {
//                    return
//                }
//
//
//                var textLists = newParagraphStyle.textLists
//                if let listType = listType {
//                    if (textLists.count > level) {
//                        textLists[level] = listType
//                    } else {
//                        textLists = [listType]
//                    }
//                } else {
//                    textLists = []
//                }
//                newParagraphStyle.textLists = textLists
//
//                textStorage.removeAttribute(.paragraphStyle, range: effectiveRange)
//                textStorage.addAttribute(.paragraphStyle, value: newParagraphStyle, range: effectiveRange)
//
//                (oldString.string as NSString).enumerateSubstrings(in: effectiveRange, options: .byLines) { (substring, substringRange, effectiveRange, _) in
//                    var existingRange = NSRange(location: substringRange.location, length: 0)
//                    if let oldList = oldParagraphStyle.textLists.last {
//                        var itemNumber = oldString.itemNumber(in: oldList, at: substringRange.location)
//                        if (oldList.startingItemNumber > 1) {
//                            itemNumber = oldList.startingItemNumber + (itemNumber - 1)
//                        }
//                        existingRange.length = oldList.marker(forItemNumber: itemNumber).count + 2
//                    }
//
//                    if let list = textLists.last {
//                        replacements.append((existingRange, "\t\(list.marker(forItemNumber: textStorage.itemNumber(in: list, at: substringRange.location)))\t"))
//                    } else {
//                        replacements.append((existingRange, ""))
//                    }
//                }
//            }
//
//            for (range, string) in replacements.reversed() {
//                textStorage.replaceCharacters(in: range, with: string)
//                if (range.location < selectedLocation) {
//                    selectedLocation += (string.count - range.length)
//                }
//            }
//        }
//
//        self.editingTextView.selectedRanges = [NSValue(range: NSRange(location: selectedLocation, length: 0))]
//
//
//        self.updateListTypes()
//    }
//
//    private func calculateEditingRangeAndLevelForList() -> (NSRange?, Int) {
//        guard let textStorage = self.editingTextView.textStorage else {
//            return (nil, 0)
//        }
//
//        let selectedRanges = self.editingTextView.selectedRanges.compactMap { $0.rangeValue }.filter { ($0.lowerBound <= textStorage.length) && ($0.upperBound <= textStorage.length) }
//        if textStorage.length == 0, selectedRanges.count == 1, selectedRanges[0] == NSRange(location: 0, length: 0) {
//            return (NSRange(location: 0, length: 0), 0)
//        }
//
//        var level: Int? = nil
//        var editingRange: NSRange?
//
//        let block: ((Any?, NSRange) -> Void) = { (attribute, effectiveRange) in
//            guard let paragraphStyle = attribute as? NSParagraphStyle else {
//                return
//            }
//
//            var newRange = effectiveRange
//            if let currentLevel = level {
//                level = min(currentLevel, max(paragraphStyle.textLists.count - 1, 0))
//            } else {
//                level = max(paragraphStyle.textLists.count - 1, 0)
//            }
//            if let list = paragraphStyle.textLists.last {
//                let listRange = textStorage.range(of: list, at: effectiveRange.location)
//                if (listRange.location != NSNotFound) {
//                    newRange = listRange
//                }
//            } else {
//                newRange = (textStorage.string as NSString).paragraphRange(for: effectiveRange)
//            }
//
//            guard let editRange = editingRange else {
//                editingRange = newRange
//                return
//            }
//            editingRange = editRange.union(newRange)
//        }
//
//        for range in selectedRanges {
//            if range.length == 0 {
//                var effectiveRange = NSRange(location: NSNotFound, length: 0)
//                var actualRange = range
//                if (actualRange.location == textStorage.length) {
//                    actualRange.location = max(actualRange.location - 1, 0)
//                }
//                var attribute: Any? = self.editingTextView.defaultParagraphStyle
//                if (textStorage.length > 0) {
//                    attribute = textStorage.attribute(.paragraphStyle, at: actualRange.location, effectiveRange: &effectiveRange)
//                    if let attribute = attribute as? NSParagraphStyle {
//                        if attribute.textLists.count == 0 {
//                            effectiveRange = (textStorage.string as NSString).paragraphRange(for: range)
//                        }
//                    }
//                }
//
//                block(attribute, effectiveRange)
//            } else {
//                textStorage.enumerateAttribute(.paragraphStyle, in: range, options: []) { (attribute, effectiveRange, _) in
//                    block(attribute, effectiveRange)
//                }
//            }
//        }
//        return (editingRange, level ?? 0)
//    }
//
//    private func updateListTypes() {
//        guard let textStorage = self.editingTextView.textStorage else {
//            return
//        }
//
//        guard textStorage.length > NSMaxRange(self.editingTextView.selectedRange()) else {
//            self.selectedListTypes = []
//            return
//        }
//
//        guard let ranges = self.editingTextView.rangesForUserParagraphAttributeChange else {
//            self.selectedListTypes = []
//            return
//        }
//
//        var selectionListTypes = [[NSTextList]]()
//        for range in ranges.map(\.rangeValue) {
//            guard range.location < textStorage.length else {
//                continue
//            }
//
//            textStorage.enumerateAttribute(.paragraphStyle, in: range, options: []) { (attribute, range, stop) in
//                guard let paragraphStyle = attribute as? NSParagraphStyle else {
//                    return
//                }
//                selectionListTypes.append(paragraphStyle.textLists)
//            }
//        }
//
//        var currentListTypes: [NSTextList]? = nil
//        for types in selectionListTypes {
//            if (currentListTypes == nil) {
//                currentListTypes = types
//            } else if (currentListTypes != types) {
//                currentListTypes = nil
//                break
//            }
//        }
//
//        self.selectedListTypes = currentListTypes
//    }
//
//    func showCustomListPanel() {
//        self.editingTextView.orderFrontListPanel(self)
//    }


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

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        if item.action == #selector(self.linkToPage(_:)) {
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

    @IBAction func addExternalLink(_ sender: Any?) {
        self.editingTextView.orderFrontLinkPanel(sender)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(self.toggleBold(_:)) {
            return self.validateItem(menuItem, keyPath: \.isBold, trait: .boldFontMask)
        }
        if menuItem.action == #selector(self.toggleItalic(_:)) {
            return self.validateItem(menuItem, keyPath: \.isItalic, trait: .italicFontMask)
        }
        if menuItem.action == #selector(self.linkToPage(_:)) {
            let enabled = (self.editingTextView.selectedRange().length > 0)
            menuItem.toolTip = enabled ? nil : NSLocalizedString("Select some text to link it to another Page", comment: "Link to Page disabled tooltip")
            return enabled
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
}


extension TextEditorViewController: PageContentEditor {
    var inspectors: [Inspector] {
        return [self.textEditorInspectorViewController, self.textEditorParagraphInspectorViewController]
    }

    func prepareForDisplay(withSafeAreaInsets safeAreaInsets: NSEdgeInsets) {
        if #available(OSX 10.16, *) {
            var insets = GlobalConstants.textEditorInsets(fullSize: !self.viewModel.isInCanvas)
            if !self.viewModel.isInCanvas {
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
