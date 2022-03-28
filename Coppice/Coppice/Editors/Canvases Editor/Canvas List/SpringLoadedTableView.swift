//
//  SpringLoadedTableView.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore
import M3Data

protocol SpringLoadedTableViewDelegate: AnyObject {
    func userDidSpringLoad(on row: NSTableRowView, of tableView: SpringLoadedTableView)
    func springLoadedDragEnded(_ tableView: SpringLoadedTableView)
}

class SpringLoadedTableView: PixelPerfectTableView, NSSpringLoadingDestination {
    weak var springLoadingDelegate: SpringLoadedTableViewDelegate?

    private func rowView(for draggingInfo: NSDraggingInfo) -> NSTableRowView? {
        let point = self.convert(draggingInfo.draggingLocation, from: nil)
        let row = self.row(at: point)
        guard row >= 0 else {
            return nil
        }
        return self.rowView(atRow: row, makeIfNecessary: false)
    }

    func springLoadingActivated(_ activated: Bool, draggingInfo: NSDraggingInfo) {
        if activated, let rowView = self.rowView(for: draggingInfo) {
            self.springLoadingDelegate?.userDidSpringLoad(on: rowView, of: self)
        }
    }

    func springLoadingHighlightChanged(_ draggingInfo: NSDraggingInfo) {
        guard let rowView = self.rowView(for: draggingInfo) else {
            return
        }
        rowView.isSelected = true
        if draggingInfo.springLoadingHighlight == .emphasized {
            rowView.isEmphasized = true
        } else if draggingInfo.springLoadingHighlight == .standard {
            rowView.isEmphasized = false
        } else {
            rowView.isSelected = false
            rowView.isEmphasized = false
        }
    }

    func springLoadingEntered(_ info: NSDraggingInfo) -> NSSpringLoadingOptions {
        guard let types = info.draggingPasteboard.types else {
            return .disabled
        }
        guard
            types.contains(ModelID.PasteboardType),
            let item = info.draggingPasteboard.pasteboardItems?.first,
            let id = ModelID(pasteboardItem: item),
            id.modelType == Canvas.modelType
        else {
            return .enabled
        }

        return .disabled
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.springLoadingDelegate?.springLoadedDragEnded(self)
        super.draggingExited(sender)
    }
}
