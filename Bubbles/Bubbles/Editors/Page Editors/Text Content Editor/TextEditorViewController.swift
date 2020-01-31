//
//  TextEditorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class TextEditorViewController: NSViewController, InspectableTextEditor {
    @IBOutlet var editingTextView: NSTextView!

    @objc dynamic let viewModel: TextEditorViewModel
    private let pageLinkManager: PageLinkManager
    init(viewModel: TextEditorViewModel) {
        self.viewModel = viewModel
        self.pageLinkManager = PageLinkManager(modelController: viewModel.modelController)
        super.init(nibName: "TextEditorViewController", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }



    private var selectableBinding: AnyCancellable!
    private var attributedTextObserver: AnyCancellable!
    private var highlightedRangeObserver: AnyCancellable!
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.selectableBinding = self.publisher(for: \.enabled).assign(to: \.isSelectable, on: self.editingTextView)
//        self.attributedTextObserver = self.publisher(for: \.viewModel.attributedText).sink { self.updateTextView(with: $0)}
        self.updateTextView(with: self.viewModel.attributedText)
//        self.highlightedRangeObserver = self.viewModel.$highlightedRange.sink { self.highlight($0) }

        self.editingTextView.textStorage?.delegate = self
        self.pageLinkManager.textStorage = self.editingTextView.textStorage
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.highlight(self.viewModel.highlightedRange)
    }

    @objc dynamic var enabled: Bool = true

    @objc func createNewLinkedPage(_ sender: Any?) {
        let selectedRange = self.editingTextView.selectedRange()
        self.viewModel.createNewLinkedPage(for: selectedRange)
    }

    @objc func linkToPage(_ sender: Any?) {
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

        let ranges = self.editingTextView.selectedRanges.compactMap { $0.rangeValue }
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


    //MARK: - Update Model
    private func updateTextView(with text: NSAttributedString) {
        guard (self.updatingText == false) else {
            return
        }
        self.editingTextView.textStorage?.setAttributedString(text)
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
            self.perform(#selector(updateText), with: nil, afterDelay: 1)
        }
    }

    private var updatingText = false
    @objc dynamic private func updateText() {
        self.updatingText = true
        self.viewModel.attributedText = self.editingTextView.attributedString().copy() as! NSAttributedString
        self.updatingText = false
        self.updateSelectionAttributes()
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


extension TextEditorViewController: Editor {
    var inspectors: [Inspector] {
        return [self.textEditorInspectorViewController]
    }
}


extension TextEditorViewController: TextEditorView {
    func addLink(with url: URL, to range: NSRange) {
        self.editingTextView.modifyText(in: [range]) { (textStorage) in
            textStorage.addAttribute(.link, value: url, range: range)
        }
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
        menu.addItem(withTitle: "Create New Linked Page…", action: #selector(createNewLinkedPage(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Link to Page…", action: #selector(linkToPage(_:)), keyEquivalent: "")
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
        print("selection changed")
        guard (notification.object as? NSTextView) == self.editingTextView else {
            return
        }
        self.updateSelectionAttributes()
    }
}
