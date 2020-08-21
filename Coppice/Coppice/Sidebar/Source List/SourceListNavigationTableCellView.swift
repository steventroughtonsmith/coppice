//
//  SourceListNavigationTableCellView.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

protocol SourceListNavigationTableCellViewDelegate: class {
    func userDidSpringLoad(on navigationCell: SourceListNavigationTableCellView)
    func springLoadedDragEnded(_ navigationCell: SourceListNavigationTableCellView)
}

class SourceListNavigationTableCellView: NSTableCellView, NSSpringLoadingDestination {
    weak var delegate: SourceListNavigationTableCellViewDelegate?

    func springLoadingActivated(_ activated: Bool, draggingInfo: NSDraggingInfo) {
        print("activated: \(activated)")
        if (activated) {
            self.delegate?.userDidSpringLoad(on: self)
        }
    }

    func springLoadingHighlightChanged(_ draggingInfo: NSDraggingInfo) {
    }

    func springLoadingEntered(_ draggingInfo: NSDraggingInfo) -> NSSpringLoadingOptions {
        return .enabled
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.delegate?.springLoadedDragEnded(self)
    }
}
