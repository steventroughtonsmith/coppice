//
//  ActiveSidebarSize.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

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
            return 15
        }
    }

    var smallRowGlyphSize: CGSize {
        switch self {
        case .small:
            return CGSize(width: 16, height: 16)
        case .medium:
            return CGSize(width: 20, height: 20)
        case .large:
            return CGSize(width: 24, height: 24)
        }
    }

    var largeRowHeight: CGFloat {
        switch self {
        case .small:
            return 32
        case .medium:
            return 38
        case .large:
            return 46
        }
    }

    var largeRowGlyphSize: CGSize {
        switch self {
        case .small:
            return CGSize(width: 48, height: 40)
        case .medium:
            return CGSize(width: 40, height: 32)
        case .large:
            return CGSize(width: 32, height: 26)
        }
    }

    var symbolSize: Symbols.Size {
        switch self {
        case .small:
            return .small
        case .medium:
            return .regular
        case .large:
            return .large
        }
    }
}


protocol SidebarSizable: AnyObject {
    var activeSidebarSize: ActiveSidebarSize { get set }
}
