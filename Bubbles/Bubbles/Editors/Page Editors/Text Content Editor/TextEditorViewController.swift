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

//        NotificationCenter.default.addObserver(self, selector: #selector(textDidBeginEditing(_:)), name: NSText.didBeginEditingNotification, object: nil)
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

        let ranges = self.textView.selectedRanges.compactMap { $0.rangeValue }
        guard (ranges.count > 1) || ((ranges.first?.length ?? 0) > 0) else {
            self.selectionAttributes = self.textEditorAttributes(from: baseAttributes)
            return
        }

        guard let textStorage = self.textView.textStorage else {
            return
        }

        var textEditorAttributes = [TextEditorAttributes]()
        for range in ranges {
            textStorage.enumerateAttributes(in: range, options: []) { (attributes, _, _) in
                let mergedAttributes = attributes.merging(baseAttributes) { (key1, _) in key1 }
                textEditorAttributes.append(self.textEditorAttributes(from: mergedAttributes))
            }
        }

        self.selectionAttributes = TextEditorAttributes.merge(textEditorAttributes)
    }

    private func textEditorAttributes(from attributes: [NSAttributedString.Key: Any]) -> TextEditorAttributes {
        let font = attributes[.font] as? NSFont
        let fontFamily = font?.familyName
        let fontPostscriptName = font?.fontDescriptor.postscriptName
        let fontSize = font?.pointSize
        let textColour = attributes[.foregroundColor] as? NSColor
        let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle
        let underlined = attributes[.underlineStyle] as? Int
        let struckthrough = attributes[.strikethroughStyle] as? Int
        let symbolicTraits = font?.fontDescriptor.symbolicTraits

        return TextEditorAttributes(fontFamily: fontFamily,
                                    fontPostscriptName: fontPostscriptName,
                                    fontSize: fontSize,
                                    textColour: textColour,
                                    alignment: paragraphStyle?.alignment,
                                    isBold: symbolicTraits?.contains(.bold),
                                    isItalic: symbolicTraits?.contains(.italic),
                                    isUnderlined: (underlined == 1),
                                    isStruckthrough: (struckthrough == 1))
    }

    func updateSelection(with editorAttributes: TextEditorAttributes) {
        let ranges = self.textView.selectedRanges.compactMap { $0.rangeValue }
        guard (ranges.count > 1) || ((ranges.first?.length ?? 0) > 0) else {
            self.textView.typingAttributes = editorAttributes.apply(to: self.textView.typingAttributes)
            self.updateSelectionAttributes()
            return
        }

        guard self.textView.shouldChangeText(inRanges: self.textView.selectedRanges, replacementStrings: nil),
              let textStorage = self.textView.textStorage else
        {
            return
        }

        textStorage.beginEditing()
        for selectionRange in ranges {
            textStorage.enumerateAttributes(in: selectionRange, options: []) { (textAttributes, range, _) in
                let newAttributes = editorAttributes.apply(to: textAttributes)
                textStorage.setAttributes(newAttributes, range: range)
//                print("range: \(range), old: \(textAttributes[.font]) new: \(newAttributes[.font])")
            }
        }
        textStorage.endEditing()
        self.textView.didChangeText()
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

    func textDidEndEditing(_ notification: Notification) {
//        self.selectionAttributes = nil
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard self.view.window?.firstResponder == self.textView else {
            return
        }
        self.updateSelectionAttributes()
    }
}
