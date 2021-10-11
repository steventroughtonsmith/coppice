//
//  NSAppearance+M3Extensions.swift
//  NSAppearance+M3Extensions
//
//  Created by Martin Pilkington on 02/10/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import AppKit

extension NSAppearance {
    var isDarkMode: Bool {
        return self.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}
