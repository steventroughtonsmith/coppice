//
//  Plist.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 31/07/2022.
//

import Foundation
import M3Data

enum Plist {
    static var allPlists: [ModelPlist.Type] {
        return [Plist.V2.self, Plist.V3.self]
    }
}
