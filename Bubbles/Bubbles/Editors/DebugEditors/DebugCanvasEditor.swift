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

class DebugCanvasEditor: NSViewController, Editor {
    @IBOutlet weak var tableView: NSTableView!

    let viewModel: DebugCanvasEditorViewModel
    init(viewModel: DebugCanvasEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "DebugCanvasEditor", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerForDraggedTypes([.string])
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
            return page.page?.title
        case .x:
            return page.position.x
        case .y:
            return page.position.y
        case .width:
            return page.size.width
        case .height:
            return page.size.height
        case .parent:
            return page.parent?.id
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
            page.page?.title = (object as? String) ?? ""
        case .x:
            page.position.x = (object as? CGFloat) ?? 0
        case .y:
            page.position.y = (object as? CGFloat) ?? 0
        case .width:
            page.size.width = (object as? CGFloat) ?? 0
        case .height:
            page.size.height = (object as? CGFloat) ?? 0
        case .parent:
            guard let uuidString = object as? String,
                let uuid = UUID(uuidString: uuidString),
                uuid != page.id else {
                    page.parent = nil
                    return
            }

            let newParent = self.viewModel.pages.first(where: { $0.id == uuid })
            newParent?.children.insert(page)
            page.parent = newParent
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
            guard let uuidString = item.string(forType: .string),
                let uuid = UUID(uuidString: uuidString) else {
                    continue
            }
            self.viewModel.addPageWithID(uuid)
        }
        self.tableView.reloadData()
        return true
    }
}
