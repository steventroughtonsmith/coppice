//
//  NSTableView+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

protocol TableCell {
    static var identifier: NSUserInterfaceItemIdentifier { get }
}

extension NSTableView {
    func makeView<CellType: TableCell>(of type: CellType.Type, owner: Any? = nil) -> CellType? {
        return self.makeView(withIdentifier: type.identifier, owner: owner) as? CellType
    }
}
