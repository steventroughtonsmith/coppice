//
//  ModelObjects+Misc.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 23/11/2020.
//

import Foundation
import M3Data

extension ModelCollection where ModelType == Canvas {
    public var sortedCanvases: [Canvas] {
        return self.all.sorted { $0.sortIndex < $1.sortIndex }
    }
}
