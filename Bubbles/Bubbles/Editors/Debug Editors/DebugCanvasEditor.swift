//
//  DebugCanvasEditor.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

enum Columns: String {
    case id
    case page
    case x
    case y
    case width
    case height
    case parent
}

class DebugCanvasEditor: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!

    @objc dynamic let viewModel: DebugCanvasEditorViewModel
    init(viewModel: DebugCanvasEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "DebugCanvasEditor", bundle: nil)
        viewModel.view = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerForDraggedTypes([ModelID.PasteboardType])
    }

    var enabled: Bool = true

    override func viewWillAppear() {
        super.viewWillAppear()
        self.viewModel.startObservingChanges()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.viewModel.stopObservingChanges()
    }
}

extension DebugCanvasEditor: Editor {
    var inspectors: [Inspector] {
        return []
    }
}

extension DebugCanvasEditor: DebugCanvasEditorView {
    func reloadPage(_ page: CanvasPage) {
        self.tableView.reloadData()
    }
}

extension DebugCanvasEditor: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.viewModel.pages.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let column = tableColumn,
            let identifier = Columns(rawValue: column.identifier.rawValue) else {
                return nil
        }
        let page = self.viewModel.pages[row]
        switch identifier {
        case .id:
            return page.id
        case .page:
            return page.pageTitle
        case .x:
            return page.x
        case .y:
            return page.y
        case .width:
            return page.width
        case .height:
            return page.height
        case .parent:
            return page.parentID
        }
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard let column = tableColumn,
            let identifier = Columns(rawValue: column.identifier.rawValue) else {
                return
        }
        let page = self.viewModel.pages[row]
        switch identifier {
        case .page:
            page.pageTitle = (object as? String) ?? ""
        case .x:
            page.x = (object as? CGFloat) ?? 0
        case .y:
            page.y = (object as? CGFloat) ?? 0
        case .width:
            page.width = (object as? CGFloat) ?? 0
        case .height:
            page.height = (object as? CGFloat) ?? 0
        case .parent:
            page.parentID = (object as? String) ?? ""
        default:
            break
        }
    }


    func tableView(_ tableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        tableView.setDropRow(-1, dropOperation: .on)
        return .move
    }

    func tableView(_ tableView: NSTableView,
                   acceptDrop info: NSDraggingInfo,
                   row: Int,
                   dropOperation: NSTableView.DropOperation) -> Bool {
        guard let items = info.draggingPasteboard.pasteboardItems else {
            return false
        }

        for item in items {
            guard let id = ModelID(pasteboardItem: item) else {
                    continue
            }
            self.viewModel.addPageWithID(id)
        }
        self.tableView.reloadData()
        return true
    }
}
