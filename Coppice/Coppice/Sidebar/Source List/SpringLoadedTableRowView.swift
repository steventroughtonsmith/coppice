//
//  SpringLoadedTableRowView.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

protocol SpringLoadedTableRowViewDelegate: class {
    func userDidSpringLoad(on row: SpringLoadedTableRowView)
    func springLoadedDragEnded(_ row: SpringLoadedTableRowView)
}

class SpringLoadedTableRowView: NSTableRowView, NSSpringLoadingDestination {
    weak var delegate: SpringLoadedTableRowViewDelegate?

    var enclosingTableView: NSTableView? {
        var superview: NSView? = self.superview
        while (superview != nil) {
            if let table = superview as? NSTableView {
                return table
            }
            superview = superview?.superview
        }
        return nil
    }

    func springLoadingActivated(_ activated: Bool, draggingInfo: NSDraggingInfo) {
        if (activated) {
            self.delegate?.userDidSpringLoad(on: self)
        }
    }

    func springLoadingHighlightChanged(_ draggingInfo: NSDraggingInfo) {
        self.isSelected = true
        if draggingInfo.springLoadingHighlight == .emphasized {
            self.isEmphasized = true
        } else if draggingInfo.springLoadingHighlight == .standard {
            self.isEmphasized = false
        } else {
            self.isSelected = false
            self.isEmphasized = false
        }
    }

    func springLoadingEntered(_ info: NSDraggingInfo) -> NSSpringLoadingOptions {
        return .enabled
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("prepare")
        return super.prepareForDragOperation(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("perform drag")
        return super.performDragOperation(sender)
    }

    override func draggingEntered(_ info: NSDraggingInfo) -> NSDragOperation {
        print("entered")
        guard let types = info.draggingPasteboard.types else {
            return super.draggingEntered(info)
        }
        guard
            types.contains(ModelID.PasteboardType),
            let item = info.draggingPasteboard.pasteboardItems?.first,
            let id = ModelID(pasteboardItem: item),
            id.modelType == Canvas.modelType
        else {
            return super.draggingEntered(info)
        }
        print("enclosingTableView: \(self.enclosingTableView)")
        return super.draggingEntered(info)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("dragging updated")
        return super.draggingUpdated(sender)
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        print("dragging exited")
        return super.draggingExited(sender)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.delegate?.springLoadedDragEnded(self)
    }
}
