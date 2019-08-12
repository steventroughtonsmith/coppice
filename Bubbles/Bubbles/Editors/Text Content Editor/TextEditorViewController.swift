//
//  TextEditorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class TextEditorViewController: NSViewController, Editor {
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
}
