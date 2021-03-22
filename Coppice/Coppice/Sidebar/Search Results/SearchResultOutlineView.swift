//
//  SearchResultOutlineView.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SearchResultOutlineView: NSOutlineView {
    override func frameOfOutlineCell(atRow row: Int) -> NSRect {
        return .zero
    }
}
