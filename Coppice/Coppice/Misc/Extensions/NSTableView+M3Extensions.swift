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
    static var nib: NSNib? { get }
}

extension NSTableView {
    func register<CellType: TableCell>(_ type: CellType.Type) {
        self.register(type.nib, forIdentifier: type.identifier)
    }

    func makeView<CellType: TableCell>(of type: CellType.Type, owner: Any? = nil) -> CellType? {
        return self.makeView(withIdentifier: type.identifier, owner: owner) as? CellType
    }
}
