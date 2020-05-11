//
//  PageSelectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class PageSelectorViewController: NSViewController {

    @IBOutlet var pagesArrayController: NSArrayController!
    @IBOutlet weak var searchField: NSTextField!
    @objc dynamic let viewModel: PageSelectorViewModel
    init(viewModel: PageSelectorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "PageSelectorViewController", bundle: nil)
        viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchField.placeholderString = self.viewModel.title
        self.view.window?.makeFirstResponder(self.searchField)
    }

    //For some reason NSWindow doesn't enable this and we can't do it in the window controller
    @IBAction func performClose(_ sender: Any?) {
        self.windowController?.close()
    }

    @IBAction func tableDoubleClicked(_ sender: Any?) {
        self.confirmSelection()
    }

    @discardableResult func confirmSelection() -> Bool {
        guard let result = self.pagesArrayController.selectedObjects.first as? PageSelectorResult else {
            return false
        }

        self.performClose(nil)
        self.viewModel.confirmSelection(of: result)
        return true
    }
}

extension PageSelectorViewController: PageSelectorView {
}

extension PageSelectorViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(cancelOperation(_:))) {
            self.performClose(nil)
            return true
        }
        if (commandSelector == #selector(moveUp(_:))) {
            self.pagesArrayController.selectPrevious(self)
            return true
        }
        if (commandSelector == #selector(moveDown(_:))) {
            self.pagesArrayController.selectNext(self)
            return true
        }
        if (commandSelector == #selector(insertNewline(_:))) {
            return self.confirmSelection()
        }
        return false
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        self.view.window?.perform(#selector(NSWindow.makeFirstResponder(_:)), with: self.searchField, afterDelay: 0)
    }
    
}

extension PageSelectorViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return PageSelectorTableRowView()
    }
}


class PageSelectorTableRowView: NSTableRowView {
    override var isEmphasized: Bool {
        get { return self.isSelected }
        set {}
    }
}
