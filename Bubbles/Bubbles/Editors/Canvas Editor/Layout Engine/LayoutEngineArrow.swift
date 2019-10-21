//
//  LayoutEngineArrow.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

struct LayoutEngineArrow: Equatable {
    enum Direction: Equatable {
        case minEdge
        case maxEdge
    }

    var id: String {
        return "\(self.parentID).\(self.childID)"
    }

    let parentID: UUID
    let childID: UUID
    let frame: CGRect
    let horizontalDirection: Direction
    let verticalDirection: Direction
}
