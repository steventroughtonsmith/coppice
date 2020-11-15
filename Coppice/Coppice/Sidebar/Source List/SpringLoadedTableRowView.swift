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

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.delegate?.springLoadedDragEnded(self)
    }
}
