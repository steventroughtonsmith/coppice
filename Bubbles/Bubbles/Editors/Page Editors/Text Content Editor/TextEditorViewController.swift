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
    @IBOutlet var textView: NSTextView!

    @objc dynamic let viewModel: TextEditorViewModel
    init(viewModel: TextEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "TextEditorViewController", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    @objc func createNewLinkedPage(_ sender: Any?) {
        let selectedRange = self.textView.selectedRange()
        self.viewModel.createNewLinkedPage(for: selectedRange)
    }

    @objc func linkToPage(_ sender: Any?) {
        guard let windowController = (self.windowController as? DocumentWindowController) else {
            return
        }
        let selectedRange = self.textView.selectedRange()
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
        var baseAttributes = self.textView.typingAttributes
        baseAttributes.merge(self.textView.selectedTextAttributes) { (key1, _) in key1 }

        guard self.textView.isTextSelected else {
            self.selectionAttributes = TextEditorAttributes(attributes: baseAttributes)
            return
        }

        guard let textStorage = self.textView.textStorage else {
            return
        }

        let ranges = self.textView.selectedRanges.compactMap { $0.rangeValue }
        self.selectionAttributes = textStorage.textEditorAttributes(in: ranges, typingAttributes: baseAttributes)
    }

    func updateSelection(with editorAttributes: TextEditorAttributes) {
        guard self.textView.isTextSelected else {
            self.textView.typingAttributes = editorAttributes.apply(to: self.textView.typingAttributes)
            self.updateSelectionAttributes()
            return
        }

        let ranges = self.textView.selectedRanges.compactMap { $0.rangeValue }
        self.textView.modifyText(in: ranges) { (textStorage) in
            textStorage.apply(editorAttributes, to: ranges)
        }
        self.updateSelectionAttributes()
    }
}




extension TextEditorViewController: Editor {
    var inspectors: [Inspector] {
        return [self.textEditorInspectorViewController]
    }
}


extension TextEditorViewController: TextEditorView {
}


extension TextEditorViewController: NSTextViewDelegate {
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Create New Linked Page…", action: #selector(createNewLinkedPage(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Link to Page…", action: #selector(linkToPage(_:)), keyEquivalent: "")
        return menu
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard self.view.window?.firstResponder == self.textView else {
            return
        }
        self.updateSelectionAttributes()
    }
}
