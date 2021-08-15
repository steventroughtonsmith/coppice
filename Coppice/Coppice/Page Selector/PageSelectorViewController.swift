//
//  PageSelectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class PageSelectorViewController: NSViewController {
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var tableScrollView: NSScrollView!
    @IBOutlet var searchFieldContainer: NSView!
    @IBOutlet var scrollViewHeightConstraint: NSLayoutConstraint!

    @objc dynamic let viewModel: PageSelectorViewModel
    let dataSource: PageSelectorTableViewDataSource
    init(viewModel: PageSelectorViewModel) {
        self.viewModel = viewModel
        self.dataSource = PageSelectorTableViewDataSource(viewModel: viewModel)

        super.init(nibName: "PageSelectorViewController", bundle: nil)

        viewModel.view = self
        self.dataSource.delegate = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.searchField.placeholderString = self.viewModel.title
        self.configureSearchField()

        if (self.displayMode == .fromWindow) {
            self.view.window?.makeFirstResponder(self.searchField)
        }
        self.dataSource.tableView = self.tableView
        self.updateViewHeight()
    }


    //MARK: - Mode

    enum DisplayMode: Equatable {
        case fromWindow
        case fromView
    }

    var displayMode: DisplayMode = .fromWindow {
        didSet {
            guard self.displayMode != oldValue else {
                return
            }
            self.configureSearchField()
            self.dataSource.displayMode = self.displayMode
            self.updateViewHeight()
        }
    }

    private func configureSearchField() {
        guard isViewLoaded else {
            return
        }
        self.searchFieldContainer.isHidden = (self.displayMode == .fromView)
    }

    //For some reason NSWindow doesn't enable this and we can't do it in the window controller
    @IBAction func performClose(_ sender: Any?) {
        self.windowController?.close()
    }

    @IBAction func tableDoubleClicked(_ sender: Any?) {
        self.confirmSelection()
    }

    @discardableResult func confirmSelection() -> Bool {
        let result = self.viewModel.rows[self.tableView.selectedRow]

        self.performClose(nil)
        self.viewModel.confirmSelection(of: result)
        return true
    }

    private func updateViewHeight() {
        guard self.isViewLoaded else {
            return
        }
        var boundedHeight = max(0, min(self.tableView.intrinsicContentSize.height, 301))
        boundedHeight += self.tableScrollView.contentInsets.top + self.tableScrollView.contentInsets.bottom
        self.scrollViewHeightConstraint.constant = boundedHeight
    }
}

extension PageSelectorViewController: PageSelectorView {}

extension PageSelectorViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(cancelOperation(_:))) {
            self.performClose(nil)
            return true
        }
        if (commandSelector == #selector(moveUp(_:))) {
            self.dataSource.selectPrevious()
//            self.pagesArrayController.selectPrevious(self)
            //Turns out NSArrayController doesn't update the selectionIndex immediately
//            self.tableView.scrollRowToVisible(max(self.pagesArrayController.selectionIndex - 1, 0))
            return true
        }
        if (commandSelector == #selector(moveDown(_:))) {
            self.dataSource.selectNext()
//            self.pagesArrayController.selectNext(self)
//            self.tableView.scrollRowToVisible(min(self.pagesArrayController.selectionIndex + 1, self.viewModel.rows.count - 1))
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

extension PageSelectorViewController: PageSelectorTableViewDataSourceDelegate {
    func didReloadTable(for dataSource: PageSelectorTableViewDataSource) {
        self.updateViewHeight()
    }
}


