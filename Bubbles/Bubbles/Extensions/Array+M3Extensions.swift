//
//  ArrayExtensions.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 06/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

extension Array {
    subscript(safe index: Self.Index) -> Element? {
        guard (index < self.count) else {
            return nil
        }
        return self[index]
    }
}
