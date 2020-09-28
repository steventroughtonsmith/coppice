//
//  ActiveSidebarSize.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

enum ActiveSidebarSize {
    case small
    case medium
    case large

    init(sidebarSize: SidebarSize) {
        switch sidebarSize {
        case .small:
            self = .small
        case .medium:
            self = .medium
        case .large:
            self = .large
        case .system:
            let intValue = UserDefaults.standard.integer(forKey: "NSTableViewDefaultSizeMode")
            guard let tableSize = NSTableView.RowSizeStyle(rawValue: intValue) else {
                self = .medium
                return
            }

            if tableSize == .small {
                self = .small
                return
            }
            if tableSize == .large {
                self = .large
                return
            }
            self = .medium
        }
    }


    var smallRowHeight: CGFloat {
        switch self {
        case .small:
            if #available(OSX 10.16, *) {
                return 24
            }
            return 22
        case .medium:
            if #available(OSX 10.16, *) {
                return 28
            }
            return 24
        case .large:
            return 32
        }
    }

    var smallRowFontSize: CGFloat {
        switch self {
        case .small:
            return 11
        case .medium:
            return 13
        case .large:
            if #available(OSX 10.16, *) {
                return 15
            }
            return 13
        }
    }

    var largeRowHeight: CGFloat {
        switch self {
        case .small:
            return 29
        case .medium:
            return 34
        case .large:
            return 39
        }
    }
}
